@IsTest
private class WorkspaceProvisioningBatchTests {
  @IsTest
  static void reservesCalloutBudgetForEveryFolderType() {
    Test.setMock(HttpCalloutMock.class, new EmptyHttpMock());
    HttpRequest request = new HttpRequest();
    request.setEndpoint('https://example.test');
    request.setMethod('GET');

    for (Integer i = 0; i < 90; i++) {
      new Http().send(request);
    }
    System.assertEquals(true, WorkspaceProvisioningBatch.hasCalloutBudget('regular'));
    new Http().send(request);
    new Http().send(request);
    System.assertEquals(false, WorkspaceProvisioningBatch.hasCalloutBudget('regular'));
    System.assertEquals(true, WorkspaceProvisioningBatch.hasCalloutBudget('tab'));
    new Http().send(request);
    System.assertEquals(false, WorkspaceProvisioningBatch.hasCalloutBudget('tab'));
    System.assertEquals(true, WorkspaceProvisioningBatch.hasCalloutBudget('search'));
    new Http().send(request);
    System.assertEquals(false, WorkspaceProvisioningBatch.hasCalloutBudget('search'));
  }

  @IsTest
  static void missingFolderPlanIsParentFirstAndExcludesExistingAndSkipped() {
    IManageWorkspaceWrap template = wrapWorkspace(
      'T!1',
      new List<IManageWFolder>{
        folder('T!4', 'Child', 'tab', 'T!2'),
        folder('T!2', 'Parent', 'regular', 'T!1'),
        folder('T!3', 'Existing', 'regular', 'T!1'),
        folder('T!5', 'Skipped', 'search', 'T!1')
      }
    );
    IManageWorkspaceWrap destination = wrapWorkspace(
      'W!1',
      new List<IManageWFolder>{
        folder('W!3', 'Existing', 'regular', 'W!1')
      }
    );

    List<IManageFolderWrap> missing = WorkspaceProvisioningBatch.findMissingFolders(
      destination,
      template.getFlatListAllFolders(),
      new Set<String>{ 'search|skipped' }
    );

    System.assertEquals(2, missing.size());
    System.assertEquals('Parent', ((IManageWFolder) missing[0].wrapItem).name);
    System.assertEquals('Child', ((IManageWFolder) missing[1].wrapItem).name);
  }

  @IsTest
  static void finishDecisionStopsTerminalJobsAndReportsUnhandledErrors() {
    IManage_Workspace_Provisioning__c operation = operation();

    operation.Status__c = 'Failed';
    System.assertEquals(
      WorkspaceProvisioningBatch.FINISH_STOP,
      WorkspaceProvisioningBatch.determineFinishAction(operation, 1)
    );
    operation.Status__c = 'Completed';
    System.assertEquals(
      WorkspaceProvisioningBatch.FINISH_STOP,
      WorkspaceProvisioningBatch.determineFinishAction(operation, 0)
    );
    operation.Status__c = 'InProgress';
    System.assertEquals(
      WorkspaceProvisioningBatch.FINISH_FAIL,
      WorkspaceProvisioningBatch.determineFinishAction(operation, 1)
    );
    System.assertEquals(
      WorkspaceProvisioningBatch.FINISH_CONTINUE,
      WorkspaceProvisioningBatch.determineFinishAction(operation, 0)
    );
  }

  @IsTest
  static void bootstrapCreatesOnlyTheWorkspaceShell() {
    resetCalloutState();
    Test.setMock(HttpCalloutMock.class, new BootstrapMock());
    IManage_Workspace_Provisioning__c operation = operation();
    operation.Stage__c = 'Bootstrap';
    operation.Status__c = 'Pending';
    operation.iManage_WS_Id__c = null;
    runWorker(operation);

    operation = [
      SELECT
        Stage__c,
        Status__c,
        iManage_WS_Id__c,
        iManage_WS_Name__c,
        Last_Error__c
      FROM IManage_Workspace_Provisioning__c
      WHERE Id = :operation.Id
    ];
    System.assertEquals(
      'Folders',
      operation.Stage__c,
      'Last error: ' + operation.Last_Error__c
    );
    System.assertEquals('InProgress', operation.Status__c);
    System.assertEquals('ACTIVE!workspace', operation.iManage_WS_Id__c);
    System.assertEquals('Created Workspace', operation.iManage_WS_Name__c);
    System.assertEquals(null, operation.Last_Error__c);
  }

  @IsTest
  static void optionalFolderIsPersistedAsSkipped() {
    resetCalloutState();
    Test.setMock(HttpCalloutMock.class, new FolderChunkMock(true));
    IManage_Workspace_Provisioning__c operation = operation();
    runWorker(operation);

    operation = [
      SELECT
        Status__c,
        Skipped_Folders__c,
        Pending_Folder_Count__c,
        Last_Error__c
      FROM IManage_Workspace_Provisioning__c
      WHERE Id = :operation.Id
    ];
    System.assertEquals(
      'InProgress',
      operation.Status__c,
      'Last error: ' + operation.Last_Error__c
    );
    System.assert(operation.Skipped_Folders__c.contains('regular|documents'));
    System.assertEquals(1, operation.Pending_Folder_Count__c);
  }

  @IsTest
  static void zeroPlanCompletesAndWritesTheMapping() {
    resetCalloutState();
    Test.setMock(HttpCalloutMock.class, new FolderChunkMock(false));
    IManage_Workspace_Provisioning__c operation = operation();
    runWorker(operation);

    operation = [
      SELECT Status__c, Active_Key__c, Last_Error__c
      FROM IManage_Workspace_Provisioning__c
      WHERE Id = :operation.Id
    ];
    System.assertEquals(
      'Completed',
      operation.Status__c,
      'Last error: ' + operation.Last_Error__c
    );
    System.assertEquals(null, operation.Active_Key__c);
    System.assertEquals(
      1,
      [
        SELECT COUNT()
        FROM IManage_WS_to_Entity_Mapping__c
        WHERE EntityId__c = :UserInfo.getUserId()
      ]
    );
  }

  @IsTest
  static void unchangedPendingCountFailsInsteadOfChainingForever() {
    resetCalloutState();
    Test.setMock(HttpCalloutMock.class, new FolderChunkMock(true));
    IManage_Workspace_Provisioning__c operation = operation();
    operation.Pending_Folder_Count__c = 1;
    runWorker(operation);

    operation = [
      SELECT Status__c, Last_Error__c
      FROM IManage_Workspace_Provisioning__c
      WHERE Id = :operation.Id
    ];
    System.assertEquals('Failed', operation.Status__c);
    System.assert(operation.Last_Error__c.contains('did not decrease'));
  }

  @IsTest
  static void decreasedPendingCountAllowsTheNextChunk() {
    resetCalloutState();
    Test.setMock(HttpCalloutMock.class, new FolderChunkMock(true));
    IManage_Workspace_Provisioning__c operation = operation();
    operation.Pending_Folder_Count__c = 2;
    runWorker(operation);

    operation = [
      SELECT Status__c, Pending_Folder_Count__c, Last_Error__c
      FROM IManage_Workspace_Provisioning__c
      WHERE Id = :operation.Id
    ];
    System.assertEquals(
      'InProgress',
      operation.Status__c,
      'Last error: ' + operation.Last_Error__c
    );
    System.assertEquals(1, operation.Pending_Folder_Count__c);
  }

  @IsTest
  static void catchPersistsSkippedFoldersFromTheSameChunk() {
    resetCalloutState();
    Test.setMock(HttpCalloutMock.class, new FailureAfterOptionalMock());
    IManage_Workspace_Provisioning__c operation = operation();
    runWorker(operation);

    operation = [
      SELECT
        Status__c,
        Skipped_Folders__c,
        Pending_Folder_Count__c
      FROM IManage_Workspace_Provisioning__c
      WHERE Id = :operation.Id
    ];
    System.assertEquals('Failed', operation.Status__c);
    System.assert(operation.Skipped_Folders__c.contains('regular|a'));
    System.assertEquals(2, operation.Pending_Folder_Count__c);
  }

  private static IManage_Workspace_Provisioning__c operation() {
    IManageWsProvisioningService.ProvisioningRequest request = new IManageWsProvisioningService.ProvisioningRequest();
    request.entityId = UserInfo.getUserId();
    request.workspaceName = 'Requested Workspace';
    request.clientId = '1000';
    request.matterId = '2000';
    request.libraryId = 'ACTIVE';
    request.templateId = 'ACTIVE!template';
    request.autoCreated = false;
    request.source = 'SF';
    return new IManage_Workspace_Provisioning__c(
      Entity_Id__c = request.entityId,
      Active_Key__c = request.entityId,
      Stage__c = 'Folders',
      Status__c = 'InProgress',
      Template_Id__c = request.templateId,
      iManage_Library__c = request.libraryId,
      iManage_WS_Id__c = 'ACTIVE!workspace',
      iManage_WS_Name__c = request.workspaceName,
      Request_Payload__c = JSON.serialize(request),
      Skipped_Folders__c = '[]'
    );
  }

  private static void runWorker(IManage_Workspace_Provisioning__c operation) {
    insert operation;
    Test.startTest();
    System.enqueueJob(new ExecuteWorker(operation.Id));
    Test.stopTest();
  }

  private static void resetCalloutState() {
    Cache.Org.remove('gdsi_imanage.iManage.license');
    iManageWrapper.invalidateApiInfoCache();
  }

  private static IManageWorkspaceWrap wrapWorkspace(
    String workspaceId,
    List<IManageWFolder> folders
  ) {
    return iManageWorkspacesHelper.wrapWorkspaceContent(
      workspace(workspaceId, 'Workspace', null),
      folders
    );
  }

  private static IManageWFolder folder(
    String id,
    String name,
    String type,
    String parentId
  ) {
    IManageWFolder result = new IManageWFolder();
    result.id = id;
    result.name = name;
    result.folder_type = type;
    result.parent_id = parentId;
    result.default_security = 'inherit';
    result.database = 'ACTIVE';
    return result;
  }

  private static IManageWWorkspace workspace(
    String id,
    String name,
    String createDate
  ) {
    IManageWWorkspace result = new IManageWWorkspace();
    result.id = id;
    result.name = name;
    result.database = 'ACTIVE';
    result.create_date = createDate;
    result.default_security = 'inherit';
    return result;
  }

  private class EmptyHttpMock implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest request) {
      HttpResponse response = new HttpResponse();
      response.setStatusCode(200);
      response.setBody('{}');
      return response;
    }
  }

  private class ExecuteWorker implements Queueable, Database.AllowsCallouts {
    private Id operationId;

    ExecuteWorker(Id operationId) {
      this.operationId = operationId;
    }

    public void execute(QueueableContext context) {
      IManage_Workspace_Provisioning__c operation = [
        SELECT
          Id,
          Entity_Id__c,
          Active_Key__c,
          Stage__c,
          Status__c,
          Last_Error__c,
          Current_Job_Id__c,
          Request_Payload__c,
          Skipped_Folders__c,
          Pending_Folder_Count__c,
          Template_Id__c,
          iManage_Library__c,
          iManage_WS_Id__c,
          iManage_WS_Name__c
        FROM IManage_Workspace_Provisioning__c
        WHERE Id = :operationId
      ];
      new WorkspaceProvisioningBatch(operation.Id).execute(
        null,
        new List<SObject>{ operation }
      );
    }
  }

  private class BootstrapMock implements HttpCalloutMock {
    private TestIManageApiResponseHelper responses = new TestIManageApiResponseHelper();

    public HttpResponse respond(HttpRequest request) {
      String endpoint = request.getEndpoint();
      if (endpoint == TestUtils.getLicenseApiUrl()) {
        return activeLicense();
      }
      if (endpoint == 'callout:iManageCreds/api') {
        return TestUtils.getMockAuthResponse(200, 'authenticated', 333, 'ACTIVE');
      }
      if (endpoint.contains('/workspaces/ACTIVE!template')) {
        return responses.buildWorkspaceResponse(
          200,
          workspace('ACTIVE!template', 'Template', null)
        );
      }
      if (endpoint.contains('/folders?')) {
        return responses.buildFoldersResponse(200, new List<IManageWFolder>());
      }
      if (endpoint.endsWith('/workspaces') && request.getMethod() == 'POST') {
        return responses.buildWorkspaceResponse(
          200,
          workspace(
            'ACTIVE!workspace',
            'Created Workspace',
            '2026-08-19T08:00:00Z'
          )
        );
      }
      if (endpoint.contains('/workspaces/ACTIVE!workspace/name-value-pairs')) {
        return responses.buildUntypedResponse(200, new Map<String, Object>());
      }
      System.assert(false, 'Unexpected Bootstrap callout: ' + endpoint);
      return null;
    }
  }

  private class FolderChunkMock implements HttpCalloutMock {
    private Boolean includeOptionalFolder;
    private TestIManageApiResponseHelper responses = new TestIManageApiResponseHelper();

    FolderChunkMock(Boolean includeOptionalFolder) {
      this.includeOptionalFolder = includeOptionalFolder;
    }

    public HttpResponse respond(HttpRequest request) {
      String endpoint = request.getEndpoint();
      if (endpoint == TestUtils.getLicenseApiUrl()) {
        return activeLicense();
      }
      if (endpoint == 'callout:iManageCreds/api') {
        return TestUtils.getMockAuthResponse(200, 'authenticated', 333, 'ACTIVE');
      }
      if (endpoint.contains('/workspaces/ACTIVE!workspace')) {
        return responses.buildWorkspaceResponse(
          200,
          workspace(
            'ACTIVE!workspace',
            'Destination Workspace',
            '2026-08-19T08:00:00Z'
          )
        );
      }
      if (endpoint.contains('/workspaces/ACTIVE!template')) {
        return responses.buildWorkspaceResponse(
          200,
          workspace('ACTIVE!template', 'Template', null)
        );
      }
      if (endpoint.contains('/folders?')) {
        List<IManageWFolder> folders = endpoint.contains(
            'container_id=ACTIVE!template'
          ) && includeOptionalFolder
          ? new List<IManageWFolder>{
              folder(
                'ACTIVE!template-folder',
                'Documents',
                'regular',
                'ACTIVE!template'
              )
            }
          : new List<IManageWFolder>();
        return responses.buildFoldersResponse(200, folders);
      }
      if (endpoint.contains('/folders/ACTIVE!template-folder/name-value-pairs')) {
        return responses.buildNameValuePairResponse(
          200,
          new Map<String, String>{ 'IMCC_IsOptional' => 'true' }
        );
      }
      if (endpoint.endsWith('/folders/ACTIVE!template-folder')) {
        return responses.buildWFolderResponse(
          200,
          folder(
            'ACTIVE!template-folder',
            'Documents',
            'regular',
            'ACTIVE!template'
          )
        );
      }
      System.assert(false, 'Unexpected folder callout: ' + endpoint);
      return null;
    }
  }

  private class FailureAfterOptionalMock implements HttpCalloutMock {
    private TestIManageApiResponseHelper responses = new TestIManageApiResponseHelper();

    public HttpResponse respond(HttpRequest request) {
      String endpoint = request.getEndpoint();
      if (endpoint == TestUtils.getLicenseApiUrl()) {
        return activeLicense();
      }
      if (endpoint == 'callout:iManageCreds/api') {
        return TestUtils.getMockAuthResponse(200, 'authenticated', 333, 'ACTIVE');
      }
      if (endpoint.contains('/workspaces/ACTIVE!workspace')) {
        return responses.buildWorkspaceResponse(
          200,
          workspace(
            'ACTIVE!workspace',
            'Destination Workspace',
            '2026-08-19T08:00:00Z'
          )
        );
      }
      if (endpoint.contains('/workspaces/ACTIVE!template')) {
        return responses.buildWorkspaceResponse(
          200,
          workspace('ACTIVE!template', 'Template', null)
        );
      }
      if (endpoint.contains('/folders?')) {
        List<IManageWFolder> folders = endpoint.contains(
            'container_id=ACTIVE!template'
          )
          ? new List<IManageWFolder>{
              folder('ACTIVE!optional', 'A', 'regular', 'ACTIVE!template'),
              folder('ACTIVE!failure', 'Failure', 'regular', 'ACTIVE!template')
            }
          : new List<IManageWFolder>();
        return responses.buildFoldersResponse(200, folders);
      }
      if (endpoint.contains('/folders/ACTIVE!optional/name-value-pairs')) {
        return responses.buildNameValuePairResponse(
          200,
          new Map<String, String>{ 'IMCC_IsOptional' => 'true' }
        );
      }
      if (endpoint.endsWith('/folders/ACTIVE!optional')) {
        return responses.buildWFolderResponse(
          200,
          folder('ACTIVE!optional', 'A', 'regular', 'ACTIVE!template')
        );
      }
      if (endpoint.contains('/folders/ACTIVE!failure/name-value-pairs')) {
        throw new CalloutException('Forced failure after optional folder.');
      }
      System.assert(false, 'Unexpected catch-path callout: ' + endpoint);
      return null;
    }
  }

  private static HttpResponse activeLicense() {
    return TestUtils.getMockLicenseResponse(
      200,
      String.valueOf([SELECT Id FROM Organization LIMIT 1].Id)
    );
  }
}

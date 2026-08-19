@IsTest
private class IManageWsProvisioningServiceTests {
  @IsTest
  static void startCreatesOneOperationAndAttachesToItsLiveJob() {
    IManageWsProvisioningService.ProvisioningRequest request = request();

    String firstId = IManageWsProvisioningService.startProvisioning(
      JSON.serialize(request)
    );
    String secondId = IManageWsProvisioningService.startProvisioning(
      JSON.serialize(request)
    );

    System.assertEquals(firstId, secondId);
    IManage_Workspace_Provisioning__c operation = [
      SELECT
        Stage__c,
        Status__c,
        Active_Key__c,
        Current_Job_Id__c,
        Request_Payload__c
      FROM IManage_Workspace_Provisioning__c
      WHERE Id = :firstId
    ];
    System.assertEquals('Bootstrap', operation.Stage__c);
    System.assertEquals('Pending', operation.Status__c);
    System.assertEquals(request.entityId, operation.Active_Key__c);
    System.assertNotEquals(null, operation.Current_Job_Id__c);
    System.assertEquals(
      request.workspaceName,
      IManageWsProvisioningService.deserializeRequest(
          operation.Request_Payload__c
        )
        .workspaceName
    );
  }

  @IsTest
  static void uniqueActiveKeyProtectsTheInsertRace() {
    IManage_Workspace_Provisioning__c winner = operation('Pending');
    winner.Stage__c = 'Bootstrap';
    winner.iManage_WS_Id__c = null;
    insert winner;
    IManage_Workspace_Provisioning__c loser = operation('Pending');
    loser.Stage__c = 'Bootstrap';
    loser.iManage_WS_Id__c = null;

    Database.SaveResult result = Database.insert(loser, false);

    System.assertEquals(false, result.isSuccess());
    System.assertEquals(
      StatusCode.DUPLICATE_VALUE,
      result.getErrors()[0].getStatusCode()
    );
    System.assertEquals(
      winner.Id,
      [
        SELECT Id
        FROM IManage_Workspace_Provisioning__c
        WHERE Active_Key__c = :winner.Active_Key__c
        LIMIT 1
      ].Id
    );
  }

  @IsTest
  static void failedOperationResumesWithTheSameWorkspace() {
    IManage_Workspace_Provisioning__c operation = operation('Failed');
    operation.Last_Error__c = 'Temporary failure';
    operation.Pending_Folder_Count__c = 10;
    insert operation;

    String resumedId = IManageWsProvisioningService.startProvisioning(
      JSON.serialize(request())
    );
    IManage_Workspace_Provisioning__c resumed = [
      SELECT
        Status__c,
        Last_Error__c,
        iManage_WS_Id__c,
        Pending_Folder_Count__c,
        Current_Job_Id__c
      FROM IManage_Workspace_Provisioning__c
      WHERE Id = :resumedId
    ];

    System.assertEquals(operation.Id, resumedId);
    System.assertEquals('InProgress', resumed.Status__c);
    System.assertEquals(null, resumed.Last_Error__c);
    System.assertEquals('ACTIVE!workspace', resumed.iManage_WS_Id__c);
    System.assertEquals(null, resumed.Pending_Folder_Count__c);
    System.assertNotEquals(null, resumed.Current_Job_Id__c);
  }

  @IsTest
  static void completionWritesAndReusesTheExistingMapping() {
    IManage_Workspace_Provisioning__c operation = operation('InProgress');
    insert operation;
    IManageWWorkspace workspace = workspace();

    IManageWsProvisioningService.completeOperation(operation, workspace);

    IManage_WS_to_Entity_Mapping__c mapping = [
      SELECT
        Auto_created__c,
        Source__c,
        iManage_WS_Id__c,
        iManage_Library__c,
        iManage_Workspace_Created_On__c
      FROM IManage_WS_to_Entity_Mapping__c
      WHERE EntityId__c = :operation.Entity_Id__c
    ];
    System.assertEquals(true, mapping.Auto_created__c);
    System.assertEquals('SF', mapping.Source__c);
    System.assertEquals(workspace.id, mapping.iManage_WS_Id__c);
    System.assertEquals(workspace.database, mapping.iManage_Library__c);
    System.assertEquals(
      workspace.create_date,
      mapping.iManage_Workspace_Created_On__c
    );

    operation = [
      SELECT
        Status__c,
        Active_Key__c,
        iManage_WS_Name__c,
        Request_Payload__c,
        Entity_Id__c,
        iManage_WS_Id__c,
        iManage_Library__c
      FROM IManage_Workspace_Provisioning__c
      WHERE Id = :operation.Id
    ];
    IManageWsProvisioningService.completeOperation(operation, workspace);
    System.assertEquals(
      1,
      [
        SELECT COUNT()
        FROM IManage_WS_to_Entity_Mapping__c
        WHERE EntityId__c = :operation.Entity_Id__c
      ]
    );
    System.assertEquals(
      null,
      IManageWsProvisioningService.getActiveProvisioning(operation.Entity_Id__c)
    );
  }

  @IsTest
  static void completionRejectsAConflictingMapping() {
    IManage_Workspace_Provisioning__c operation = operation('InProgress');
    insert operation;
    insert new IManage_WS_to_Entity_Mapping__c(
      EntityId__c = operation.Entity_Id__c,
      iManage_WS_Id__c = 'ACTIVE!different',
      iManage_Library__c = operation.iManage_Library__c
    );

    try {
      IManageWsProvisioningService.completeOperation(operation, workspace());
      System.assert(false, 'Expected a conflicting mapping error.');
    } catch (IManageExceptions.IManageApplicationException ex) {
      System.assert(ex.getMessage().contains('different iManage workspace'));
    }
  }

  @IsTest
  static void auraStatusMethodsReturnSerializedStatus() {
    IManage_Workspace_Provisioning__c operation = operation('InProgress');
    insert operation;

    IManageWsProvisioningService.ProvisioningStatus active = (IManageWsProvisioningService.ProvisioningStatus) JSON.deserialize(
      IManageWsProvisioningService.getActiveProvisioning(
        operation.Entity_Id__c
      ),
      IManageWsProvisioningService.ProvisioningStatus.class
    );
    IManageWsProvisioningService.ProvisioningStatus status = (IManageWsProvisioningService.ProvisioningStatus) JSON.deserialize(
      IManageWsProvisioningService.getProvisioningStatus(operation.Id),
      IManageWsProvisioningService.ProvisioningStatus.class
    );

    System.assertEquals(operation.Id, active.operationId);
    System.assertEquals('InProgress', active.status);
    System.assertEquals(operation.Id, status.operationId);
    System.assertEquals('InProgress', status.status);
  }

  @IsTest
  static void startRejectsAnExistingMappingAndStatusHandlesMissingOperation() {
    IManageWsProvisioningService.ProvisioningRequest request = request();
    insert new IManage_WS_to_Entity_Mapping__c(
      EntityId__c = request.entityId,
      iManage_WS_Id__c = 'ACTIVE!existing',
      iManage_Library__c = request.libraryId
    );

    try {
      IManageWsProvisioningService.startProvisioning(JSON.serialize(request));
      System.assert(false, 'Expected an existing mapping error.');
    } catch (IManageExceptions.IManageApplicationException ex) {
      System.assert(ex.getMessage().contains('mapping already exists'));
    }

    try {
      IManageWsProvisioningService.getProvisioningStatus(
        UserInfo.getUserId()
      );
      System.assert(false, 'Expected a missing operation error.');
    } catch (IManageExceptions.IManageApplicationException ex) {
      System.assert(ex.getMessage().contains('not found'));
    }
  }

  private static IManageWsProvisioningService.ProvisioningRequest request() {
    IManageWsProvisioningService.ProvisioningRequest result = new IManageWsProvisioningService.ProvisioningRequest();
    result.entityId = UserInfo.getUserId();
    result.workspaceName = 'Client Matter';
    result.clientId = '1000';
    result.matterId = '2000';
    result.libraryId = 'ACTIVE';
    result.templateId = 'ACTIVE!template';
    result.autoCreated = true;
    result.source = 'SF';
    return result;
  }

  private static IManage_Workspace_Provisioning__c operation(String status) {
    IManageWsProvisioningService.ProvisioningRequest request = request();
    return new IManage_Workspace_Provisioning__c(
      Entity_Id__c = request.entityId,
      Active_Key__c = request.entityId,
      Stage__c = 'Folders',
      Status__c = status,
      Template_Id__c = request.templateId,
      iManage_Library__c = request.libraryId,
      iManage_WS_Id__c = 'ACTIVE!workspace',
      iManage_WS_Name__c = request.workspaceName,
      Request_Payload__c = JSON.serialize(request),
      Skipped_Folders__c = '[]'
    );
  }

  private static IManageWWorkspace workspace() {
    IManageWWorkspace result = new IManageWWorkspace();
    result.id = 'ACTIVE!workspace';
    result.name = 'Actual Workspace';
    result.database = 'ACTIVE';
    result.create_date = '2026-08-19T08:00:00Z';
    return result;
  }
}

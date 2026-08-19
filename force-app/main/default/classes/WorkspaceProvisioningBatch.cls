public with sharing class WorkspaceProvisioningBatch
  implements Database.Batchable<SObject>, Database.AllowsCallouts {
  private static final Integer CALLOUT_RESERVE = 2;
  @TestVisible private static final String FINISH_STOP = 'Stop';
  @TestVisible private static final String FINISH_FAIL = 'Fail';
  @TestVisible private static final String FINISH_CONTINUE = 'Continue';

  private Id operationId;

  public WorkspaceProvisioningBatch(Id operationId) {
    this.operationId = operationId;
  }

  public Database.QueryLocator start(Database.BatchableContext context) {
    return Database.getQueryLocator([
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
    ]);
  }

  public void execute(Database.BatchableContext context, List<SObject> scope) {
    if (scope.isEmpty()) {
      return;
    }
    IManage_Workspace_Provisioning__c operation = (IManage_Workspace_Provisioning__c) scope[0];
    try {
      if (operation.Stage__c == 'Bootstrap') {
        createWorkspaceShell(operation);
      } else if (operation.Stage__c == 'Folders') {
        createFolderChunk(operation);
      } else {
        throw new IManageExceptions.IManageApplicationException(
          'Unknown workspace provisioning stage: ' + operation.Stage__c
        );
      }
      Logger.getInstance().Flush();
    } catch (Exception ex) {
      operation.Status__c = 'Failed';
      operation.Last_Error__c = ex.getMessage();
      update operation;
      Logger.getInstance().error(ex, 'WorkspaceProvisioningBatch::execute');
      Logger.getInstance().Flush();
    }
  }

  public void finish(Database.BatchableContext context) {
    List<IManage_Workspace_Provisioning__c> operations = [
      SELECT Id, Status__c, Last_Error__c, Current_Job_Id__c
      FROM IManage_Workspace_Provisioning__c
      WHERE Id = :operationId
      LIMIT 1
    ];
    if (operations.isEmpty()) {
      return;
    }
    IManage_Workspace_Provisioning__c operation = operations[0];
    AsyncApexJob job = [
      SELECT NumberOfErrors
      FROM AsyncApexJob
      WHERE Id = :context.getJobId()
    ];
    // finish() runs in a fresh transaction, so it can record an uncatchable
    // execute() failure or start the next chunk with a new callout budget.
    String action = determineFinishAction(operation, job.NumberOfErrors);
    if (action == FINISH_STOP) {
      return;
    }
    if (action == FINISH_FAIL) {
      operation.Status__c = 'Failed';
      operation.Last_Error__c =
        'Workspace provisioning worker failed with an unhandled Apex error. Job Id: ' +
        context.getJobId();
      update operation;
      return;
    }
    Id nextJobId = Database.executeBatch(
      new WorkspaceProvisioningBatch(operation.Id),
      1
    );
    operation.Current_Job_Id__c = nextJobId;
    update operation;
  }

  @TestVisible
  private static String determineFinishAction(
    IManage_Workspace_Provisioning__c operation,
    Integer numberOfErrors
  ) {
    if (operation.Status__c == 'Completed' || operation.Status__c == 'Failed') {
      return FINISH_STOP;
    }
    if (numberOfErrors > 0) {
      return FINISH_FAIL;
    }
    return FINISH_CONTINUE;
  }

  private static void createWorkspaceShell(
    IManage_Workspace_Provisioning__c operation
  ) {
    LicenseService.CheckOrganizationLicense();
    IManageWsProvisioningService.ProvisioningRequest request = IManageWsProvisioningService.deserializeRequest(
      operation.Request_Payload__c
    );
    iManageWrapper.ApiInfo apiInfo = iManageWrapper.GetApiInfo();
    IManageWWorkspace workspace;

    if (String.isBlank(operation.iManage_WS_Id__c)) {
      IManageWorkspaceWrap templateWrap = iManageWorkspacesHelper.getWorkspaceTemplateWrap(
        request.templateId,
        request.libraryId
      );
      if (templateWrap == null) {
        throw new IManageExceptions.IManageApplicationException(
          'Workspace template not found. Template Id: ' + request.templateId
        );
      }
      IManageWWorkspace template = ((IManageWWorkspace) templateWrap.wrapItem)
        .cloneThis();
      template.custom1 = request.clientId;
      template.custom2 = request.matterId;
      template.name = request.workspaceName;
      iManageSettings__c settings = iManageSettings__c.getOrgDefaults();
      workspace = iManageWrapper.createWorkspaceApiCall(
        template,
        apiInfo.customerId,
        request.libraryId,
        settings.iManage_Ws_Owner__c
      );
      operation.iManage_WS_Id__c = workspace.id;
      operation.iManage_WS_Name__c = workspace.name;
      operation.iManage_Library__c = workspace.database;
      iManageWrapper.patchNameValuePair(
        'workspaces',
        workspace.id,
        apiInfo.customerId,
        request.libraryId,
        new Map<String, Object>{ 'templateId' => request.templateId }
      );
    } else {
      workspace = iManageWrapper.getWorkspace(
        operation.iManage_WS_Id__c,
        operation.iManage_Library__c
      );
      if (workspace == null) {
        throw new IManageExceptions.IManageApplicationException(
          'The workspace created by this operation was not found.'
        );
      }
      Map<String, String> values = iManageWrapper.getNameValuePair(
        'workspaces',
        workspace.id,
        apiInfo.customerId,
        operation.iManage_Library__c
      );
      if (String.isBlank(values.get('templateId'))) {
        iManageWrapper.patchNameValuePair(
          'workspaces',
          workspace.id,
          apiInfo.customerId,
          operation.iManage_Library__c,
          new Map<String, Object>{ 'templateId' => operation.Template_Id__c }
        );
      } else if (values.get('templateId') != operation.Template_Id__c) {
        throw new IManageExceptions.IManageApplicationException(
          'The existing workspace uses a different folder template.'
        );
      }
      operation.iManage_WS_Name__c = workspace.name;
      operation.iManage_Library__c = workspace.database;
    }

    operation.Stage__c = 'Folders';
    operation.Status__c = 'InProgress';
    operation.Last_Error__c = null;
    update operation;
  }

  private static void createFolderChunk(
    IManage_Workspace_Provisioning__c operation
  ) {
    IManageWsProvisioningService.ProvisioningRequest request = IManageWsProvisioningService.deserializeRequest(
      operation.Request_Payload__c
    );
    iManageWrapper.ApiInfo apiInfo = iManageWrapper.GetApiInfo();
    IManageWorkspaceWrap workspaceWrap = iManageWorkspacesHelper.getWorkspaceContentWrap(
      operation.iManage_WS_Id__c,
      operation.iManage_Library__c,
      true,
      false
    );
    IManageWorkspaceWrap templateWrap = iManageWorkspacesHelper.getWorkspaceTemplateWrap(
      operation.Template_Id__c,
      operation.iManage_Library__c
    );
    // The live destination tree is the checkpoint between transactions.
    Set<String> skippedFolders = deserializeKeys(operation.Skipped_Folders__c);
    List<IManageFolderWrap> missingFolders = findMissingFolders(
      workspaceWrap,
      templateWrap.getFlatListAllFolders(),
      skippedFolders
    );

    if (missingFolders.isEmpty()) {
      IManageWsProvisioningService.completeOperation(
        operation,
        (IManageWWorkspace) workspaceWrap.wrapItem
      );
      return;
    }

    Integer previousPendingCount = operation.Pending_Folder_Count__c == null
      ? null
      : Integer.valueOf(String.valueOf(operation.Pending_Folder_Count__c));
    if (
      previousPendingCount != null &&
      missingFolders.size() >= previousPendingCount
    ) {
      // Prevent an endless chain when a create is not reflected by the next
      // iManage tree read or folder identity does not converge.
      throw new IManageExceptions.IManageApplicationException(
        'Folder provisioning stopped because the pending folder count did not decrease.'
      );
    }
    operation.Pending_Folder_Count__c = missingFolders.size();

    Integer processed = 0;
    for (IManageFolderWrap folder : missingFolders) {
      String folderType = ((IManageWFolder) folder.wrapItem).folder_type;
      if (!hasCalloutBudget(folderType)) {
        break;
      }
      Boolean created = iManageWorkspacesHelper.createFolderChunkItem(
        apiInfo.customerId,
        operation.iManage_Library__c,
        request.clientId,
        request.matterId,
        folder,
        workspaceWrap
      );
      if (!created) {
        // Optional folders intentionally skipped by existing rules must not be
        // planned again by every continuation transaction.
        skippedFolders.add(folderKey(folder));
        operation.Skipped_Folders__c = serializeKeys(skippedFolders);
      }
      processed++;
    }
    if (processed == 0) {
      throw new IManageExceptions.IManageApplicationException(
        'No folder fit within the remaining callout budget.'
      );
    }

    operation.Skipped_Folders__c = serializeKeys(skippedFolders);
    operation.Status__c = 'InProgress';
    operation.Last_Error__c = null;
    update operation;
  }

  @TestVisible
  private static List<IManageFolderWrap> findMissingFolders(
    IManageWorkspaceWrap workspaceWrap,
    List<IManageFolderWrap> templateFolders,
    Set<String> skippedFolders
  ) {
    Set<String> existing = new Set<String>();
    Set<String> safeSkipped = skippedFolders == null
      ? new Set<String>()
      : skippedFolders;
    for (IManageFolderWrap folder : workspaceWrap.getFlatListAllFolders()) {
      existing.add(folderKey(folder));
    }
    List<IManageFolderWrap> result = new List<IManageFolderWrap>();
    for (IManageFolderWrap folder : templateFolders) {
      String key = folderKey(folder);
      if (!existing.contains(key) && !safeSkipped.contains(key)) {
        insertParentFirst(result, folder);
      }
    }
    return result;
  }

  private static void insertParentFirst(
    List<IManageFolderWrap> folders,
    IManageFolderWrap folder
  ) {
    Integer insertAt = folders.size();
    for (Integer i = 0; i < folders.size(); i++) {
      if (folder.folderFullPath.length() <= folders[i].folderFullPath.length()) {
        insertAt = i;
        break;
      }
    }
    if (insertAt == folders.size()) {
      folders.add(folder);
    } else {
      folders.add(insertAt, folder);
    }
  }

  @TestVisible
  private static Boolean hasCalloutBudget(String folderType) {
    Integer worstCase;
    if ('regular'.equalsIgnoreCase(folderType)) {
      worstCase = 7;
    } else if ('tab'.equalsIgnoreCase(folderType)) {
      worstCase = 6;
    } else if ('search'.equalsIgnoreCase(folderType)) {
      worstCase = 5;
    } else {
      throw new IManageExceptions.IManageApplicationException(
        'Unknown folder type: ' + folderType
      );
    }
    // Never start a folder unless its complete worst-case callout sequence and
    // a fixed safety margin fit in the current transaction.
    return Limits.getLimitCallouts() - Limits.getCallouts() >=
      worstCase + CALLOUT_RESERVE;
  }

  private static String folderKey(IManageFolderWrap folder) {
    IManageWFolder item = (IManageWFolder) folder.wrapItem;
    return item.folder_type.toLowerCase() +
      '|' +
      folder.folderFullPath.toLowerCase();
  }

  private static Set<String> deserializeKeys(String value) {
    Set<String> result = new Set<String>();
    if (String.isBlank(value)) {
      return result;
    }
    for (Object item : (List<Object>) JSON.deserializeUntyped(value)) {
      result.add(String.valueOf(item));
    }
    return result;
  }

  private static String serializeKeys(Set<String> keys) {
    List<String> result = new List<String>();
    result.addAll(keys);
    result.sort();
    return JSON.serialize(result);
  }
}

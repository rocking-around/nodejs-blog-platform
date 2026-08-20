public with sharing class IManageWsProvisioningService {
  private static final Set<String> LIVE_JOB_STATUSES = new Set<String>{
    'Queued',
    'Holding',
    'Preparing',
    'Processing'
  };

  // LWC cannot use Apex inner classes as method parameters or return values.
  // The Aura boundary below therefore exchanges these DTOs as JSON strings.
  public class ProvisioningRequest {
    @AuraEnabled public String entityId { get; set; }
    @AuraEnabled public String workspaceName { get; set; }
    @AuraEnabled public String clientId { get; set; }
    @AuraEnabled public String matterId { get; set; }
    @AuraEnabled public String libraryId { get; set; }
    @AuraEnabled public String templateId { get; set; }
    @AuraEnabled public Boolean autoCreated { get; set; }
    @AuraEnabled public String source { get; set; }
    // Bootstrap snapshots the template setting so every chunk uses one name.
    public String folderNameAffix { get; set; }
    public Boolean folderNameAffixToEnd { get; set; }
  }

  public class ProvisioningStatus {
    @AuraEnabled public String operationId { get; set; }
    @AuraEnabled public String status { get; set; }
    @AuraEnabled public String lastError { get; set; }
    @AuraEnabled public String workspaceId { get; set; }
    @AuraEnabled public String workspaceName { get; set; }
    @AuraEnabled public String workspaceDatabase { get; set; }
  }

  @AuraEnabled
  public static void prepareCustomFields(String entityId, String libraryId) {
    iManageWorkspacesHelper.createCustomFiledsIfNotExist(entityId, libraryId);
  }

  @AuraEnabled
  public static String getActiveProvisioning(String entityId) {
    if (String.isBlank(entityId)) {
      return null;
    }
    List<IManage_Workspace_Provisioning__c> operations = [
      SELECT
        Id,
        Status__c,
        Last_Error__c,
        iManage_WS_Id__c,
        iManage_WS_Name__c,
        iManage_Library__c
      FROM IManage_Workspace_Provisioning__c
      WHERE Active_Key__c = :entityId
      LIMIT 1
    ];
    return operations.isEmpty()
      ? null
      : JSON.serialize(toStatus(operations[0]));
  }

  @AuraEnabled
  public static String startProvisioning(String requestJson) {
    ProvisioningRequest request = deserializeRequest(requestJson);
    validateRequest(request);
    List<IManage_Workspace_Provisioning__c> operations = [
      SELECT
        Id,
        Stage__c,
        Status__c,
        Current_Job_Id__c,
        Request_Payload__c,
        Pending_Folder_Count__c,
        Template_Id__c,
        iManage_Library__c,
        iManage_WS_Id__c
      FROM IManage_Workspace_Provisioning__c
      WHERE Active_Key__c = :request.entityId
      LIMIT 1
      FOR UPDATE
    ];

    IManage_Workspace_Provisioning__c operation;
    if (!operations.isEmpty()) {
      operation = operations[0];
      if (
        (operation.Status__c == 'Pending' ||
        operation.Status__c == 'InProgress') &&
        isLiveJob(operation.Current_Job_Id__c)
      ) {
        return operation.Id;
      }
      if (
        String.isNotBlank(operation.iManage_WS_Id__c) &&
        (operation.Template_Id__c != request.templateId ||
        operation.iManage_Library__c != request.libraryId)
      ) {
        throw new IManageExceptions.IManageApplicationException(
          'The existing workspace provisioning operation uses a different template or library.'
        );
      }
      if (String.isBlank(operation.iManage_WS_Id__c)) {
        operation.Request_Payload__c = JSON.serialize(request);
        operation.Template_Id__c = request.templateId;
        operation.iManage_Library__c = request.libraryId;
      }
      operation.Status__c = operation.Stage__c == 'Folders'
        ? 'InProgress'
        : 'Pending';
      operation.Last_Error__c = null;
      operation.Pending_Folder_Count__c = null;
      update operation;
    } else {
      if (mappingExists(request.entityId, request.libraryId)) {
        throw new IManageExceptions.IManageApplicationException(
          'An iManage workspace mapping already exists for this entity and library.'
        );
      }
      operation = new IManage_Workspace_Provisioning__c(
        Entity_Id__c = request.entityId,
        Active_Key__c = request.entityId,
        Stage__c = 'Bootstrap',
        Status__c = 'Pending',
        Template_Id__c = request.templateId,
        iManage_Library__c = request.libraryId,
        Request_Payload__c = JSON.serialize(request),
        Skipped_Folders__c = '[]'
      );
      try {
        insert operation;
      } catch (DmlException ex) {
        if (ex.getDmlStatusCode(0) != 'DUPLICATE_VALUE') {
          throw ex;
        }
        return [
          SELECT Id
          FROM IManage_Workspace_Provisioning__c
          WHERE Active_Key__c = :request.entityId
          LIMIT 1
        ].Id;
      }
    }

    Id jobId = Database.executeBatch(
      new WorkspaceProvisioningBatch(operation.Id),
      1
    );
    operation.Current_Job_Id__c = jobId;
    update operation;
    return operation.Id;
  }

  @AuraEnabled
  public static String getProvisioningStatus(String operationId) {
    if (String.isBlank(operationId)) {
      throw new IManageExceptions.IManageApplicationException(
        'Provisioning operation Id is required.'
      );
    }
    List<IManage_Workspace_Provisioning__c> operations = [
      SELECT
        Id,
        Status__c,
        Last_Error__c,
        iManage_WS_Id__c,
        iManage_WS_Name__c,
        iManage_Library__c
      FROM IManage_Workspace_Provisioning__c
      WHERE Id = :operationId
      LIMIT 1
    ];
    if (operations.isEmpty()) {
      throw new IManageExceptions.IManageApplicationException(
        'Provisioning operation not found.'
      );
    }
    return JSON.serialize(toStatus(operations[0]));
  }

  public static ProvisioningRequest deserializeRequest(String payload) {
    return (ProvisioningRequest) JSON.deserialize(
      payload,
      ProvisioningRequest.class
    );
  }

  public static void completeOperation(
    IManage_Workspace_Provisioning__c operation,
    IManageWWorkspace workspace
  ) {
    ProvisioningRequest request = deserializeRequest(
      operation.Request_Payload__c
    );
    List<IManage_WS_to_Entity_Mapping__c> mappings = [
      SELECT Id, iManage_WS_Id__c
      FROM IManage_WS_to_Entity_Mapping__c
      WHERE
        EntityId__c = :operation.Entity_Id__c AND
        iManage_Library__c = :operation.iManage_Library__c
    ];
    if (mappings.size() > 1) {
      throw new IManageExceptions.IManageApplicationException(
        'Multiple Salesforce mappings exist for this entity and iManage library.'
      );
    }
    if (
      !mappings.isEmpty() &&
      mappings[0].iManage_WS_Id__c != operation.iManage_WS_Id__c
    ) {
      throw new IManageExceptions.IManageApplicationException(
        'A Salesforce mapping already points to a different iManage workspace.'
      );
    }
    if (mappings.isEmpty()) {
      insert new IManage_WS_to_Entity_Mapping__c(
        Auto_created__c = request.autoCreated == true,
        EntityId__c = operation.Entity_Id__c,
        iManage_Workspace_Created_On__c = workspace.create_date,
        iManage_WS_Id__c = operation.iManage_WS_Id__c,
        Source__c = request.source,
        iManage_Library__c = workspace.database
      );
    }
    operation.iManage_WS_Name__c = workspace.name;
    operation.Status__c = 'Completed';
    operation.Active_Key__c = null;
    operation.Last_Error__c = null;
    update operation;
  }

  private static Boolean mappingExists(String entityId, String libraryId) {
    return [
      SELECT COUNT()
      FROM IManage_WS_to_Entity_Mapping__c
      WHERE EntityId__c = :entityId AND iManage_Library__c = :libraryId
    ] > 0;
  }

  private static Boolean isLiveJob(String jobId) {
    if (String.isBlank(jobId)) {
      return false;
    }
    List<AsyncApexJob> jobs = [
      SELECT Status
      FROM AsyncApexJob
      WHERE Id = :jobId
      LIMIT 1
    ];
    return !jobs.isEmpty() && LIVE_JOB_STATUSES.contains(jobs[0].Status);
  }

  private static ProvisioningStatus toStatus(
    IManage_Workspace_Provisioning__c operation
  ) {
    ProvisioningStatus result = new ProvisioningStatus();
    result.operationId = operation.Id;
    result.status = operation.Status__c;
    result.lastError = operation.Last_Error__c;
    if (operation.Status__c == 'Completed') {
      result.workspaceId = operation.iManage_WS_Id__c;
      result.workspaceName = operation.iManage_WS_Name__c;
      result.workspaceDatabase = operation.iManage_Library__c;
    }
    return result;
  }

  private static void validateRequest(ProvisioningRequest request) {
    if (
      request == null ||
      String.isBlank(request.entityId) ||
      String.isBlank(request.workspaceName) ||
      String.isBlank(request.clientId) ||
      String.isBlank(request.matterId) ||
      String.isBlank(request.libraryId) ||
      String.isBlank(request.templateId)
    ) {
      throw new IManageExceptions.IManageApplicationException(
        'Entity, workspace, client, matter, library, and template values are required.'
      );
    }
    if (String.isBlank(request.source)) {
      request.source = 'SF';
    }
  }
}

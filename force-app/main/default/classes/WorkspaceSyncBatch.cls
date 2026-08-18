public with sharing class WorkspaceSyncBatch
  implements
    Database.Batchable<SObject>,
    Database.AllowsCallouts,
    Database.Stateful {
  // One workspace per transaction gives it a fresh 100-callout budget.
  @TestVisible
  private static final Integer SCOPE_SIZE = 1;

  private Set<Id> entityIds;
  private Integer processedCount = 0;
  private Integer updatedCount = 0;
  private Integer unchangedCount = 0;
  private Integer failedCount = 0;

  private WorkspaceSyncBatch(Set<Id> entityIds) {
    this.entityIds = entityIds == null
      ? new Set<Id>()
      : new Set<Id>(entityIds);
  }

  public static Id enqueue(Set<Id> entityIds) {
    if (entityIds == null || entityIds.isEmpty()) {
      return null;
    }
    return Database.executeBatch(new WorkspaceSyncBatch(entityIds), SCOPE_SIZE);
  }

  public Database.QueryLocator start(Database.BatchableContext context) {
    return Database.getQueryLocator([
      SELECT Id, EntityId__c, iManage_WS_Id__c, iManage_Library__c
      FROM IManage_WS_to_Entity_Mapping__c
      WHERE EntityId__c IN :entityIds
    ]);
  }

  public void execute(
    Database.BatchableContext context,
    List<SObject> scope
  ) {
    for (SObject scopeItem : scope) {
      IManage_WS_to_Entity_Mapping__c mapping = (IManage_WS_to_Entity_Mapping__c) scopeItem;
      processedCount++;
      try {
        if (EntityIManageWorkspaceUpdater.syncWorkspace(mapping)) {
          updatedCount++;
        } else {
          unchangedCount++;
        }
      } catch (Exception ex) {
        failedCount++;
        String errorMessage = String.format(
          'WorkspaceSyncBatch::execute. Workspace update failed (workspace ID = {0}, sObject ID = {1})',
          new List<Object>{ mapping.iManage_WS_Id__c, mapping.EntityId__c }
        );
        Logger.getInstance().error(ex, errorMessage);
      } finally {
        Logger.getInstance().Flush();
      }
    }
  }

  public void finish(Database.BatchableContext context) {
    // An uncatchable governor failure rolls back that scope's stateful counters.
    AsyncApexJob job = [
      SELECT TotalJobItems, JobItemsProcessed, NumberOfErrors
      FROM AsyncApexJob
      WHERE Id = :context.getJobId()
    ];

    Logger.getInstance()
      .info(
        String.format(
          'WorkspaceSyncBatch::finish. Processed = {0}, updated = {1}, unchanged = {2}, application failures = {3}, batch scope errors = {4}, job items processed = {5}, total job items = {6}',
          new List<Object>{
            processedCount,
            updatedCount,
            unchangedCount,
            failedCount,
            job.NumberOfErrors,
            job.JobItemsProcessed,
            job.TotalJobItems
          }
        )
      );

    if (job.NumberOfErrors > 0 || processedCount < job.TotalJobItems) {
      Logger.getInstance()
        .warn(
          String.format(
            'WorkspaceSyncBatch::finish. Unhandled batch scope failures detected. Stateful processed count = {0}, batch scope errors = {1}, total job items = {2}',
            new List<Object>{
              processedCount,
              job.NumberOfErrors,
              job.TotalJobItems
            }
          )
        );
    }
    Logger.getInstance().Flush();
  }
}

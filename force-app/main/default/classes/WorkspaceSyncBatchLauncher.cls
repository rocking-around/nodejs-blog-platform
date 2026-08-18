public with sharing class WorkspaceSyncBatchLauncher implements Queueable {
  private Set<Id> entityIds;

  public WorkspaceSyncBatchLauncher(Set<Id> entityIds) {
    this.entityIds = entityIds == null
      ? new Set<Id>()
      : new Set<Id>(entityIds);
  }

  public void execute(QueueableContext context) {
    // Leave launch failures unhandled so AsyncApexJob records this job as Failed.
    WorkspaceSyncBatch.enqueue(entityIds);
  }
}

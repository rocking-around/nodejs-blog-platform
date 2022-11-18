public with sharing class IManageLinksAndFilesHelper {
  @AuraEnabled
  public static List<IManage_File_Link__c> getLinks(
    String parentId,
    Integer size,
    Integer skip
  ) {
    List<IManage_File_Link__c> result = [
      SELECT Id, LastModifiedDate, Name, File_Link__c, ParentId__c, Version__c
      FROM IManage_File_Link__c
      WHERE ParentId__c = :parentId
      LIMIT :size
      OFFSET :skip
    ];
    return result;
  }

  @AuraEnabled
  public static Integer getLinksCount(String parentId) {
    Integer result = [
      SELECT COUNT()
      FROM IManage_File_Link__c
      WHERE ParentId__c = :parentId
    ];
    return result;
  }

  @AuraEnabled
  public static List<SObject> getFiles(
    String parentId,
    Integer size,
    Integer skip
  ) {
    List<SObject> result = [
      SELECT
        ContentDocumentId,
        LinkedEntityId,
        ContentDocument.id,
        ContentDocument.LastModifiedDate,
        ContentDocument.title,
        ContentDocument.FileExtension,
        ContentDocument.ContentModifiedDate
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :parentId
      LIMIT :size
      OFFSET :skip
    ];
    return result;
  }

  @AuraEnabled
  public static Integer getFilesCount(String parentId) {
    Integer result = [
      SELECT COUNT()
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :parentId
    ];
    return result;
  }
}

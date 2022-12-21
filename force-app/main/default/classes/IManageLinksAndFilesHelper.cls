public with sharing class IManageLinksAndFilesHelper {
  @AuraEnabled
  public static List<IManage_File_Link__c> getLinks(
    String parentId,
    Integer size,
    Integer skip
  ) {
    LicenseService.CheckOrganizationLicense();

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
    LicenseService.CheckOrganizationLicense();

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
    LicenseService.CheckOrganizationLicense();

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
    LicenseService.CheckOrganizationLicense();

    Integer result = [
      SELECT COUNT()
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :parentId
    ];
    return result;
  }

  @AuraEnabled
  public static List<iManageDocumentMetadata__c> getIManageDocumentsMetadata(
    List<Id> entityIds
  ) {
    LicenseService.CheckOrganizationLicense();

    return [
      SELECT
        Name,
        Document_Version__c,
        DocNumber__c,
        Document_Author__c,
        EntityId__c
      FROM iManageDocumentMetadata__c
      WHERE EntityId__c IN :entityIds
    ];
  }

  @AuraEnabled
  public static Void deleteLink(Id id) {
    LicenseService.CheckOrganizationLicense();

    IManage_File_Link__c[] links = [
      SELECT Id, LastModifiedDate, Name, File_Link__c, ParentId__c, Version__c
      FROM IManage_File_Link__c
      WHERE Id = :id
    ];
    delete links;
  }

  @AuraEnabled
  public static Void deleteFile(Id id) {
    LicenseService.CheckOrganizationLicense();

    ContentDocument[] contentDocuments = [
      SELECT Id
      FROM ContentDocument
      WHERE Id = :Id
    ];
    delete contentDocuments;
  }

  @AuraEnabled
  public static Boolean isEnabledForRecord(Id recordId) {
    LicenseService.CheckOrganizationLicense();

    String sObjName = Id.valueOf(recordId)
      .getSObjectType()
      .getDescribe()
      .getName();
    Map<String, Object> config = ConfigurationHelper.getIManageDocumentSettings();
    switch on sObjName {
      when 'Event' {
        return config.containsKey('iManageDocuments:Calendar') &&
          (Boolean) config.get('iManageDocuments:Calendar');
      }
      when 'Task' {
        return config.containsKey('iManageDocuments:Task') &&
          (Boolean) config.get('iManageDocuments:Task');
      }
      when 'litify_pm__Matter__c' {
        return config.containsKey('iManageDocuments:Matter') &&
          (Boolean) config.get('iManageDocuments:Matter');
      }
      when 'litify_pm__Intake__c' {
        return config.containsKey('iManageDocuments:Intake_Document');
      }
      when 'litify_pm__lit_Note__c' {
        return config.containsKey('iManageDocuments:Matter_Document');
      }
      when else {
        throw new IManageExceptions.IManageSettingsException('Not configured');
      }
    }
  }

  @AuraEnabled
  public static Id saveIManageDocumentMetadata(
    Id entityId,
    Map<String, Object> metadata
  ) {
    LicenseService.CheckOrganizationLicense();

    deleteIManageDocumentMetadata(entityId);

    iManageDocumentMetadata__c md = new iManageDocumentMetadata__c(
      EntityId__c = entityId,
      Name = String.valueOf(metadata.get('name')),
      Document_Version__c = String.valueOf(metadata.get('version')),
      DocNumber__c = String.valueOf(metadata.get('document_number')),
      Document_Author__c = String.valueOf(metadata.get('author'))
    );
    insert md;
    return md.Id;
  }

  @AuraEnabled
  public static Void deleteIManageDocumentMetadata(Id entityId) {
    LicenseService.CheckOrganizationLicense();

    List<iManageDocumentMetadata__c> existingMetadata = [
      SELECT
        Id,
        Name,
        EntityId__c,
        Document_Version__c,
        DocNumber__c,
        Document_Author__c
      FROM iManageDocumentMetadata__c
      WHERE EntityId__c = :entityId
    ];
    delete existingMetadata;
  }

  @AuraEnabled
  public static Void changeIManageDocumentMetadataEntity(
    Id entityId,
    Id newEntityId
  ) {
    LicenseService.CheckOrganizationLicense();

    List<iManageDocumentMetadata__c> existingMetadata = [
      SELECT
        Id,
        Name,
        EntityId__c,
        Document_Version__c,
        DocNumber__c,
        Document_Author__c
      FROM iManageDocumentMetadata__c
      WHERE EntityId__c = :entityId
    ];
    for (iManageDocumentMetadata__c md : existingMetadata) {
      md.EntityId__c = newEntityId;
    }
    update existingMetadata;
  }
}

public with sharing class IManageLinksAndFilesHelper {
  @AuraEnabled
  public static List<IManage_File_Link__c> getLinks(
    String parentId,
    Integer size,
    Integer skip
  ) {
    Map<String, Object> params = new Map<String, Object>{
      'parentId' => parentId,
      'size' => size,
      'skip' => skip
    };

    Logger.getInstance()
      .info(
        'IManageLinksAndFilesHelper::getLinks, start method. Params: ' +
        JSON.serialize(params)
      );

    LicenseService.CheckOrganizationLicense();

    try {
      List<IManage_File_Link__c> result = [
        SELECT Id, LastModifiedDate, Name, File_Link__c, ParentId__c, Version__c
        FROM IManage_File_Link__c
        WHERE ParentId__c = :parentId
        LIMIT :size
        OFFSET :skip
      ];
      Logger.getInstance()
        .info(
          'IManageLinksAndFilesHelper::getLinks, Result: ' +
          result?.size() +
          ' items(s)'
        );
      return result;
    } catch (Exception ex) {
      Logger.getInstance().error(ex, 'IManageLinksAndFilesHelper::getLinks');
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
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
    Map<String, Object> params = new Map<String, Object>{
      'parentId' => parentId,
      'size' => size,
      'skip' => skip
    };

    Logger.getInstance()
      .info(
        'IManageLinksAndFilesHelper::getFiles, start method. Params: ' +
        JSON.serialize(params)
      );

    LicenseService.CheckOrganizationLicense();

    try {
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
      Logger.getInstance()
        .info(
          'IManageLinksAndFilesHelper::getFiles, Result: ' +
          result?.size() +
          ' items(s)'
        );
      return result;
    } catch (Exception ex) {
      Logger.getInstance().error(ex, 'IManageLinksAndFilesHelper::getFiles');
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
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
  public static List<Map<String, Object>> getIManageDocumentsMetadata(
    List<Id> entityIds
  ) {
    Map<String, Object> params = new Map<String, Object>{
      'entityIds' => entityIds
    };

    Logger.getInstance()
      .info(
        'IManageLinksAndFilesHelper::getIManageDocumentsMetadata, start method. Params: ' +
        JSON.serialize(params)
      );

    LicenseService.CheckOrganizationLicense();

    try {
      List<iManageDocumentMetadata__c> metadata = [
        SELECT
          Name,
          Document_Version__c,
          DocNumber__c,
          Document_Class__c,
          Document_Author__c,
          EntityId__c
        FROM iManageDocumentMetadata__c
        WHERE EntityId__c IN :entityIds
      ];

      List<Map<String, Object>> result = new List<Map<String, Object>>();
      for (iManageDocumentMetadata__c md : metadata) {
        result.add(
          new Map<String, Object>{
            'Name' => md.Name,
            'Document_Version__c' => md.Document_Version__c,
            'DocNumber__c' => md.DocNumber__c,
            'Document_Class__c' => md.Document_Class__c,
            'Document_Author__c' => md.Document_Author__c,
            'EntityId__c' => md.EntityId__c
          }
        );
      }
      Logger.getInstance()
        .info(
          'IManageLinksAndFilesHelper::getIManageDocumentsMetadata, Result: ' +
          JSON.serialize(result)
        );
      return result;
    } catch (Exception ex) {
      Logger.getInstance()
        .error(ex, 'IManageLinksAndFilesHelper::getIManageDocumentsMetadata');
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
  }

  @AuraEnabled
  public static List<IManage_Folder_Link__c> getFolderLinks(
    String parentId,
    Integer size,
    Integer skip
  ) {
    String logPrefix = 'ManageLinksAndFilesHelper::getFolderLinks';

    try {
      Map<String, Object> params = new Map<String, Object>{
        'parentId' => parentId,
        'size' => size,
        'skip' => skip
      };

      Logger.getInstance()
        .info(
          logPrefix + ', start method. Params: ' +
          JSON.serialize(params)
        );

      LicenseService.CheckOrganizationLicense();

      List<IManage_Folder_Link__c> result = [
        SELECT Id, LastModifiedDate, Name, EntityId__c, iManage_Id__c, iManage_Library__c
        FROM IManage_Folder_Link__c
        WHERE EntityId__c = :parentId
        LIMIT :size
        OFFSET :skip
      ];
      Logger.getInstance()
        .info(
          logPrefix + ', Result: ' +
          result?.size() +
          ' items(s)'
        );
      return result;
    } catch (Exception ex) {
      Logger.getInstance().error(ex, logPrefix);
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
  }

  @AuraEnabled
  public static Integer getFolderLinksCount(String parentId) {
    LicenseService.CheckOrganizationLicense();

    Integer result = [
      SELECT COUNT()
      FROM IManage_Folder_Link__c
      WHERE EntityId__c = :parentId
    ];
    return result;
  }

  @AuraEnabled
  public static Void deleteLink(Id id) {
    Map<String, Object> params = new Map<String, Object>{ 'id' => id };

    Logger.getInstance()
      .info(
        'IManageLinksAndFilesHelper::deleteLink, start method. Params: ' +
        JSON.serialize(params)
      );
    LicenseService.CheckOrganizationLicense();

    try {
      IManage_File_Link__c[] links = [
        SELECT Id, LastModifiedDate, Name, File_Link__c, ParentId__c, Version__c
        FROM IManage_File_Link__c
        WHERE Id = :id
      ];
      delete links;
      Logger.getInstance()
        .info(
          'IManageLinksAndFilesHelper::deleteLink, Deleted' +
          links?.size() +
          ' item(s)'
        );
    } catch (Exception ex) {
      Logger.getInstance().error(ex, 'IManageLinksAndFilesHelper::deleteLink');
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
  }

  @AuraEnabled
  public static Void deleteFile(Id id) {
    Map<String, Object> params = new Map<String, Object>{ 'id' => id };

    Logger.getInstance()
      .info(
        'IManageLinksAndFilesHelper::deleteFile, start method. Params: ' +
        JSON.serialize(params)
      );
    LicenseService.CheckOrganizationLicense();

    try {
      ContentDocument[] contentDocuments = [
        SELECT Id
        FROM ContentDocument
        WHERE Id = :Id
      ];
      delete contentDocuments;
      Logger.getInstance()
        .info(
          'IManageLinksAndFilesHelper::deleteFile, Deleted' +
          contentDocuments?.size() +
          ' item(s)'
        );
    } catch (Exception ex) {
      Logger.getInstance().error(ex, 'IManageLinksAndFilesHelper::deleteFile');
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
  }

  @AuraEnabled
  public static Void deleteFolderLink(Id id) {
    String logPrefix = 'ManageLinksAndFilesHelper::deleteFolderLink';
    try {
      Map<String, Object> params = new Map<String, Object>{ 'id' => id };

      Logger.getInstance()
        .info(
          logPrefix + ', start method. Params: ' +
          JSON.serialize(params)
        );
      LicenseService.CheckOrganizationLicense();

      IManage_Folder_Link__c[] links = [
        SELECT Id
        FROM IManage_Folder_Link__c
        WHERE Id = :id
      ];
      delete links;
      Logger.getInstance()
        .info(
          logPrefix + ', Deleted' +
          links?.size() +
          ' item(s)'
        );
    } catch (Exception ex) {
      Logger.getInstance().error(ex, logPrefix);
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
  }

  @AuraEnabled
  public static Boolean isEnabledForRecord(Id recordId) {
    Map<String, Object> params = new Map<String, Object>{
      'recordId' => recordId
    };

    Logger.getInstance()
      .info(
        'IManageLinksAndFilesHelper::isEnabledForRecord, start method. Params: ' +
        JSON.serialize(params)
      );

    LicenseService.CheckOrganizationLicense();

    try {
      String sObjName = Id.valueOf(recordId)
        .getSObjectType()
        .getDescribe()
        .getName();

      Boolean result = isEnabledForRecord(sObjName);
      Logger.getInstance()
        .info(
          'IManageLinksAndFilesHelper::isEnabledForRecord, Result: ' + result
        );
      return result;
    } catch (Exception ex) {
      Logger.getInstance()
        .error(ex, 'IManageLinksAndFilesHelper::isEnabledForRecord');
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
  }

  @TestVisible
  private static Boolean isEnabledForRecord(String sObjName) {
    Map<String, Object> params = new Map<String, Object>{
      'sObjName' => sObjName
    };

    Logger.getInstance()
      .info(
        'iManageFileWorker::isEnabledForRecord, start method. Params: ' +
        JSON.serialize(params)
      );

    iManageSettings__c mc = iManageSettings__c.getOrgDefaults();
    Map<String, Object> config = ConfigurationHelper.getIManageDocumentSettings();

    Logger.getInstance()
      .info(
        'IManageLinksAndFilesHelper::isEnabledForRecord, iManageSettings = ' +
        JSON.serialize(mc)
      );

    if (sObjName == mc.gdsi_imanage__Mapping_EntityMatterIdObjectField__c)
      return config.containsKey('iManageDocuments:Matter') &&
        (Boolean) config.get('iManageDocuments:Matter');

    if (sObjName == mc.gdsi_imanage__Mapping_EntityClientIdObjectField__c) {
      return config.containsKey('iManageDocuments:Client') &&
        (Boolean) config.get('iManageDocuments:Client');
    }

    switch on sObjName {
      when 'Event' {
        return config.containsKey('iManageDocuments:Calendar') &&
          (Boolean) config.get('iManageDocuments:Calendar');
      }
      when 'Task' {
        return config.containsKey('iManageDocuments:Task') &&
          (Boolean) config.get('iManageDocuments:Task');
      }
      when 'Account' {
        return config.containsKey('iManageDocuments:Client') &&
          (Boolean) config.get('iManageDocuments:Client');
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
        return false;
        //throw new IManageExceptions.IManageSettingsException('Not configured');
      }
    }
  }

  @AuraEnabled
  public static Id saveIManageDocumentMetadata(
    Id entityId,
    Map<String, Object> metadata
  ) {
    Map<String, Object> params = new Map<String, Object>{
      'entityId' => entityId,
      'metadata' => metadata
    };

    Logger.getInstance()
      .info(
        'iManageFileWorker::saveIManageDocumentMetadata, start method. Params: ' +
        JSON.serialize(params)
      );
    LicenseService.CheckOrganizationLicense();

    try {
      clearIManageDocumentMetadata(entityId);

      iManageDocumentMetadata__c md = new iManageDocumentMetadata__c(
        EntityId__c = entityId,
        Name = String.valueOf(metadata.get('name')),
        Document_Version__c = String.valueOf(metadata.get('version')),
        DocNumber__c = String.valueOf(metadata.get('document_number')),
        Document_Author__c = String.valueOf(metadata.get('author')),
        Document_Class__c = String.valueOf(metadata.get('document_class'))
      );
      insert md;
      Logger.getInstance()
        .info(
          'iManageFileWorker::saveIManageDocumentMetadata, Saved. Id = ' + md.Id
        );
      return md.Id;
    } catch (Exception ex) {
      Logger.getInstance()
        .error(ex, 'iManageFileWorker::saveIManageDocumentMetadata');
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
  }

  @AuraEnabled
  public static Void deleteIManageDocumentMetadata(Id entityId) {
    Map<String, Object> params = new Map<String, Object>{
      'entityId' => entityId
    };

    Logger.getInstance()
      .info(
        'iManageFileWorker::deleteIManageDocumentMetadata, start method. Params: ' +
        JSON.serialize(params)
      );
    LicenseService.CheckOrganizationLicense();
    try {
      clearIManageDocumentMetadata(entityId);
    } catch (Exception ex) {
      Logger.getInstance()
        .error(ex, 'iManageFileWorker::deleteIManageDocumentMetadata');
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
  }

  @AuraEnabled
  public static Id saveFolderLinkFromIManage(
    String recordId,
    Map<String, Object> folderData
  ) {
    String logPrefix = 'ManageLinksAndFilesHelper::saveFolderLinkFromIManage';
    try {
      String imFolderId = String.valueOf(folderData.get('id'));
      String imLibrary = String.valueOf(folderData.get('database'));
      String name = String.valueOf(folderData.get('name'));
      IManage_Folder_Link__c sobj = new IManage_Folder_Link__c(
        EntityId__c = recordId,
        iManage_Id__c = imFolderId,
        iManage_Library__c = imLibrary,
        Name = name
      );
      insert sobj;
      return sobj.Id;
    } catch (Exception ex) {
      Logger.getInstance().error(ex, logPrefix);
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
  }

  private static Void clearIManageDocumentMetadata(Id entityId) {
    Map<String, Object> params = new Map<String, Object>{
      'entityId' => entityId
    };

    Logger.getInstance()
      .info(
        'iManageFileWorker::clearIManageDocumentMetadata, start method. Params: ' +
        JSON.serialize(params)
      );

    LicenseService.CheckOrganizationLicense();

    List<iManageDocumentMetadata__c> existingMetadata = [
      SELECT Id
      FROM iManageDocumentMetadata__c
      WHERE EntityId__c = :entityId
    ];
    delete existingMetadata;
    Logger.getInstance()
      .info(
        'iManageFileWorker::clearIManageDocumentMetadata, Deleted  ' +
        existingMetadata?.size() +
        ' item(s)'
      );
  }

  @AuraEnabled
  public static Void changeIManageDocumentMetadataEntity(
    Id entityId,
    Id newEntityId
  ) {
    Map<String, Object> params = new Map<String, Object>{
      'entityId' => entityId,
      'newEntityId' => newEntityId
    };

    Logger.getInstance()
      .info(
        'iManageFileWorker::changeIManageDocumentMetadataEntity, start method. Params: ' +
        JSON.serialize(params)
      );

    LicenseService.CheckOrganizationLicense();

    try {
      List<iManageDocumentMetadata__c> existingMetadata = [
        SELECT
          Id,
          Name,
          EntityId__c,
          Document_Version__c,
          Document_Class__c,
          DocNumber__c,
          Document_Author__c
        FROM iManageDocumentMetadata__c
        WHERE EntityId__c = :entityId
      ];
      for (iManageDocumentMetadata__c md : existingMetadata) {
        md.EntityId__c = newEntityId;
      }
      update existingMetadata;
      Logger.getInstance()
        .info(
          'iManageFileWorker::changeIManageDocumentMetadataEntity, Updated  ' +
          existingMetadata?.size() +
          ' item(s)'
        );
    } catch (Exception ex) {
      Logger.getInstance()
        .error(ex, 'iManageFileWorker::changeIManageDocumentMetadataEntity');
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
  }
}

public with sharing class ConfigurationHelper {
  static final String INCORRECT_SYMBOLS = '(_|[^\\w\\s])';

  @AuraEnabled
  public static Void checkOrganizationLicense() {
    try {
      LicenseService.CheckOrganizationLicense();
    } catch (Exception e) {
      Organization org = [SELECT id FROM Organization];
      String message =
        'Organization Id = "' +
        org.Id +
        '". \n' +
        e.getMessage();
      if (Request.getCurrent().getQuiddity() == System.Quiddity.AURA) {
        throw new AuraHandledException(message);
      } else {
        throw new IManageExceptions.IManageLicenseException(message);
      }
    }
  }

  @AuraEnabled
  public static Map<String, Object> getGeneralSettings() {
    Logger.getInstance()
      .info('ConfigurationHelper::getGeneralSettings, start method');
    LicenseService.CheckOrganizationLicense();

    try {
      iManageSettings__c settings = iManageSettings__c.getOrgDefaults();

      Map<String, Object> result = new Map<String, Object>{
        'general:Url' => settings.Url__c,
        'general:MatterField' => settings.MatterField__c,
        'general:Client_Id' => settings.Client_Id__c,
        'general:ClientField' => settings.ClientField__c,
        'general:Enable_CSV_Export' => settings.Enable_CSV_Export__c,
        'general:Verbose_Logging' => settings.Verbose_Logging__c
      };

      Logger.getInstance()
        .info(
          'ConfigurationHelper::getGeneralSettings, result: ' +
          JSON.serialize(result)
        );
      return result;
    } catch (Exception ex) {
      Logger.getInstance().error(ex, 'ConfigurationHelper::getGeneralSettings');
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
  }

  @AuraEnabled
  public static void saveGeneralSettings(Map<String, Object> data) {
    Map<String, Object> params = new Map<String, Object>{ 'data' => data };
    Logger.getInstance()
      .info(
        'ConfigurationHelper::saveGeneralSettings, start method. Params: ' +
        JSON.serialize(data)
      );
    LicenseService.CheckOrganizationLicense();

    try {
      iManageSettings__c settings = iManageSettings__c.getOrgDefaults();

      for (String key : data.keySet()) {
        switch on key {
          when 'general:Url' {
            settings.Url__c = (String) data.get(key);
          }
          when 'general:MatterField' {
            settings.MatterField__c = (String) data.get(key);
          }
          when 'general:Client_Id' {
            settings.Client_Id__c = (String) data.get(key);
          }
          when 'general:ClientField' {
            settings.ClientField__c = (String) data.get(key);
          }
          when 'general:Enable_CSV_Export' {
            settings.Enable_CSV_Export__c = (Boolean) data.get(key);
          }
          when 'general:Verbose_Logging' {
            settings.Verbose_Logging__c = (Boolean) data.get(key);
          }
        }
      }

      upsert settings;
      Logger.getInstance()
        .info(
          'ConfigurationHelper::saveGeneralSettings. Saved: ' +
          JSON.serialize(settings)
        );
    } catch (Exception ex) {
      Logger.getInstance()
        .error(ex, 'ConfigurationHelper::saveGeneralSettings');
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
  }

  @AuraEnabled
  public static Map<String, Object> getIManageDocumentSettings() {
    Logger.getInstance()
      .info('ConfigurationHelper::getIManageDocumentSettings, start');
    LicenseService.CheckOrganizationLicense();

    try {
      List<iManageDocumentSettings__c> docSettings = [
        SELECT
          Id,
          Calendar__c,
          Task__c,
          Intake_Document__c,
          Matter_Document__c,
          Matter__c,
          Client__c,
          Save_Document__c,
          Save_Link__c,
          Save_Folder_Link__c
        FROM iManageDocumentSettings__c
      ];

      if (docSettings.size() > 1) {
        throw new IManageExceptions.IManageSettingsException(
          'iManageDocumentSettings__c has more than 1 record'
        );
      }

      iManageDocumentSettings__c settings = docSettings.size() > 0
        ? docSettings.get(0)
        : new iManageDocumentSettings__c(
            Calendar__c = false,
            Task__c = false,
            Intake_Document__c = false,
            Matter_Document__c = false,
            Matter__c = false,
            Client__c = false,
            Save_Document__c = false,
            Save_Link__c = false,
            Save_Folder_Link__c = false
          );

      Map<String, Object> result = new Map<String, Object>{
        'iManageDocuments:Calendar' => settings.Calendar__c,
        'iManageDocuments:Task' => settings.Task__c,
        'iManageDocuments:Intake_Document' => settings.Intake_Document__c,
        'iManageDocuments:Matter_Document' => settings.Matter_Document__c,
        'iManageDocuments:Matter' => settings.Matter__c,
        'iManageDocuments:Client' => settings.Client__c,
        'iManageDocuments:Save_Document' => settings.Save_Document__c,
        'iManageDocuments:Save_Link' => settings.Save_Link__c,
        'iManageDocuments:Save_Folder_Link' => settings.Save_Folder_Link__c
      };

      Logger.getInstance()
        .info(
          'ConfigurationHelper::saveGeneralSettings. Result: ' +
          JSON.serialize(result)
        );
      return result;
    } catch (IManageExceptions.IManageSettingsException ex) {
      throw ex;
    } catch (Exception ex) {
      Logger.getInstance()
        .error(ex, 'ConfigurationHelper::getIManageDocumentSettings');
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
  }

  @AuraEnabled
  public static void saveIManageDocumentsSettings(Map<String, Object> data) {
    Map<String, Object> params = new Map<String, Object>{ 'data' => data };
    Logger.getInstance()
      .info(
        'ConfigurationHelper::saveIManageDocumentsSettings, start method. Params: ' +
        JSON.serialize(data)
      );

    LicenseService.CheckOrganizationLicense();

    try {
      List<iManageDocumentSettings__c> docSettings = [
        SELECT
          Id,
          Calendar__c,
          Task__c,
          Intake_Document__c,
          Matter_Document__c,
          Matter__c,
          Client__c,
          Save_Document__c,
          Save_Link__c,
          Save_Folder_Link__c
        FROM iManageDocumentSettings__c
      ];

      if (docSettings.size() > 1) {
        throw new IManageExceptions.IManageSettingsException(
          'iManageDocumentSettings__c has more than 1 record'
        );
      }

      iManageDocumentSettings__c settings = docSettings.size() > 0
        ? docSettings.get(0)
        : new iManageDocumentSettings__c(
            Calendar__c = false,
            Task__c = false,
            Intake_Document__c = false,
            Matter_Document__c = false,
            Matter__c = false,
            Client__c = false,
            Save_Document__c = false,
            Save_Link__c = false,
            Save_Folder_Link__c = false
          );

      for (String key : data.keySet()) {
        switch on key {
          when 'iManageDocuments:Calendar' {
            settings.Calendar__c = (Boolean) data.get(key);
          }
          when 'iManageDocuments:Task' {
            settings.Task__c = (Boolean) data.get(key);
          }
          when 'iManageDocuments:Intake_Document' {
            settings.Intake_Document__c = (Boolean) data.get(key);
          }
          when 'iManageDocuments:Matter_Document' {
            settings.Matter_Document__c = (Boolean) data.get(key);
          }
          when 'iManageDocuments:Matter' {
            settings.Matter__c = (Boolean) data.get(key);
          }
          when 'iManageDocuments:Client' {
            settings.Client__c = (Boolean) data.get(key);
          }
          when 'iManageDocuments:Save_Document' {
            settings.Save_Document__c = (Boolean) data.get(key);
          }
          when 'iManageDocuments:Save_Link' {
            settings.Save_Link__c = (Boolean) data.get(key);
          }
          when 'iManageDocuments:Save_Folder_Link' {
            settings.Save_Folder_Link__c = (Boolean) data.get(key);
          }
        }
      }

      Logger.getInstance()
        .info(
          'ConfigurationHelper::saveIManageDocumentsSettings, Saved: ' +
          JSON.serialize(settings)
        );
      upsert settings;
    } catch (IManageExceptions.IManageSettingsException ex) {
      throw ex;
    } catch (Exception ex) {
      Logger.getInstance()
        .error(ex, 'ConfigurationHelper::saveIManageDocumentsSettings');
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
  }

  @AuraEnabled
  public static String getIManageDefaultFolderId() {
    Logger.getInstance()
      .info('ConfigurationHelper::getIManageDefaultFolderId, start method');
    LicenseService.CheckOrganizationLicense();

    try {
      iManageSettings__c settings = iManageSettings__c.getOrgDefaults();
      Logger.getInstance()
        .info(
          'ConfigurationHelper::getIManageDefaultFolderId, Result: ' +
          settings?.iManage_Default_Folder_Id__c
        );
      return settings.iManage_Default_Folder_Id__c;
    } catch (Exception ex) {
      Logger.getInstance()
        .error(ex, 'ConfigurationHelper::getIManageDefaultFolderId');
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
  }

  @AuraEnabled
  public static void saveManualIManageDefaultFolderPath(String folderPath) {
    Map<String, Object> params = new Map<String, Object>{
      'folderPath' => folderPath
    };
    Logger.getInstance()
      .info(
        'ConfigurationHelper::saveManualIManageDefaultFolderPath, start method. Params: ' +
        JSON.serialize(params)
      );

    LicenseService.CheckOrganizationLicense();

    try {
      if (!IsFolderPathCorrect(folderPath)) {
        System.debug(
          'saveManualIManageDefaultFolderPath. The path is incorrect: ' +
          folderPath
        );
        throw IManageBaseHelper.BuildException(
          IManageBaseHelper.IManageErrors.INCORRECT_FOLDER_NAME
        );
      }

      iManageSettings__c settings = iManageSettings__c.getOrgDefaults();
      settings.iManage_Default_Folder_Id__c = folderPath;

      upsert settings;
      System.debug(
        'saveManualIManageDefaultFolderPath. Saved: ' + JSON.serialize(settings)
      );
    } catch (AuraHandledException ex) {
      Logger.getInstance()
        .error(ex, 'ConfigurationHelper::saveManualIManageDefaultFolderPath');
      throw ex;
    } catch (Exception ex) {
      Logger.getInstance()
        .error(ex, 'ConfigurationHelper::saveManualIManageDefaultFolderPath');
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
  }

  @AuraEnabled
  public static void saveIManageDefaultFolderId(String folderId) {
    Map<String, Object> params = new Map<String, Object>{
      'folderId' => folderId
    };
    Logger.getInstance()
      .info(
        'ConfigurationHelper::saveIManageDefaultFolderId, start method. Params: ' +
        JSON.serialize(params)
      );

    LicenseService.CheckOrganizationLicense();

    try {
      iManageSettings__c settings = iManageSettings__c.getOrgDefaults();
      settings.iManage_Default_Folder_Id__c = getIManageFolderStructure(
        folderId
      );

      upsert settings;
      Logger.getInstance()
        .info(
          'ConfigurationHelper::saveIManageDefaultFolderId. Saved: ' +
          JSON.serialize(settings)
        );
    } catch (Exception ex) {
      Logger.getInstance()
        .error(ex, 'ConfigurationHelper::saveIManageDefaultFolderId');
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
  }

  @AuraEnabled
  public static String GetIManageLibraries() {
    Logger.getInstance()
      .info('ConfigurationHelper::GetIManageLibraries, start method');
    LicenseService.CheckOrganizationLicense();

    try {
      iManageSettings__c settings = iManageSettings__c.getOrgDefaults();
      Logger.getInstance()
        .info(
          'ConfigurationHelper::GetIManageLibraries, Result: ' +
          settings?.iManage_Libraries__c
        );
      return settings.iManage_Libraries__c;
    } catch (Exception ex) {
      Logger.getInstance()
        .error(ex, 'ConfigurationHelper::GetIManageLibraries');
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
  }

  @AuraEnabled
  public static void SaveIManageLibraries(String libraries) {
    Map<String, Object> params = new Map<String, Object>{
      'libraries' => libraries
    };
    Logger.getInstance()
      .info(
        'ConfigurationHelper::SaveIManageLibraries, start method. Params: ' +
        JSON.serialize(params)
      );

    LicenseService.CheckOrganizationLicense();

    try {
      iManageSettings__c settings = iManageSettings__c.getOrgDefaults();
      settings.iManage_Libraries__c = libraries;

      upsert settings;
      System.debug('SaveIManageLibraries. Saved: ' + JSON.serialize(settings));
    } catch (AuraHandledException ex) {
      Logger.getInstance()
        .error(ex, 'ConfigurationHelper::SaveIManageLibraries');
      throw ex;
    } catch (Exception ex) {
      Logger.getInstance()
        .error(ex, 'ConfigurationHelper::SaveIManageLibraries');
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
  }

  @AuraEnabled
  public static String GetIManageAvailableLibraries() {
    Logger.getInstance()
      .info('ConfigurationHelper::GetIManageAvailableLibraries, start method');
    LicenseService.CheckOrganizationLicense();

    try {
      iManageWrapper.ApiInfo apiInfo = iManageWrapper.GetApiInfo();
      List<iManageWrapper.iManageLibrary> results = iManageWrapper.GetLibraries(
        apiInfo.customerId
      );
      String result = '';
      for (iManageWrapper.iManageLibrary lib : results) {
        if (result == '')
          result = lib.id;
        else
          result += ';' + lib.id;
      }
      Logger.getInstance()
        .info(
          'ConfigurationHelper::GetIManageAvailableLibraries, Result: ' + result
        );
      return result;
    } catch (Exception ex) {
      Logger.getInstance()
        .error(ex, 'ConfigurationHelper::GetIManageAvailableLibraries');
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
  }

  public static String getIManageFolderStructure(String folderId) {
    Map<String, Object> params = new Map<String, Object>{
      'folderId' => folderId
    };
    Logger.getInstance()
      .info(
        'ConfigurationHelper::getIManageFolderStructure, start method. Params: ' +
        JSON.serialize(params)
      );

    LicenseService.CheckOrganizationLicense();

    try {
      iManageWrapper.ApiInfo apiInfo = iManageWrapper.GetApiInfo();
      iManageWrapper.iManageFolder folder = iManageWrapper.GetFolder(
        apiInfo.customerId,
        apiInfo.library,
        folderId
      );
      String folderStructure = folder.name;
      system.debug(folder.name);
      system.debug(folder.parent_id);

      Logger.getInstance()
        .info(
          'ConfigurationHelper::getIManageFolderStructure, folder.name  = ' +
          folder?.name
        );
      Logger.getInstance()
        .info(
          'ConfigurationHelper::getIManageFolderStructure, folder.parent_id  = ' +
          folder?.parent_id
        );

      while (
        folder != null &&
        folder.parent_id != '' &&
        folder.parent_id != null
      ) {
        folder = iManageWrapper.GetFolder(
          apiInfo.customerId,
          apiInfo.library,
          folder.parent_id
        );

        if (folder != null && folder.name != null && folder.name != '') {
          if (folder.id == folder.workspace_id)
            folder = null;
          else
            folderStructure = folder.name + '/' + folderStructure;
        }
      }
      Logger.getInstance()
        .info(
          'ConfigurationHelper::getIManageFolderStructure, Resiult: ' +
          folderStructure
        );
      return folderStructure;
    } catch (Exception ex) {
      Logger.getInstance()
        .error(ex, 'ConfigurationHelper::getIManageFolderStructure');
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
  }

  private static Boolean IsFolderPathCorrect(String folderPath) {
    Map<String, Object> params = new Map<String, Object>{
      'folderPath' => folderPath
    };
    Logger.getInstance()
      .info(
        'ConfigurationHelper::IsFolderPathCorrect, start method. Params: ' +
        JSON.serialize(params)
      );

    Boolean result = true;
    if (String.isBlank(folderPath)) {
      result = false;
    } else {
      String[] folders = folderPath.split('/');
      for (string folder : folders) {
        if (
          String.isBlank(folder) ||
          folder != folder.replaceAll(INCORRECT_SYMBOLS, '')
        ) {
          result = false;
          break;
        }
      }
    }
    Logger.getInstance()
      .info('ConfigurationHelper::IsFolderPathCorrect, Result: ' + result);
    return result;
  }

  @AuraEnabled
  public static Map<String, String> loadFolderTemplates() {
    try {
      Logger.getInstance().info('ConfigurationHelper::loadFolderTemplates');
      LicenseService.CheckOrganizationLicense();

      iManageSettings__c mc = iManageSettings__c.getOrgDefaults();
      iManageWrapper.ApiInfo apiInfo = iManageWrapper.GetApiInfo();
      Set<String>libraries = new Set<String>();
      if (String.isNotBlank(mc?.iManage_Libraries__c)) {
        libraries.addAll(mc?.iManage_Libraries__c.split(';'));
      }
      if (String.isNotBlank(apiInfo?.library)) {
        libraries.add(apiInfo?.library);
      }

      Map<String, String> templates = new Map<String, String>();

      for (String libraryId : libraries) {
        Integer offset = 0;
        Integer batchSize = 2000;
        try {
          iManageWrapper.iManageTemplatesResponse resp = iManageWrapper.searchTemplateWorkspace(
            apiInfo.customerId,
            libraryId,
            null,
            offset,
            batchSize
          );
  
          if (resp.data?.results != null) {
            for (IManageWWorkspace templ : resp.data.results) {
              String key = libraryId + '::' + templ.id;
              templates.put(key, libraryId + ' : ' + templ.name);
            }
          }
        }
        catch (Exception ex1) {
          Logger.getInstance()
            .error(ex1, 'ConfigurationHelper::loadFolderTemplates. Error fetching templates for the "' + libraryId + '" library.');
        }
      }

      return templates;
    } catch (Exception ex) {
      Logger.getInstance()
        .error(ex, 'ConfigurationHelper::loadFolderTemplates');
      Logger.getInstance().Flush();
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
  }

  @AuraEnabled
  public static Map<String, Object> getIManageWorkspaceSettings() {
    Logger.getInstance()
      .info('ConfigurationHelper::getIManageWorkspaceSettings, start method');
    LicenseService.CheckOrganizationLicense();

    try {
      iManageSettings__c settings = iManageSettings__c.getOrgDefaults();

      Map<String, Object> result = new Map<String, Object>{
        'iManageWs:Name_Pattern' => settings.iManage_Ws_Name_Pattern__c,
        'iManageWs:Create_Ws_Enabled' => settings.iManage_Create_Ws_Enabled__c,
        'iManageWs:Auto_Create' => settings.iManage_Ws_Auto_Create__c,
        'iManageWs:Folder_Template_Id' => settings.iManage_Ws_Folder_Template_Id__c
      };

      Logger.getInstance()
        .info(
          'ConfigurationHelper::getIManageWorkspaceSettings, result: ' +
          JSON.serialize(result)
        );
      return result;
    } catch (Exception ex) {
      Logger.getInstance()
        .error(ex, 'ConfigurationHelper::getIManageWorkspaceSettings');
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
  }

  @AuraEnabled
  public static void saveIManageWorkspaceSettings(Map<String, Object> data) {
    Map<String, Object> params = new Map<String, Object>{ 'data' => data };
    Logger.getInstance()
      .info(
        'ConfigurationHelper::saveIManageWorkspaceSettings, start method. Params: ' +
        JSON.serialize(data)
      );
    LicenseService.CheckOrganizationLicense();

    try {
      iManageSettings__c settings = iManageSettings__c.getOrgDefaults();

      for (String key : data.keySet()) {
        switch on key {
          when 'iManageWs:Name_Pattern' {
            settings.iManage_Ws_Name_Pattern__c = (String) data.get(key);
          }
          when 'iManageWs:Folder_Template_Id' {
            settings.iManage_Ws_Folder_Template_Id__c = (String) data.get(key);
          }
          when 'iManageWs:Create_Ws_Enabled' {
            settings.iManage_Create_Ws_Enabled__c = (Boolean) data.get(key);
          }
          when 'iManageWs:Auto_Create' {
            settings.iManage_Ws_Auto_Create__c = (Boolean) data.get(key);
          }
        }
      }

      upsert settings;
      Logger.getInstance()
        .info(
          'ConfigurationHelper::saveIManageWorkspaceSettings. Saved: ' +
          JSON.serialize(settings)
        );
    } catch (Exception ex) {
      Logger.getInstance()
        .error(ex, 'ConfigurationHelper::saveIManageWorkspaceSettings');
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
  }
}

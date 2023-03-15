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
    LicenseService.CheckOrganizationLicense();

    iManageSettings__c settings = iManageSettings__c.getOrgDefaults();

    Map<String, Object> result = new Map<String, Object>{
      'general:Url' => settings.Url__c,
      'general:MatterField' => settings.MatterField__c,
      'general:Client_Id' => settings.Client_Id__c,
      'general:ClientField' => settings.ClientField__c,
      'general:Enable_CSV_Export' => settings.Enable_CSV_Export__c
    };

    return result;
  }

  @AuraEnabled
  public static void saveGeneralSettings(Map<String, Object> data) {
    LicenseService.CheckOrganizationLicense();

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
      }
    }

    upsert settings;
  }

  @AuraEnabled
  public static Map<String, Object> getIManageDocumentSettings() {
    LicenseService.CheckOrganizationLicense();

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
        Save_Link__c
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
          Save_Link__c = false
        );

    Map<String, Object> result = new Map<String, Object>{
      'iManageDocuments:Calendar' => settings.Calendar__c,
      'iManageDocuments:Task' => settings.Task__c,
      'iManageDocuments:Intake_Document' => settings.Intake_Document__c,
      'iManageDocuments:Matter_Document' => settings.Matter_Document__c,
      'iManageDocuments:Matter' => settings.Matter__c,
      'iManageDocuments:Client' => settings.Client__c,
      'iManageDocuments:Save_Document' => settings.Save_Document__c,
      'iManageDocuments:Save_Link' => settings.Save_Link__c
    };
    return result;
  }

  @AuraEnabled
  public static void saveIManageDocumentsSettings(Map<String, Object> data) {
    LicenseService.CheckOrganizationLicense();

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
        Save_Link__c
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
          Save_Link__c = false
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
      }
    }

    upsert settings;
  }

  @AuraEnabled
  public static String getIManageDefaultFolderId() {
    LicenseService.CheckOrganizationLicense();

    iManageSettings__c settings = iManageSettings__c.getOrgDefaults();

    return settings.iManage_Default_Folder_Id__c;
  }

  @AuraEnabled
  public static void saveManualIManageDefaultFolderPath(String folderPath) {
    System.debug('saveManualIManageDefaultFolderPath("' + folderPath + '")');
    LicenseService.CheckOrganizationLicense();

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
  }

  @AuraEnabled
  public static void saveIManageDefaultFolderId(String folderId) {
    LicenseService.CheckOrganizationLicense();

    iManageSettings__c settings = iManageSettings__c.getOrgDefaults();
    settings.iManage_Default_Folder_Id__c = getIManageFolderStructure(folderId);

    upsert settings;
  }

  public static String getIManageFolderStructure(String folderId) {
    LicenseService.CheckOrganizationLicense();
    iManageWrapper.ApiInfo apiInfo = iManageWrapper.GetApiInfo();
    iManageWrapper.iManageFolder folder = iManageWrapper.GetFolder(
      apiInfo.customerId,
      apiInfo.library,
      folderId
    );
    String folderStructure = folder.name;
    system.debug(folder.name);
    system.debug(folder.parent_id);

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
    return folderStructure;
  }

  private static Boolean IsFolderPathCorrect(String folderPath) {
    System.debug('IsFolderPathCorrect("' + folderPath + '")');
    if (String.isBlank(folderPath))
      return false;
    String[] folders = folderPath.split('/');
    for (string folder : folders) {
      if (
        String.isBlank(folder) ||
        folder != folder.replaceAll(INCORRECT_SYMBOLS, '')
      )
        return false;
    }

    return true;
  }
}

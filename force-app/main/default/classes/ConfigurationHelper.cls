public with sharing class ConfigurationHelper {
  @AuraEnabled
  public static Map<String, Object> getGeneralSettings() {
    LicenseService.CheckOrganizationLicense();

    iManageSettings__c settings = iManageSettings__c.getOrgDefaults();

    Map<String, Object> result = new Map<String, Object>{
      // 'mapping:ClientIdField' => settings.Mapping_ClientIdField__c,
      // 'mapping:ClientNameField' => settings.Mapping_ClientNameField__c,
      // 'mapping:EntityClientIdObjectField' => settings.Mapping_EntityClientIdObjectField__c,
      // 'mapping:EntityMatterIdObjectField' => settings.Mapping_EntityMatterIdObjectField__c,
      // 'mapping:EntityType' => settings.Mapping_EntityType__c,
      // 'mapping:MatterIdField' => settings.Mapping_MatterIdField__c,
      // 'mapping:MatterNameField' => settings.Mapping_MatterNameField__c,
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
          Save_Document__c = false,
          Save_Link__c = false
        );

    Map<String, Object> result = new Map<String, Object>{
      'iManageDocuments:Calendar' => settings.Calendar__c,
      'iManageDocuments:Task' => settings.Task__c,
      'iManageDocuments:Intake_Document' => settings.Intake_Document__c,
      'iManageDocuments:Matter_Document' => settings.Matter_Document__c,
      'iManageDocuments:Matter' => settings.Matter__c,
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
}

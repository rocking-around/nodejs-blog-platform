@isTest
public with sharing class ConfigurationHelperTests {
  static testMethod void saveAndGetGeneralSettingsTest() {
    TestUtils.setupMockActiveLicense();

    String urlKey = 'general:Url';
    String matterFieldKey = 'general:MatterField';
    String clientIdKey = 'general:Client_Id';
    String clientFieldKey = 'general:ClientField';
    String csvExportKey = 'general:Enable_CSV_Export';
    Map<String, Object> data = new Map<String, Object>{
      urlKey => 'http://test.test',
      matterFieldKey => 'f1',
      clientIdKey => 'f2',
      clientFieldKey => 'f3',
      csvExportKey => true
    };
    Test.startTest();
    ConfigurationHelper.saveGeneralSettings(data);
    Map<String, Object> result = ConfigurationHelper.getGeneralSettings();
    Test.stopTest();
    System.assert(
      (String) result.get(urlKey) == (String) data.get(urlKey),
      'Url has wrong value'
    );
    System.assert(
      (String) result.get(matterFieldKey) == (String) data.get(matterFieldKey),
      'MatterField has wrong value'
    );
    System.assert(
      (String) result.get(clientIdKey) == (String) data.get(clientIdKey),
      'Client_Id has wrong value'
    );
    System.assert(
      (String) result.get(clientFieldKey) == (String) data.get(clientFieldKey),
      'ClientField has wrong value'
    );
    System.assert(
      (Boolean) result.get(csvExportKey) == (Boolean) data.get(csvExportKey),
      'Enable_CSV_Export has wrong value'
    );
  }

  static testMethod void getIManageDocumentSettingsTest() {
    TestUtils.setupMockActiveLicense();

    // add settings
    iManageDocumentSettings__c docSettings = new iManageDocumentSettings__c();
    docSettings.Calendar__c = true;
    docSettings.Task__c = false;
    docSettings.Intake_Document__c = true;
    docSettings.Matter_Document__c = true;
    docSettings.Matter__c = true;
    insert docSettings;

    Test.startTest();
    Map<String, Object> result = ConfigurationHelper.getIManageDocumentSettings();
    Test.stopTest();

    Boolean calendar = (Boolean) result.get('iManageDocuments:Calendar');
    Boolean task = (Boolean) result.get('iManageDocuments:Task');
    Boolean intakeDoc = (Boolean) result.get(
      'iManageDocuments:Intake_Document'
    );
    Boolean matterDoc = (Boolean) result.get(
      'iManageDocuments:Matter_Document'
    );
    Boolean matter = (Boolean) result.get('iManageDocuments:Matter');

    System.assert(calendar, 'Calendar should be enabled');
    System.assert(!task, 'Task should be disabled');
    System.assert(intakeDoc, 'Intake_Document should be enabled');
    System.assert(matterDoc, 'Matter_Document should be enabled');
    System.assert(matter, 'Matter should be enabled');
  }

  static testMethod void saveIManageDocumentsSettingsTest() {
    TestUtils.setupMockActiveLicense();

    Map<String, Object> data = new Map<String, Object>{
      'iManageDocuments:Calendar' => false,
      'iManageDocuments:Task' => true,
      'iManageDocuments:Intake_Document' => false,
      'iManageDocuments:Matter_Document' => true,
      'iManageDocuments:Matter' => false,
      'iManageDocuments:Save_Document' => true,
      'iManageDocuments:Save_Link' => true
    };
    Test.startTest();
    ConfigurationHelper.saveIManageDocumentsSettings(data);
    Map<String, Object> result = ConfigurationHelper.getIManageDocumentSettings();
    Test.stopTest();

    Boolean calendar = (Boolean) result.get('iManageDocuments:Calendar');
    Boolean task = (Boolean) result.get('iManageDocuments:Task');
    Boolean intakeDoc = (Boolean) result.get(
      'iManageDocuments:Intake_Document'
    );
    Boolean matterDoc = (Boolean) result.get(
      'iManageDocuments:Matter_Document'
    );
    Boolean matter = (Boolean) result.get('iManageDocuments:Matter');
    Boolean saveDoc = (Boolean) result.get('iManageDocuments:Save_Document');
    Boolean saveLink = (Boolean) result.get('iManageDocuments:Save_Link');

    System.assert(!calendar, 'Calendar should be enabled');
    System.assert(task, 'Task should be disabled');
    System.assert(!intakeDoc, 'Intake_Document should be enabled');
    System.assert(matterDoc, 'Matter_Document should be enabled');
    System.assert(!matter, 'Matter should be enabled');
    System.assert(saveDoc, 'Save_Document should be enabled');
    System.assert(saveLink, 'Save_Link should be enabled');
  }

  static testMethod void getIManageDefaultFolderIdTest() {
    TestUtils.setupMockActiveLicense();

    String defaultFolder = 'test folder';
    iManageSettings__c settings = new iManageSettings__c(
      Client_Id__c = 'val1',
      ClientField__c = 'val2',
      MatterField__c = 'val3',
      Url__c = 'val4',
      Enable_CSV_Export__c = true,
      Mapping_EntityType__c = 'Opportunity',
      Mapping_EntityMatterIdObjectField__c = 'Opportunity',
      Mapping_MatterIdField__c = 'Id',
      Mapping_MatterNameField__c = 'Name',
      Mapping_EntityClientIdObjectField__c = 'Opportunity',
      Mapping_ClientIdField__c = 'Id',
      Mapping_ClientNameField__c = 'Name',
      iManage_Default_Folder_Id__c = defaultFolder
    );
    insert settings;

    Test.startTest();
    String result = ConfigurationHelper.getIManageDefaultFolderId();
    Test.stopTest();

    System.assert(
      result == defaultFolder,
      'iManage_Default_Folder_Id__c has wrong value'
    );
  }
}

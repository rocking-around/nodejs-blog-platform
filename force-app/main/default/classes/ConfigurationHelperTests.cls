@isTest
public with sharing class ConfigurationHelperTests {
  static testMethod void saveAndGetGeneralSettingsTest() {
    TestUtils.setupMockActiveLicense();

    String urlKey = 'general:Url';
    String matterFieldKey = 'general:MatterField';
    String clientIdKey = 'general:Client_Id';
    String clientFieldKey = 'general:ClientField';
    String csvExportKey = 'general:Enable_CSV_Export';
    String loggingKey = 'general:Verbose_Logging';
    Map<String, Object> data = new Map<String, Object>{
      urlKey => 'http://test.test',
      matterFieldKey => 'f1',
      clientIdKey => 'f2',
      clientFieldKey => 'f3',
      csvExportKey => true,
      loggingKey => true
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
    System.assert(
      (Boolean) result.get(loggingKey) == (Boolean) data.get(loggingKey),
      'Verbose_Logging has wrong value'
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
    docSettings.Save_Folder_Link__c = true;
    docSettings.ClassCaption__c = 'Class';
    docSettings.SubClassCaption__c = 'SubClass';
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
    Boolean saveFolderLink = (Boolean) result.get('iManageDocuments:Save_Folder_Link');
    String classCaption = (String)result.get('iManageDocuments:ClassCaption');
    String subClassCaption = (String)result.get('iManageDocuments:SubClassCaption');

    System.assert(calendar, 'Calendar should be enabled');
    System.assert(!task, 'Task should be disabled');
    System.assert(intakeDoc, 'Intake_Document should be enabled');
    System.assert(matterDoc, 'Matter_Document should be enabled');
    System.assert(matter, 'Matter should be enabled');
    System.assert(saveFolderLink, 'Matter should be enabled');
    System.assert(classCaption == 'Class' , 'ClassCaption has wrong value');
    System.assert(subClassCaption == 'SubClass' , 'SubClassCaption has wrong value');  
  }

  static testMethod void saveIManageDocumentsSettingsTest() {
    TestUtils.setupMockActiveLicense();

    Map<String, Object> data = new Map<String, Object>{
      'iManageDocuments:Calendar' => false,
      'iManageDocuments:Task' => true,
      'iManageDocuments:Intake_Document' => false,
      'iManageDocuments:Matter_Document' => true,
      'iManageDocuments:Matter' => false,
      'iManageDocuments:Client' => true,
      'iManageDocuments:Save_Document' => true,
      'iManageDocuments:Save_Link' => true,
      'iManageDocuments:ClassCaption' => 'Class',
      'iManageDocuments:SubClassCaption' => 'SubClass'
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
    Boolean client = (Boolean) result.get('iManageDocuments:Client');
    Boolean saveDoc = (Boolean) result.get('iManageDocuments:Save_Document');
    Boolean saveLink = (Boolean) result.get('iManageDocuments:Save_Link');
    String classCaption = (String)result.get('iManageDocuments:ClassCaption');
    String subClassCaption = (String)result.get('iManageDocuments:SubClassCaption');

    System.assert(!calendar, 'Calendar should be enabled');
    System.assert(task, 'Task should be disabled');
    System.assert(!intakeDoc, 'Intake_Document should be enabled');
    System.assert(matterDoc, 'Matter_Document should be enabled');
    System.assert(!matter, 'Matter should not be enabled');
    System.assert(client, 'Client should be enabled');
    System.assert(saveDoc, 'Save_Document should be enabled');
    System.assert(saveLink, 'Save_Link should be enabled');
    System.assert(classCaption == 'Class' , 'ClassCaption has wrong value');
    System.assert(subClassCaption == 'SubClass' , 'SubClassCaption has wrong value');  
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
      Verbose_Logging__c = true,
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

  static testMethod void checkOrganizationLicenseTest() {
    TestUtils.setupMockInvalidLicense();
    Test.startTest();
    try {
      ConfigurationHelper.checkOrganizationLicense();
    } catch (Exception ex) {
      System.debug(
        'checkOrganizationLicense. Error message: ' + ex.getMessage()
      );
      System.assert(
        ex.getMessage().contains('Organization Id'),
        'Error message does not contains Organization Id'
      );
    }
    Test.stopTest();
  }

  static testMethod void saveManualIManageDefaultFolderPathTest() {
    TestUtils.setupMockActiveLicense();

    iManageSettings__c settings = new iManageSettings__c(
      Client_Id__c = 'val1',
      ClientField__c = 'val2',
      MatterField__c = 'val3',
      Url__c = 'val4',
      Enable_CSV_Export__c = true,
      Verbose_Logging__c = true,
      Mapping_EntityType__c = 'Opportunity',
      Mapping_EntityMatterIdObjectField__c = 'Opportunity',
      Mapping_MatterIdField__c = 'Id',
      Mapping_MatterNameField__c = 'Name',
      Mapping_EntityClientIdObjectField__c = 'Opportunity',
      Mapping_ClientIdField__c = 'Id',
      Mapping_ClientNameField__c = 'Name',
      iManage_Default_Folder_Id__c = 'test-folder'
    );
    insert settings;

    String folderPath = 'folder1/folder2';
    Test.startTest();
    ConfigurationHelper.saveManualIManageDefaultFolderPath(folderPath);
    iManageSettings__c currentSettings = iManageSettings__c.getOrgDefaults();
    Test.stopTest();
    System.assert(
      currentSettings.iManage_Default_Folder_Id__c == folderPath,
      'Folder Id has wrong value'
    );
  }

  static testMethod void saveIManageDefaultFolderIdTest() {
    Map<String, HttpResponse> licenseResponces = TestUtils.getMockActiveLicenseResponse();

    iManageSettings__c settings = new iManageSettings__c(
      Client_Id__c = 'val1',
      ClientField__c = 'val2',
      MatterField__c = 'val3',
      Url__c = 'val4',
      Enable_CSV_Export__c = true,
      Verbose_Logging__c = true,
      Mapping_EntityType__c = 'Opportunity',
      Mapping_EntityMatterIdObjectField__c = 'Opportunity',
      Mapping_MatterIdField__c = 'Id',
      Mapping_MatterNameField__c = 'Name',
      Mapping_EntityClientIdObjectField__c = 'Opportunity',
      Mapping_ClientIdField__c = 'Id',
      Mapping_ClientNameField__c = 'Name',
      iManage_Default_Folder_Id__c = 'test-folder'
    );
    insert settings;

    String customerId = 'cust-1';
    String library = 'lib-1';
    String folderId = 'folder-1';
    String folderName = 'folder-1-name';
    String getFoderQuery =
      '/work/api/v2/customers/' +
      customerId +
      '/libraries/' +
      library +
      '/folders/' +
      folderId;

    ///work/api/v2/customers/1/libraries/LOCAL/folders/folder-1

    Map<String, HttpResponse> responses = new Map<String, HttpResponse>{
      getFoderQuery => getMockFolderResponse(
        200,
        'authenticated',
        folderId,
        folderName
      ),
      'callout:iManageCreds/api' => getMockAuthResponse(
        200,
        'authenticated',
        customerId,
        library
      )
    };
    responses.putAll(licenseResponces);
    EchoHttpMock.setTestMockResponse(responses);

    Test.startTest();
    ConfigurationHelper.saveIManageDefaultFolderId(folderId);
    String currentFolder = ConfigurationHelper.getIManageDefaultFolderId();
    Test.stopTest();

    System.assert(currentFolder == folderName, 'Folder Id has wrong value');
  }

  @IsTest
  static void saveAndGetIManageLibrariesTest() {
    String libraries = 'lib1;lib2';
    iManageSettings__c settings = new iManageSettings__c(
      Client_Id__c = 'val1',
      ClientField__c = 'val2',
      MatterField__c = 'val3',
      Url__c = 'val4',
      Enable_CSV_Export__c = true,
      Verbose_Logging__c = true,
      Mapping_EntityType__c = 'Opportunity',
      Mapping_EntityMatterIdObjectField__c = 'Opportunity',
      Mapping_MatterIdField__c = 'Id',
      Mapping_MatterNameField__c = 'Name',
      Mapping_EntityClientIdObjectField__c = 'Opportunity',
      Mapping_ClientIdField__c = 'Id',
      Mapping_ClientNameField__c = 'Name',
      iManage_Default_Folder_Id__c = 'test-folder',
      iManage_Libraries__c = ''
    );
    insert settings;

    TestUtils.setupMockActiveLicense();

    Test.startTest();
    ConfigurationHelper.SaveIManageLibraries(libraries);
    String libs = ConfigurationHelper.GetIManageLibraries();
    Test.stopTest();
    System.assert(libs == libraries, 'libs has wrong value = ' + libs + ', expected = ' + libraries);
  }

  @IsTest
  static void getIManageAvailableLibrariesTest() {
    String customerId = '1';
    String preferredLib = '';

    iManageWrapper.iManageLibrary lib1 = new iManageWrapper.iManageLibrary();
    lib1.id = 'l1';
    lib1.type = 't1';
    lib1.is_hidden = false;

    iManageWrapper.iManageLibrary lib2 = new iManageWrapper.iManageLibrary();
    lib2.id = 'l2';
    lib2.type = 't2';
    lib2.is_hidden = true;

    List<iManageWrapper.iManageLibrary> libs = new List<iManageWrapper.iManageLibrary> { lib1, lib2 };
    // mock callouts
    TestUtils.setupMockActiveLicense();

    Map<String, List<HttpResponse>> responses = new Map<String, List<HttpResponse>>{
        'callout:iManageCreds/api' => new List<HttpResponse> {
          getMockAuthResponse(
            200,
            'authenticated',
            customerId,
            preferredLib
          )
        },
        TestUtils.buildCalloutUrl('/work/api/v2/customers/' + customerId + '/libraries', null) => new List<HttpResponse> {
          getMockIManageLibrariesResponse(
            200,
            libs
          )
      }
    };
    Map<String, HttpResponse> licenseResp = TestUtils.getMockActiveLicenseResponse();
    responses.putAll(TestUtils.getMockActiveLicenseResponses(1));

    HttpCalloutQueueMock.setTestMockResponse(responses, true);
    // --
    Test.startTest();
    String result = ConfigurationHelper.GetIManageAvailableLibraries();
    Test.stopTest();
    String expectedResult = lib1.id + ';' + lib2.id;
    System.assert(result == expectedResult, 'result has wrong value = ' + result + ', expected = ' + expectedResult);
  }

  @IsTest
  static void iManageWorkspaceSettingsTest() {
    String libraries = 'lib1;lib2';
    iManageSettings__c settings = new iManageSettings__c(
      Client_Id__c = 'val1',
      ClientField__c = 'val2',
      MatterField__c = 'val3',
      Url__c = 'val4',
      Enable_CSV_Export__c = true,
      Verbose_Logging__c = true,
      Mapping_EntityType__c = 'Opportunity',
      Mapping_EntityMatterIdObjectField__c = 'Opportunity',
      Mapping_MatterIdField__c = 'Id',
      Mapping_MatterNameField__c = 'Name',
      Mapping_EntityClientIdObjectField__c = 'Opportunity',
      Mapping_ClientIdField__c = 'Id',
      Mapping_ClientNameField__c = 'Name',
      iManage_Default_Folder_Id__c = 'test-folder',
      iManage_Libraries__c = ''
    );
    insert settings;
    String folderTemplate = 'xxx';
    String namePattern = 'yyy';
    Boolean createWsEnabled = false;
    Boolean autoCreate = true;
    Map<String, Object> wsSettings = new Map<String, Object> {
      'iManageWs:Name_Pattern' => namePattern,
      'iManageWs:Folder_Template_Id' => folderTemplate,
      'iManageWs:Create_Ws_Enabled' =>  createWsEnabled,
      'iManageWs:Auto_Create' => autoCreate
    };

    TestUtils.setupMockActiveLicense();

    Test.startTest();
    ConfigurationHelper.saveIManageWorkspaceSettings(wsSettings);
    Map<String, Object> result = ConfigurationHelper.getIManageWorkspaceSettings();
    Test.stopTest();
    System.assert(String.valueOf(result.get('iManageWs:Name_Pattern')) == namePattern, 'Name_Pattern has wrong value');
    System.assert(String.valueOf(result.get('iManageWs:Folder_Template_Id')) == folderTemplate, 'Folder_Template_Id has wrong value');
    System.assert(Boolean.valueOf(result.get('iManageWs:Create_Ws_Enabled')) == createWsEnabled, 'Create_Ws_Enabled has wrong value');
    System.assert(Boolean.valueOf(result.get('iManageWs:Auto_Create')) == autoCreate, 'Auto_Create has wrong value');
  }

  @IsTest
  static void loadFolderTemplatesTest() {
    String customerId = '1';
    String iManageLib = 'lib1';
    String workspaceId = 'ws1';
    String templateName = 'wsTemplate1';

    iManageSettings__c settings = new iManageSettings__c(
      Client_Id__c = 'val1',
      ClientField__c = 'val2',
      MatterField__c = 'val3',
      Url__c = 'val4',
      Mapping_EntityType__c = 'Opportunity',
      Mapping_EntityMatterIdObjectField__c = 'Opportunity',
      Mapping_MatterIdField__c = 'Id',
      Mapping_MatterNameField__c = 'Name',
      Mapping_EntityClientIdObjectField__c = 'Opportunity',
      Mapping_ClientIdField__c = 'Id',
      Mapping_ClientNameField__c = 'Name',
      iManage_Default_Folder_Id__c = 'test-folder',
      iManage_Libraries__c = iManageLib
    );
    insert settings;
    // mock callouts
    TestUtils.setupMockActiveLicense();

    String searchWsTemplate = TestUtils.buildCalloutUrl(
      '/work/api/v2/customers/{0}/libraries/{1}/templates?offset={2}&limit={3}&total=true',
      new List<Object>{ customerId, iManageLib, 0, 2000 }
    );
    IManageWWorkspace ws = new IManageWWorkspace();
    ws.id = workspaceId;
    ws.name = templateName;
    List<IManageWWorkspace> wss = new List<IManageWWorkspace> {ws};

    Map<String, List<HttpResponse>> responses = new Map<String, List<HttpResponse>>{
        'callout:iManageCreds/api' => new List<HttpResponse> {
          getMockAuthResponse(
            200,
            'authenticated',
            customerId,
            iManageLib
          )
        },
        searchWsTemplate => new List<HttpResponse> {
          getSearchTemplateWorkspaceResponse(
            200,
            wss
          )
      }
    };

    Map<String, HttpResponse> licenseResp = TestUtils.getMockActiveLicenseResponse();
    responses.putAll(TestUtils.getMockActiveLicenseResponses(1));

    HttpCalloutQueueMock.setTestMockResponse(responses, true);
    // --
    Test.startTest();
    Map<String, String> result = ConfigurationHelper.loadFolderTemplates();
    Test.stopTest();

    String expectedKey = iManageLib + '::' + workspaceId;
    String expectedValue = iManageLib + ' : ' + templateName;
    System.assert(result.containsKey(expectedKey), 'Expected key "' + expectedKey + '" not found');
    System.assert(result.get(expectedKey) == expectedValue, 'template name  has wrong value = ' + result.get(expectedKey) + ', expected = ' + expectedValue);
  }

  @IsTest
  static void deleteFromLitifyListTest() {

    iManageSettings__c settings = new iManageSettings__c(
      Client_Id__c = 'val1',
      ClientField__c = 'val2',
      MatterField__c = 'val3',
      Url__c = 'val4',
      Mapping_EntityType__c = 'Opportunity',
      Mapping_EntityMatterIdObjectField__c = 'Opportunity',
      Mapping_MatterIdField__c = 'Id',
      Mapping_MatterNameField__c = 'Name',
      Mapping_EntityClientIdObjectField__c = 'Account',
      Mapping_ClientIdField__c = 'Id',
      Mapping_ClientNameField__c = 'Name',
      iManage_Default_Folder_Id__c = 'test-folder',
      iManage_Libraries__c = 'lib1'
    );
    insert settings;
    // mock callouts
    TestUtils.setupMockActiveLicense();


    // --
    Test.startTest();
    String result = ConfigurationHelper.DeleteFromLitifyList('0064H00001Rd6VTQAZ', '0064H00001Rd6VTQAZ');
    Test.stopTest();

    System.assert(result == 'Error:Workspace is not found.', 'Find workpace error');
  }


  private static HttpResponse getMockFolderResponse(
    Integer statusCode,
    String auth_status,
    String folderId,
    String folderName
  ) {
    HttpResponse resp = new HttpResponse();
    if (String.isEmpty(auth_status)) {
      auth_status = 'authenticated';
    }
    resp.setStatusCode(statusCode);
    resp.setBody(
      '{"data":{"project_custom3":"active_uk|91|522","database":"active_uk","default_security":"inherit","activity_date":"2022-06-13T16:53:48Z","edit_date":"2022-06-13T16:53:48Z","folder_type":"regular","has_documents":true,"has_subfolders":false,"id":"' +
      folderId +
      '","inherited_default_security":"public","is_container_saved_search":false,"is_content_saved_search":false,"is_external_as_normal":false,"name":"' +
      folderName +
      '","owner":"ADMINISTRATOR","owner_description":"Administrator","parent_id": null,"view_type":"document","wstype":"folder","workspace_id":"ws-01","workspace_name":"ws-01"}}'
    );
    return resp;
  }

  private static HttpResponse getMockAuthResponse(
    Integer statusCode,
    String auth_status,
    String customerId,
    String library
  ) {
    HttpResponse resp = new HttpResponse();
    if (String.isEmpty(auth_status)) {
      auth_status = 'authenticated';
    }
    resp.setStatusCode(statusCode);
    resp.setBody(
      '{"data": { "user": { "id":"12345","name":"test test","email":"test@test.test","customer_id":"' +
      customerId +
      '" }, "work": { "preferred_library": "' +
      library +
      '" }}}'
    );
    return resp;
  }

  private static HttpResponse getMockIManageLibrariesResponse(Integer statusCode, List<iManageWrapper.iManageLibrary> data) {
    HttpResponse resp = new HttpResponse();
    resp.setStatusCode(statusCode);
    iManageWrapper.iManageLibraries body = new iManageWrapper.iManageLibraries();
    body.data = data;
    resp.setBody(JSON.serialize(body));
    return resp;
  }

  private static HttpResponse getSearchTemplateWorkspaceResponse(Integer statusCode, List<IManageWWorkspace> wss){
    HttpResponse resp = new HttpResponse();
    resp.setStatusCode(statusCode);

    iManageWrapper.iManageTemplates searchResults = new iManageWrapper.iManageTemplates();
    searchResults.results = wss;
    iManageWrapper.iManageTemplatesResponse body = new iManageWrapper.iManageTemplatesResponse();
    body.data = searchResults;
    body.total_count = wss.size();

    resp.setBody(JSON.serialize(body));
    return resp;
  }
}

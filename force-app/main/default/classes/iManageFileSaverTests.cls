@isTest
public class iManageFileSaverTests {
  @testSetup
  static void testSetup() {
    // create settings
    System.debug('Create iManageSettings');
    iManageSettings__c settings = new iManageSettings__c(
      Client_Id__c = 'val1',
      ClientField__c = 'custom1',
      MatterField__c = 'custom2',
      Url__c = 'https://imanage.test',
      Customer_Id__c = '0',
      Enable_CSV_Export__c = false,
      Verbose_Logging__c = false,
      Mapping_EntityType__c = 'Opportunity',
      Mapping_EntityMatterIdObjectField__c = 'Opportunity',
      Mapping_MatterIdField__c = 'Id',
      Mapping_MatterNameField__c = 'Name',
      Mapping_EntityClientIdObjectField__c = 'Opportunity',
      Mapping_ClientIdField__c = 'Id',
      Mapping_ClientNameField__c = 'Name',
      iManage_Default_Folder_Id__c = 'Test1',
      Mapping_LibraryField__c = ''
    );
    insert settings;
    IManageMappingMigration.migrateLegacyMapping();
  }

  static testMethod void getFolderByStructureTest() {
    String workspaceId = 'ws-1';
    String folderId = 'folder-1';
    String folderStructure = folderId;
    Integer customerId = 333;
    String library = folderId = 'ACTIVE';

    String searchQuery =
      '/work/api/v2/customers/' +
      String.valueOf(customerId) +
      '/libraries/' +
      library +
      '/folders/search';

    Map<String, HttpResponse> responses = new Map<String, HttpResponse>{
      'callout:iManageCreds/api' => getMockAuthResponse(
        200,
        'authenticated',
        customerId
      ),
      searchQuery => getMockFolderSearchResponse(200, 'authenticated', folderId)
    };
    EchoHttpMock.setTestMockResponse(responses);

    Test.startTest();
    iManageWrapper.ApiInfo apiInfo = iManageWrapper.GetApiInfo();
    String result = iManageFileSaver.GetFolderByStructure(
      apiInfo,
      workspaceId,
      folderStructure
    );
    Test.stopTest();

    System.assert(
      result.contains(folderId),
      'The folder structure has wrong walue'
    );
  }

  static testMethod void saveFileTest() {
    iManageSettings__c ims = iManageSettings__c.getOrgDefaults();

    //Create Matter
    Opportunity matter = new Opportunity(
      StageName = '100',
      Name = '10',
      CloseDate = system.now().addDays(30).date()
    );
    insert matter;

    Blob data = Blob.valueOf('test data');
    String name = 'file name';
    String extension = 'txt';
    String entityId = String.valueOf(matter.Id);

    String workspaceId = 'ws-1';
    String folderId = 'folder-1';
    String folderStructure = folderId;
    Integer customerId = 333;
    String library = folderId = 'ACTIVE';

    Organization org = [SELECT Id FROM Organization];
    String orgId = String.valueOf(org.Id);
    String licenseUrl = LicenseService.baseUrl + '/api/License/organization';

    String searchFolderQuery =
      '/work/api/v2/customers/' +
      String.valueOf(customerId) +
      '/libraries/' +
      library +
      '/folders/search';

    String serchWorkspaceQuery =
      '/work/api/v2/customers/' +
      customerId +
      '/libraries/' +
      library +
      '/workspaces?' +
      ims.MatterField__c +
      '=' +
      matter.Id +
      '&' +
      ims.ClientField__c +
      '=' +
      matter.Id;

    String postDocumentsQuery =
      '/work/api/v2/customers/' +
      customerId +
      '/libraries/' +
      library +
      '/folders/' +
      folderId +
      '/documents';

    Map<String, HttpResponse> responses = new Map<String, HttpResponse>{
      licenseUrl => TestUtils.getMockLicenseResponse(200, orgId),
      'callout:iManageCreds/api' => getMockAuthResponse(
        200,
        'authenticated',
        customerId
      ),
      serchWorkspaceQuery => getMockWorkspaceSearchResponse(
        200,
        'authenticated',
        workspaceId
      ),
      searchFolderQuery => getMockFolderSearchResponse(
        200,
        'authenticated',
        folderId
      ),
      postDocumentsQuery => getMockPostDocumentResponse(
        200,
        'authenticated',
        name,
        extension
      )
    };
    EchoHttpMock.setTestMockResponse(responses);

    Test.startTest();
    iManageFileSaver.SaveFile(data, name, extension, entityId);
    Test.stopTest();
  }

  static testMethod void saveFileToFolderTest() {
    iManageSettings__c ims = iManageSettings__c.getOrgDefaults();

    //Create Matter
    Opportunity matter = new Opportunity(
      StageName = '100',
      Name = '10',
      CloseDate = system.now().addDays(30).date()
    );
    insert matter;

    Blob data = Blob.valueOf('test data');
    String name = 'file name';
    String extension = 'txt';
    String entityId = String.valueOf(matter.Id);

    String workspaceId = 'ws-1';
    String folderId = 'folder-1';
    String folderStructure = folderId;
    Integer customerId = 333;
    String library = folderId = 'ACTIVE';

    Organization org = [SELECT Id FROM Organization];
    String orgId = String.valueOf(org.Id);
    String licenseUrl = LicenseService.baseUrl + '/api/License/organization';

    String searchFolderQuery =
      '/work/api/v2/customers/' +
      String.valueOf(customerId) +
      '/libraries/' +
      library +
      '/folders/search';

    String serchWorkspaceQuery =
      '/work/api/v2/customers/' +
      customerId +
      '/libraries/' +
      library +
      '/workspaces?' +
      ims.MatterField__c +
      '=' +
      matter.Id +
      '&' +
      ims.ClientField__c +
      '=' +
      matter.Id;

    String postDocumentsQuery =
      '/work/api/v2/customers/' +
      customerId +
      '/libraries/' +
      library +
      '/folders/' +
      folderId +
      '/documents';

    Map<String, HttpResponse> responses = new Map<String, HttpResponse>{
      licenseUrl => TestUtils.getMockLicenseResponse(200, orgId),
      'callout:iManageCreds/api' => getMockAuthResponse(
        200,
        'authenticated',
        customerId
      ),
      serchWorkspaceQuery => getMockWorkspaceSearchResponse(
        200,
        'authenticated',
        workspaceId
      ),
      searchFolderQuery => getMockFolderSearchResponse(
        200,
        'authenticated',
        folderId
      ),
      postDocumentsQuery => getMockPostDocumentResponse(
        200,
        'authenticated',
        name,
        extension
      )
    };
    EchoHttpMock.setTestMockResponse(responses);

    String folder = 'TestFolder';
    
    Test.startTest();
    iManageFileSaver.SaveFileToFolder(data, name, extension, entityId, folder);
    Test.stopTest();
  }

  static testMethod void saveFileNullFolderIdExceptionsTest() {
    TestUtils.setupMockActiveLicense();

    iManageSettings__c ims = iManageSettings__c.getOrgDefaults();
    ims.iManage_Default_Folder_Id__c = null;
    update ims;

    //Create Matter
    Opportunity matter = new Opportunity(
      StageName = '100',
      Name = '10',
      CloseDate = system.now().addDays(30).date()
    );
    insert matter;

    Blob data = Blob.valueOf('test data');
    String name = 'file name';
    String extension = 'txt';
    String entityId = String.valueOf(matter.Id);

    Test.startTest();
    try {
      iManageFileSaver.SaveFile(data, name, extension, entityId);
    } catch (Exception ex) {
      System.assert(
        ex instanceof iManageFileSaver.IManageFileSaverException,
        'Wrong exception type'
      );
    }
    Test.stopTest();
  }

  private static HttpResponse getMockAuthResponse(
    Integer statusCode,
    String auth_status,
    Integer customerId
  ) {
    HttpResponse resp = new HttpResponse();
    if (String.isEmpty(auth_status)) {
      auth_status = 'authenticated';
    }
    resp.setStatusCode(statusCode);
    resp.setBody(
      '{"data":{"app":{"id":"894a95b7-e904-429a-a37f-467823927648"},"auth_status":"' +
      auth_status +
      '","capabilities":["app_store","global_users","oauth"],"dms_version":"10.2.2838","user":{"customer_id":' +
      customerId +
      ',"email":"test@gdsi.com","id":"TEST","name":"test","ssid":"386600337554908195","user_type":"enterprise"},"versions":[{"name":"v2","url":"https://cloudimanage.com/work/api/v2","version":"2.1.766"}],"work":{"libraries":[{"alias":"ACTIVE","is_classic_client_compatible":false,"type":"worksite"}],"preferred_library":"ACTIVE"}}}'
    );
    return resp;
  }

  private static HttpResponse getMockFolderSearchResponse(
    Integer statusCode,
    String auth_status,
    String folderId
  ) {
    HttpResponse resp = new HttpResponse();
    if (String.isEmpty(auth_status)) {
      auth_status = 'authenticated';
    }
    resp.setStatusCode(statusCode);
    resp.setBody(
      '{"data":[{"project_custom3":"active_uk|91|522","database":"active_uk","default_security":"inherit","activity_date":"2022-06-13T16:53:48Z","edit_date":"2022-06-13T16:53:48Z","folder_type":"regular","has_documents":true,"has_subfolders":false,"id":"' +
      folderId +
      '","inherited_default_security":"public","is_container_saved_search":false,"is_content_saved_search":false,"is_external_as_normal":false,"name":"Attorney Notes","owner":"ADMINISTRATOR","owner_description":"Administrator","parent_id":"active_uk!522","view_type":"document","wstype":"folder","workspace_id":"ws-01","workspace_name":"ws-01"}]}'
    );
    return resp;
  }

  private static HttpResponse getMockWorkspaceSearchResponse(
    Integer statusCode,
    String auth_status,
    String workspaceId
  ) {
    HttpResponse resp = new HttpResponse();
    if (String.isEmpty(auth_status)) {
      auth_status = 'authenticated';
    }
    resp.setStatusCode(statusCode);
    resp.setBody(
      '{"data":[{"database":"active_uk","default_security":"inherit","edit_date":"2022-06-13T16:53:48Z","has_documents":true,"has_subfolders":false,"id":"' +
      workspaceId +
      '","is_container_saved_search":false,"is_content_saved_search":false,"is_external_as_normal":false,"name":"ws-01","owner":"ADMINISTRATOR","owner_description":"Administrator","wstype":"folder"}]}'
    );
    return resp;
  }

  private static HttpResponse getMockPostDocumentResponse(
    Integer statusCode,
    String auth_status,
    String name,
    String ext
  ) {
    HttpResponse resp = new HttpResponse();
    if (String.isEmpty(auth_status)) {
      auth_status = 'authenticated';
    }
    resp.setStatusCode(statusCode);
    resp.setBody(
      '{"data":{"id":"", "name":"' +
      name +
      '","extension":"' +
      ext +
      '"}}'
    );
    return resp;
  }
}
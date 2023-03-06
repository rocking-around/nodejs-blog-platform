@isTest
private class iManageWrapperTests {
  static testMethod void getApiTest() {
    Organization org = [SELECT Id FROM Organization];
    String orgId = String.valueOf(org.Id);
    String licenseUrl = LicenseService.baseUrl + '/api/License/organization';
    //Setup Mock responses
    Map<String, HttpResponse> responses = new Map<String, HttpResponse>{
      'callout:iManageCreds/api' => iManageWrapperTests.getMockAuthResponse(
        200,
        'authenticated',
        333
      )
    };
    EchoHttpMock.setTestMockResponse(responses);

    Test.startTest();
    iManageProvider.IManageApiDataResponse result = iManageWrapper.GetApi();
    Test.stopTest();

    System.assert(
      result.data.auth_status == 'authenticated',
      'The auth_status has wrong value'
    );
    System.assert(result.data.user.id == 'TEST', 'The user.id has wrong value');
  }

  static testMethod void getApi401Test() {
    Organization org = [SELECT Id FROM Organization];
    String orgId = String.valueOf(org.Id);
    String licenseUrl = LicenseService.baseUrl + '/api/License/organization';

    HttpResponse getApiDataResponse401 = new HttpResponse();
    getApiDataResponse401.setStatusCode(401);
    Map<String, HttpResponse> responses = new Map<String, HttpResponse>{
      'callout:iManageCreds/api' => getApiDataResponse401
    };

    EchoHttpMock.setTestMockResponse(responses);

    try {
      Test.startTest();
      iManageProvider.IManageApiDataResponse result = iManageWrapper.GetApi();
      Test.stopTest();
    } catch (Exception e) {
      System.assert(
        e instanceof IManageExceptions.IManageUnauthorizedException,
        'Unexpected type of Exception'
      );
    }
  }

  static testMethod void getFolderTest() {
    String customerId = 'cust-1';
    String library = 'lib-1';
    String folderId = 'folder-1';
    String query =
      '/work/api/v2/customers/' +
      customerId +
      '/libraries/' +
      library +
      '/folders/' +
      folderId;

    Map<String, HttpResponse> responses = new Map<String, HttpResponse>{
      query => iManageWrapperTests.getMockFolderResponse(
        200,
        'authenticated',
        folderId
      )
    };
    EchoHttpMock.setTestMockResponse(responses);

    Test.startTest();
    iManageWrapper.iManageFolder result = iManageWrapper.GetFolder(
      customerId,
      library,
      folderId
    );
    Test.stopTest();

    System.assert(result.id == folderId, 'The folder id has wrong value');
  }

  static testMethod void postDocumentTest() {
    String customerId = 'cust-1';
    String library = 'lib-1';
    String folderId = 'folder-1';
    String docName = 'Test doc name';
    String docExt = 'txt';
    Blob data = Blob.valueOf('test doc');

    String query =
      '/work/api/v2/customers/' +
      customerId +
      '/libraries/' +
      library +
      '/folders/' +
      folderId +
      '/documents';

    Map<String, HttpResponse> responses = new Map<String, HttpResponse>{
      query => iManageWrapperTests.getMockPostDocumentResponse(
        200,
        'authenticated',
        'test-doc-id',
        docName,
        docExt
      )
    };
    EchoHttpMock.setTestMockResponse(responses);

    Test.startTest();
    iManageWrapper.iManageDocument result = iManageWrapper.PostDocument(
      customerId,
      library,
      folderId,
      docName,
      docExt,
      data
    );
    Test.stopTest();

    System.assert(result.data.name == docName, 'The doc name has wrong value');
    System.assert(
      result.data.extension == docExt,
      'The doc extension has wrong value'
    );
  }

  static testMethod void postFolderToWorkspaceTest() {
    String customerId = 'cust-1';
    String library = 'lib-1';
    String folderId = 'folder-1';
    String workspaceId = 'ws-01';
    String folderName = 'Test folder name';
    String clientField = 'Id';
    String clientId = 'Cl-01';
    String matterField = 'Id';
    String matterId = 'mat-01';

    String query =
      '/work/api/v2/customers/' +
      customerId +
      '/libraries/' +
      library +
      '/workspaces/' +
      workspaceId +
      '/folders';

    Map<String, HttpResponse> responses = new Map<String, HttpResponse>{
      query => iManageWrapperTests.getMockFolderResponse(
        200,
        'authenticated',
        folderId
      )
    };
    EchoHttpMock.setTestMockResponse(responses);

    Test.startTest();
    iManageWrapper.iManageFolderResponse result = iManageWrapper.PostFolderToWorkspace(
      customerId,
      library,
      workspaceId,
      folderName,
      clientField,
      clientId,
      matterField,
      matterId
    );
    Test.stopTest();

    System.assert(result.data.id == folderId, 'The folder id has wrong value');
  }

  static testMethod void postFolderTest() {
    String customerId = 'cust-1';
    String library = 'lib-1';
    String folderId = 'folder-1';
    String workspaceId = 'ws-01';
    String folderName = 'Test folder name';
    String parentId = 'p-01';
    String clientField = 'Id';
    String clientId = 'Cl-01';
    String matterField = 'Id';
    String matterId = 'mat-01';

    String query =
      '/work/api/v2/customers/' +
      customerId +
      '/libraries/' +
      library +
      '/folders/' +
      parentId +
      '/subfolders';

    Map<String, HttpResponse> responses = new Map<String, HttpResponse>{
      query => iManageWrapperTests.getMockFolderResponse(
        200,
        'authenticated',
        folderId
      )
    };
    EchoHttpMock.setTestMockResponse(responses);

    Test.startTest();
    iManageWrapper.iManageFolderResponse result = iManageWrapper.PostFolder(
      customerId,
      library,
      folderName,
      parentId,
      clientField,
      clientId,
      matterField,
      matterId
    );
    Test.stopTest();

    System.assert(result.data.id == folderId, 'The folder id has wrong value');
  }

  static testMethod void searchFolderTest() {
    String customerId = 'cust-1';
    String library = 'lib-1';
    String containerId = 'parent-1';
    String folderName = 'Test folder name';
    String folderId = 'f-01';

    String query =
      '/work/api/v2/customers/' +
      customerId +
      '/libraries/' +
      library +
      '/folders/search';

    Map<String, HttpResponse> responses = new Map<String, HttpResponse>{
      query => iManageWrapperTests.getMockFolderSearchResponse(
        200,
        'authenticated',
        folderId
      )
    };
    EchoHttpMock.setTestMockResponse(responses);

    Test.startTest();
    iManageWrapper.iManageFolderSearch result = iManageWrapper.SearchFolder(
      customerId,
      library,
      containerId,
      folderName
    );
    Test.stopTest();

    System.assert(result.data.size() > 0, 'The search result is empty');

    System.assert(
      result.data.get(0).id == folderId,
      'The folder id has wrong value'
    );
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

  private static HttpResponse getMockFolderResponse(
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
      '{"data":{"project_custom3":"active_uk|91|522","database":"active_uk","default_security":"inherit","activity_date":"2022-06-13T16:53:48Z","edit_date":"2022-06-13T16:53:48Z","folder_type":"regular","has_documents":true,"has_subfolders":false,"id":"' +
      folderId +
      '","inherited_default_security":"public","is_container_saved_search":false,"is_content_saved_search":false,"is_external_as_normal":false,"name":"Attorney Notes","owner":"ADMINISTRATOR","owner_description":"Administrator","parent_id":"active_uk!522","view_type":"document","wstype":"folder","workspace_id":"ws-01","workspace_name":"ws-01"}}'
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

  private static HttpResponse getMockPostDocumentResponse(
    Integer statusCode,
    String auth_status,
    String docId,
    String docName,
    String docExt
  ) {
    HttpResponse resp = new HttpResponse();
    if (String.isEmpty(auth_status)) {
      auth_status = 'authenticated';
    }
    resp.setStatusCode(statusCode);
    resp.setBody(
      '{"data":{"id":"' +
      docId +
      '","name":"' +
      docName +
      '","extension":"' +
      docExt +
      '"}}'
    );
    return resp;
  }
}

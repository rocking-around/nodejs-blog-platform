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

  static testMethod void getApiInfoUsesTransactionCacheTest() {
    Map<String, HttpResponse> responses = new Map<String, HttpResponse>{
      'callout:iManageCreds/api' => iManageWrapperTests.getMockAuthResponse(
        200,
        'authenticated',
        333
      )
    };
    EchoHttpMock.setTestMockResponse(responses);
    iManageWrapper.invalidateApiInfoCache();

    Test.startTest();
    iManageWrapper.ApiInfo first = iManageWrapper.GetApiInfo();
    iManageWrapper.ApiInfo second = iManageWrapper.GetApiInfo();
    Integer callouts = Limits.getCallouts();
    Test.stopTest();

    System.assertEquals(1, callouts, 'ApiInfo should be loaded only once');
    System.assertEquals('333', first.customerId);
    System.assertEquals('ACTIVE', first.library);
    System.assertEquals(first.customerId, second.customerId);
    System.assertEquals(first.library, second.library);
  }

  static testMethod void getApiInfoDoesNotCacheFallbackTest() {
    Map<String, HttpResponse> responses = new Map<String, HttpResponse>{
      'callout:iManageCreds/api' => iManageWrapperTests.getMockAuthResponse(
        200,
        'authenticated',
        null
      )
    };
    EchoHttpMock.setTestMockResponse(responses);
    iManageWrapper.invalidateApiInfoCache();

    Test.startTest();
    iManageWrapper.ApiInfo first = iManageWrapper.GetApiInfo();
    iManageWrapper.ApiInfo second = iManageWrapper.GetApiInfo();
    Integer callouts = Limits.getCallouts();
    Test.stopTest();

    System.assertEquals('0', first.customerId);
    System.assertEquals('0', second.customerId);
    System.assertEquals(2, callouts, 'Fallback ApiInfo should not be cached');
  }

  static testMethod void getApiInfoDoesNotCacheLibraryFallbackTest() {
    HttpResponse apiResponse = iManageWrapperTests.getMockAuthResponse(
      200,
      'authenticated',
      333
    );
    Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(
      apiResponse.getBody()
    );
    Map<String, Object> data = (Map<String, Object>) responseBody.get('data');
    Map<String, Object> work = (Map<String, Object>) data.get('work');
    work.remove('preferred_library');
    apiResponse.setBody(JSON.serialize(responseBody));

    EchoHttpMock.setTestMockResponse(
      new Map<String, HttpResponse>{
        'callout:iManageCreds/api' => apiResponse
      }
    );
    iManageWrapper.invalidateApiInfoCache();

    Test.startTest();
    iManageWrapper.ApiInfo first = iManageWrapper.GetApiInfo();
    iManageWrapper.ApiInfo second = iManageWrapper.GetApiInfo();
    Integer callouts = Limits.getCallouts();
    Test.stopTest();

    System.assertEquals('333', first.customerId);
    System.assertEquals('ACTIVE', first.library);
    System.assertEquals('ACTIVE', second.library);
    System.assertEquals(2, callouts, 'Library fallback should not be cached');
  }

  static testMethod void getApiInfoDoesNotCacheUnauthorizedResponseTest() {
    HttpResponse unauthorizedResponse = new HttpResponse();
    unauthorizedResponse.setStatusCode(401);
    EchoHttpMock.setTestMockResponse(
      new Map<String, HttpResponse>{
        'callout:iManageCreds/api' => unauthorizedResponse
      }
    );
    iManageWrapper.invalidateApiInfoCache();

    Test.startTest();
    for (Integer attempt = 0; attempt < 2; attempt++) {
      try {
        iManageWrapper.GetApiInfo();
        System.assert(false, 'Expected an unauthorized exception');
      } catch (IManageExceptions.IManageUnauthorizedException ex) {
        // Expected.
      }
    }
    Integer callouts = Limits.getCallouts();
    Test.stopTest();

    System.assertEquals(2, callouts, 'Unauthorized responses should not be cached');
  }

  static testMethod void unauthorizedRequestInvalidatesApiInfoCacheTest() {
    String documentQuery =
      '/work/api/v2/customers/333/libraries/ACTIVE/documents/doc-1';
    HttpResponse unauthorizedResponse = new HttpResponse();
    unauthorizedResponse.setStatusCode(401);
    Map<String, HttpResponse> responses = new Map<String, HttpResponse>{
      'callout:iManageCreds/api' => iManageWrapperTests.getMockAuthResponse(
        200,
        'authenticated',
        333
      ),
      documentQuery => unauthorizedResponse
    };
    EchoHttpMock.setTestMockResponse(responses);
    iManageWrapper.invalidateApiInfoCache();

    Test.startTest();
    iManageWrapper.GetApiInfo();
    try {
      iManageWrapper.GetDocument('333', 'ACTIVE', 'doc-1');
      System.assert(false, 'Expected an unauthorized exception');
    } catch (IManageExceptions.IManageUnauthorizedException ex) {
      // Expected.
    }
    iManageWrapper.GetApiInfo();
    Integer callouts = Limits.getCallouts();
    Test.stopTest();

    System.assertEquals(3, callouts, 'A 401 response should clear the ApiInfo cache');
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

    Boolean exceptionThrown = false;
    Test.startTest();
    try {
      iManageWrapper.GetApi();
    } catch (IManageExceptions.IManageUnauthorizedException ex) {
      exceptionThrown = true;
    }
    Test.stopTest();

    System.assert(exceptionThrown, 'Expected an unauthorized exception');
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

  //iManageWorkspaceOnPremiseSearchResults
  @isTest
  static void iManageWorkspaceOnPremiseSearch_error_response_test() {
    String responseBody = '{"error":{"code":"NRC_INVALID_PARAM","code_message":"Parameter is invalid","messages":[{"audit":{"activity":"checkin","activity_code":600,"activity_date":"2017-09-01T22:15:07Z","application_name":"WINWORD","comments":"New Activity","duration":0,"location":"192.168.0.1","user":"ACASE"},"field":"limit","code":"NRC_INVALID_PARAM","code_message":"invalid format"}]}}';
    
    Test.startTest();
    iManageWrapper.iManageWorkspaceOnPremiseSearch onPremResult = (iManageWrapper.iManageWorkspaceOnPremiseSearch) JSON.deserialize(
        responseBody,
        iManageWrapper.iManageWorkspaceOnPremiseSearch.class
      );
    Test.stopTest();
    System.assert(
      onPremResult.error.code == 'NRC_INVALID_PARAM',
      'Wrong value = ' + onPremResult.error.code + ', expected = ' + 'NRC_INVALID_PARAM'
    );
    System.assert(
      onPremResult.error.code_message == 'Parameter is invalid',
      'Wrong value = ' + onPremResult.error.code_message + ', expected = ' + 'Parameter is invalid'
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

@isTest
private class iManageFileWorkerTests {
  static testMethod void getApiDataTest() {
    //Setup Mock responses
    Map<String, HttpResponse> responses = new Map<String, HttpResponse>{
      'callout:iManageCreds/api' => iManageFileWorkerTests.getMockAuthResponse(
        200,
        'authenticated',
        333
      )
    };
    EchoHttpMock.setTestMockResponse(responses);

    Test.startTest();
    iManageProvider.IManageApiDataResponse result = iManageFileWorker.GetApiData();
    Test.stopTest();

    System.assert(
      result.data.auth_status == 'authenticated',
      'The auth_status has wrong value'
    );
    System.assert(result.data.user.id == 'TEST', 'The user.id has wrong value');
  }

  static testMethod void getApiData401Test() {
    HttpResponse getApiDataResponse401 = new HttpResponse();
    getApiDataResponse401.setStatusCode(401);
    Map<String, HttpResponse> responses = new Map<String, HttpResponse>{
      'callout:iManageCreds/api' => getApiDataResponse401
    };
    EchoHttpMock.setTestMockResponse(responses);

    try {
      Test.startTest();
      iManageProvider.IManageApiDataResponse result = iManageFileWorker.GetApiData();
      Test.stopTest();
    } catch (Exception e) {
      System.assert(
        e instanceof IManageExceptions.IManageUnauthorizedException,
        'Unexpected type of Exception'
      );
    }
  }

  static testMethod void SaveFileFromIManageTest() {
    //insert parent Object
    Opportunity opp = new Opportunity(
      Name = 'Test Opportunity',
      Closedate = System.today(),
      StageName = 'Prospecting'
    );
    insert opp;

    String recordId = opp.Id;
    String docId = 'test-doc-id-1';
    String docName = 'test';
    String docExtension = 'txt';
    Integer customerId = 333;
    String library = 'ACTIVE';
    String docContent = 'Test content';

    //Setup Mock responses
    String downloadDocEndpoint =
      'callout:iManageCreds/api/v2/customers/' +
      customerId +
      '/libraries/' +
      library +
      '/documents/' +
      docId +
      '/download';

    Map<String, HttpResponse> responses = new Map<String, HttpResponse>{
      'callout:iManageCreds/api' => iManageFileWorkerTests.getMockAuthResponse(
        200,
        'authenticated',
        customerId
      ),
      downloadDocEndpoint => iManageFileWorkerTests.getMockDownloadDocResponse(
        200,
        docContent
      )
    };
    EchoHttpMock.setTestMockResponse(responses);

    Test.startTest();
    iManageFileWorker.SaveFileFromIManage(
      recordId,
      docId,
      docName,
      docExtension
    );

    List<SObject> files = IManageLinksAndFilesHelper.getFiles(opp.Id, 100, 0);

    Test.stopTest();

    System.assert(files.size() > 0, 'File was not saved');
    SObject file = files.get(0);
    String fileTitle = (String) file.getSObject('ContentDocument').get('Title');
    String fileExtension = (String) file.getSObject('ContentDocument')
      .get('FileExtension');
    System.assertEquals(
      fileTitle,
      docName,
      'Title has wrong value = ' +
      fileTitle +
      ', Expexted = ' +
      docName
    );
    System.assertEquals(
      fileExtension,
      docExtension,
      'Extension has wrong value = ' +
      fileExtension +
      ', Expexted = ' +
      docExtension
    );
  }

  static testMethod void SaveLinkToSalesforceTest() {
    // Insert Custom Settings
    iManageSettings__c mcSetting = new iManageSettings__c();
    mcSetting.Client_Id__c = 'https://cloudimanage.com';
    mcSetting.Url__c = '894a95b7-e904-429a-a37f-467823927648';
    mcSetting.Mapping_EntityType__c = 'Opportunity';
    mcSetting.Mapping_EntityMatterIdObjectField__c = 'Opportunity';
    mcSetting.Mapping_MatterIdField__c = 'Id';
    mcSetting.Mapping_MatterNameField__c = 'Name';
    mcSetting.Mapping_EntityClientIdObjectField__c = 'AccountId';
    mcSetting.Mapping_ClientIdField__c = 'Id';
    mcSetting.Mapping_ClientNameField__c = 'Name';
    insert mcSetting;

    //insert parent Object
    Opportunity opp = new Opportunity(
      Name = 'Test Opportunity',
      Closedate = System.today(),
      StageName = 'Prospecting'
    );
    insert opp;

    //Setup Mock responses
    String recordId = opp.Id;
    String docId = 'test-doc-id-3';
    String docName = 'test3';
    String docExtension = 'txt';
    Integer customerId = 333;
    String library = 'ACTIVE';
    String docContent = 'Test content 333';

    String docInfoEndpoint =
      'callout:iManageCreds/api/v2/customers/' +
      customerId +
      '/libraries/' +
      library +
      '/documents/' +
      docId;

    String downloadDocEndpoint =
      'callout:iManageCreds/api/v2/customers/' +
      customerId +
      '/libraries/' +
      library +
      '/documents/' +
      docId +
      '/download';

    system.debug('dock Info endpoint: ' + docInfoEndpoint);
    system.debug('dock Download endpoint: ' + downloadDocEndpoint);

    Map<String, HttpResponse> responses = new Map<String, HttpResponse>{
      'callout:iManageCreds/api' => iManageFileWorkerTests.getMockAuthResponse(
        200,
        'authenticated',
        333
      ),
      docInfoEndpoint => iManageFileWorkerTests.getMockDocInfoResponse(
        200,
        docName,
        docExtension
      ),
      downloadDocEndpoint => iManageFileWorkerTests.getMockDownloadDocResponse(
        200,
        docContent
      )
    };
    EchoHttpMock.setTestMockResponse(responses);

    //Insert Link
    IManage_File_Link__c link = new IManage_File_Link__c(
      ParentId__c = opp.id,
      Version__c = '1',
      File_Link__c = docInfoEndpoint
    );
    insert link;

    Test.startTest();
    iManageFileWorker.SaveLinkToSalesforce(link.Id);

    Integer linksCount = [
      SELECT COUNT()
      FROM IManage_File_Link__c
      WHERE Id = :link.Id
    ];

    List<SObject> files = IManageLinksAndFilesHelper.getFiles(opp.Id, 100, 0);

    Test.stopTest();

    System.assert(linksCount == 0, 'The link was not deleted');

    System.assert(files.size() > 0, 'No files were added');

    SObject file = files.get(0);
    String fileTitle = (String) file.getSObject('ContentDocument').get('Title');
    String fileExtension = (String) file.getSObject('ContentDocument')
      .get('FileExtension');
    System.assertEquals(
      fileTitle,
      docName,
      'Title has wrong value = ' +
      fileTitle +
      ', Expexted = ' +
      docName
    );
    System.assertEquals(
      fileExtension,
      docExtension,
      'Extension has wrong value = ' +
      fileExtension +
      ', Expexted = ' +
      docExtension
    );
  }

  static testMethod void SaveLinkFromIManageTest() {
    // Insert Custom Settings
    iManageSettings__c mcSetting = new iManageSettings__c();
    mcSetting.Client_Id__c = 'https://cloudimanage.com';
    mcSetting.Url__c = 'http://894a95b7-e904-429a-a37f-467823927648';
    mcSetting.Mapping_EntityType__c = 'Opportunity';
    mcSetting.Mapping_EntityMatterIdObjectField__c = 'Opportunity';
    mcSetting.Mapping_MatterIdField__c = 'Id';
    mcSetting.Mapping_MatterNameField__c = 'Name';
    mcSetting.Mapping_EntityClientIdObjectField__c = 'AccountId';
    mcSetting.Mapping_ClientIdField__c = 'Id';
    mcSetting.Mapping_ClientNameField__c = 'Name';
    insert mcSetting;

    //insert parent Object
    Opportunity opp = new Opportunity(
      Name = 'Test Opportunity',
      Closedate = System.today(),
      StageName = 'Prospecting'
    );
    insert opp;

    String recordId = opp.Id;
    String docId = 'test-doc-01';
    String version = '5';
    String expectedFileLinkUrl =
      mcSetting.Url__c +
      '/work/web/dialogs/link/d/' +
      docId;

    Test.startTest();
    iManageFileWorker.SaveLinkFromIManage(recordId, docId, version);

    List<IManage_File_Link__c> links = IManageLinksAndFilesHelper.getLinks(
      recordId,
      100,
      0
    );
    Test.stopTest();

    System.assert(links.size() > 0, 'The list is empty');
    IManage_File_Link__c link = links.get(0);
    System.assertEquals(
      link.ParentId__c,
      recordId,
      'ParentId__c has wrong value'
    );
    System.assertEquals(
      link.File_Link__c,
      expectedFileLinkUrl,
      'File_Link__c has wrong value'
    );
    System.assertEquals(
      link.Version__c,
      version,
      'File_Link__c has wrong value'
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

  private static HttpResponse getMockDownloadDocResponse(
    Integer statusCode,
    String body
  ) {
    HttpResponse resp = new HttpResponse();
    resp.setStatusCode(statusCode);
    resp.setBody(body);
    return resp;
  }

  private static HttpResponse getMockDocInfoResponse(
    Integer statusCode,
    String name,
    String extension
  ) {
    HttpResponse resp = new HttpResponse();
    resp.setStatusCode(statusCode);
    resp.setBody(
      '{"data": {"name": "' +
      name +
      '", "extension": "' +
      extension +
      '"}}'
    );
    system.debug('getMockDocInfoResponse: ' + resp.getBody());
    return resp;
  }
}

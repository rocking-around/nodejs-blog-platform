@isTest
private class iManageIFrameDialogTests {
  @testSetup
  public static void setup() {
    // Insert Custom Settings
    iManageSettings__c mcSetting = new iManageSettings__c();
    mcSetting.Client_Id__c = 'https://cloudimanage.com';
    mcSetting.Url__c = '894a95b7-e904-429a-a37f-467823927648';
    mcSetting.Mapping_EntityType__c = 'Opportunity';
    mcSetting.Mapping_EntityMatterIdObjectField__c = 'Opportunity';
    mcSetting.Mapping_MatterIdField__c = 'Id';
    mcSetting.Mapping_MatterNameField__c = 'Name';
    mcSetting.Mapping_EntityClientIdObjectField__c = 'Opportunity';
    mcSetting.Mapping_ClientIdField__c = 'Id';
    mcSetting.Mapping_ClientNameField__c = 'Name';
    insert mcSetting;
  }

  @isTest //(SeeAllData=true)
  static void getIFrameFolderTest() {
    //Create Matter
    Opportunity matter = new Opportunity(
      StageName = '100',
      Name = '10',
      CloseDate = system.now().addDays(30).date()
    );
    insert matter;

    HttpResponse getApiDataResponse = new HttpResponse();
    getApiDataResponse.setStatusCode(200);
    getApiDataResponse.setBody(
      '{"data":{"app":{"id":"894a95b7-e904-429a-a37f-467823927648"},"auth_status":"authenticated","capabilities":["app_store","global_users","oauth"],"dms_version":"10.2.2838","user":{"customer_id":337,"email":"test@gdsi.com","id":"TEST","name":"test","ssid":"386600337554908195","user_type":"enterprise"},"versions":[{"name":"v2","url":"https://cloudimanage.com/work/api/v2","version":"2.1.766"}],"work":{"libraries":[{"alias":"Active","is_classic_client_compatible":false,"type":"worksite"}],"preferred_library":"Active"}}}'
    );

    String dialogToken = 'f42516d6-acca-4629-a8d3-be63776094ad';
    HttpResponse getDialogTokenResponse = new HttpResponse();
    getDialogTokenResponse.setStatusCode(200);
    getDialogTokenResponse.setBody(
      '{"data": {"dialog_token":"' +
      dialogToken +
      '"}}'
    );

    String folderId = 'Active!917';
    HttpResponse searchFolderIdResponse = new HttpResponse();
    searchFolderIdResponse.setStatusCode(200);
    searchFolderIdResponse.setBody(
      '{"data":{ "results": [{"id":"' +
      folderId +
      '","wstype":"workspace"}]}}'
    );

    Organization org = [SELECT Id FROM Organization];
    String orgId = String.valueOf(org.Id);
    String licenseUrl = LicenseService.baseUrl + '/api/License/organization';

    String wsSearchUrl =
      'callout:iManageCreds/work/api/v2/customers/337/libraries/Active/workspaces?custom1=' +
      matter.Id +
      '&custom2=' +
      matter.Id;
    System.debug('*** wsSearchUrl: ' + wsSearchUrl);
    Map<String, HttpResponse> responses = new Map<String, HttpResponse>{
      'callout:iManageCreds/work/api/v2/customers/337/dialog-tokens' => getDialogTokenResponse,
      wsSearchUrl => searchFolderIdResponse,
      'callout:iManageCreds/api' => getApiDataResponse,
      licenseUrl => TestUtils.getMockLicenseResponse(200, orgId)
    };
    EchoHttpMock.setTestMockResponse(responses);

    Test.startTest();

    String result = iManageIFrameDialog.GetIFrameFolder(matter.Id);
    iManageSettings__c mc = iManageSettings__c.getOrgDefaults();
    String expectedResult =
      mc.Url__c +
      '/work/partner-apps/' +
      EncodingUtil.urlEncode(mc.Client_Id__c, 'UTF-8') +
      '/dialogs/file-picker/?protocol=postmessage&dialogToken=' +
      EncodingUtil.urlEncode(dialogToken, 'UTF-8') +
      '&mode=emm&multiselect=false&start=' +
      EncodingUtil.urlEncode(folderId, 'UTF-8');

    Test.stopTest();

    System.assert(
      result == expectedResult,
      'The iFrame folder has wrong value'
    );
  }

  /*static testMethod void getIFrameFolderMappingNotExistsTest() {
    // Create Account
    Account acc = new Account(Name = 'Donald Duck');
    insert acc;

    //Create Matter
    Opportunity matter = new Opportunity(
      AccountId = acc.Id,
      StageName = '100',
      Name = '10',
      CloseDate = system.now().addDays(30).date()
    );
    insert matter;

    Test.startTest();
    IManageBaseResponse result = iManageIFrameDialog.GetIFrameFolder(matter.Id);
    Test.stopTest();
    System.assert(
      result.Error.Code == IManageBaseHelper.IManageErrors.EMPTY_CLIENT_OR_MATTER.name(),
      'Error code has wrong value'
    );
  }*/

  static testMethod void getIFrameFilePickerTest() {
    iManageSettings__c mc = iManageSettings__c.getOrgDefaults();

    // Mock responses
    Integer customerId = 333;
    List<HttpResponse> authResponses = new List<HttpResponse>();
    authResponses.add(
      iManageIFrameDialogTests.getMockAuthResponse(
        200,
        'not-authenticated',
        customerId
      )
    );
    authResponses.add(
      iManageIFrameDialogTests.getMockAuthResponse(200, 'authenticated', 333)
    );

    String dialogToken = 'f42516d6-acca-4629-a8d3-be63776094ad';
    List<HttpResponse> dialogTokenResponses = new List<HttpResponse>();
    HttpResponse dialogTokenResponse = new HttpResponse();
    dialogTokenResponse.setStatusCode(200);
    dialogTokenResponse.setBody(
      '{"data":{"dialog_token":"' +
      dialogToken +
      '"}}'
    );
    dialogTokenResponses.add(dialogTokenResponse);

    List<HttpResponse> dialogTokenResponses2 = new List<HttpResponse>{
      dialogTokenResponse
    };

    Organization org = [SELECT Id FROM Organization];
    String orgId = String.valueOf(org.Id);
    String licenseUrl = LicenseService.baseUrl + '/api/License/organization';

    Map<String, List<HttpResponse>> responses = new Map<String, List<HttpResponse>>{
      'callout:iManageCreds/api' => authResponses,
      'callout:iManageCreds/work/api/v2/customers/0/dialog-tokens' => dialogTokenResponses,
      'callout:iManageCreds/work/api/v2/customers/' +
      customerId +
      '/dialog-tokens' => dialogTokenResponses2,
      licenseUrl => new List<HttpResponse>{
        TestUtils.getMockLicenseResponse(200, orgId),
        TestUtils.getMockLicenseResponse(200, orgId),
        TestUtils.getMockLicenseResponse(200, orgId)
      }
    };
    HttpCalloutQueueMock.setTestMockResponse(responses);

    Test.startTest();
    String result = iManageIFrameDialog.GetIFrameFilePicker();
    Test.stopTest();
    String expectedResult =
      mc.Url__c +
      '/work/partner-apps/' +
      mc.Client_Id__c +
      '/dialogs/file-picker/?protocol=postmessage&dialogToken=' +
      EncodingUtil.urlEncode(dialogToken, 'UTF-8') +
      '&mode=open';
    System.assert(
      result == expectedResult,
      'The IFrame FilePicker has wrong value'
    );
  }

  static testMethod void getIFrameFilePicker401Test() {
    Organization org = [SELECT Id FROM Organization];
    String orgId = String.valueOf(org.Id);
    String licenseUrl = LicenseService.baseUrl + '/api/License/organization';

    HttpResponse getApiDataResponse401 = new HttpResponse();
    getApiDataResponse401.setStatusCode(401);
    Map<String, HttpResponse> responses = new Map<String, HttpResponse>{
      'callout:iManageCreds/api' => getApiDataResponse401,
      licenseUrl => TestUtils.getMockLicenseResponse(200, orgId)
    };
    EchoHttpMock.setTestMockResponse(responses);

    Test.startTest();
    try {
      String result = iManageIFrameDialog.GetIFrameFilePicker();
    } catch (AuraHandledException ex) {
      System.assert(
        ex.getMessage() ==
        System.Label.imanage_message_codes_empty_custom_resource,
        'Error code has wrong value'
      );
    }
    Test.stopTest();
  }

  static testMethod void getIFrameFolderPickerTest() {
    iManageSettings__c mc = iManageSettings__c.getOrgDefaults();

    // Mock responses
    Integer customerId = 333;
    List<HttpResponse> authResponses = new List<HttpResponse>();
    authResponses.add(
      iManageIFrameDialogTests.getMockAuthResponse(
        200,
        'not-authenticated',
        customerId
      )
    );
    authResponses.add(
      iManageIFrameDialogTests.getMockAuthResponse(200, 'authenticated', 333)
    );

    String dialogToken = 'f42516d6-acca-4629-a8d3-be63776094ad';
    List<HttpResponse> dialogTokenResponses = new List<HttpResponse>();
    HttpResponse dialogTokenResponse = new HttpResponse();
    dialogTokenResponse.setStatusCode(200);
    dialogTokenResponse.setBody(
      '{"data":{"dialog_token":"' +
      dialogToken +
      '"}}'
    );
    dialogTokenResponses.add(dialogTokenResponse);

    List<HttpResponse> dialogTokenResponses2 = new List<HttpResponse>{
      dialogTokenResponse
    };

    Organization org = [SELECT Id FROM Organization];
    String orgId = String.valueOf(org.Id);
    String licenseUrl = LicenseService.baseUrl + '/api/License/organization';

    Map<String, List<HttpResponse>> responses = new Map<String, List<HttpResponse>>{
      'callout:iManageCreds/api' => authResponses,
      'callout:iManageCreds/work/api/v2/customers/0/dialog-tokens' => dialogTokenResponses,
      'callout:iManageCreds/work/api/v2/customers/' +
      customerId +
      '/dialog-tokens' => dialogTokenResponses2,
      licenseUrl => new List<HttpResponse>{
        TestUtils.getMockLicenseResponse(200, orgId),
        TestUtils.getMockLicenseResponse(200, orgId),
        TestUtils.getMockLicenseResponse(200, orgId)
      }
    };
    HttpCalloutQueueMock.setTestMockResponse(responses);

    Test.startTest();
    String result = iManageIFrameDialog.GetIFrameFolderPicker();
    Test.stopTest();

    String expectedResult =
      mc.Url__c +
      '/work/partner-apps/' +
      mc.Client_Id__c +
      '/dialogs/file-picker/?protocol=postmessage&dialogToken=' +
      EncodingUtil.urlEncode(dialogToken, 'UTF-8') +
      '&mode=browse&multiselect=false&types=folder';
    System.assert(
      result == expectedResult,
      'The IFrame FolderPicker has wrong value'
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
}

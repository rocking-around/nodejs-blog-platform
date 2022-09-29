@isTest
private class iManageIFrameDialogTests {
  @testSetup
  public static void setup() {
    // Insert Custom Settings
    iManageSettings__c mcSetting = new iManageSettings__c();
    mcSetting.Client_Id__c = 'https://cloudimanage.com';
    mcSetting.Url__c = '894a95b7-e904-429a-a37f-467823927648';
    insert mcSetting;
  }

  @isTest //(SeeAllData=true)
  static void getIFrameFolderTest() {
    HttpResponse getApiDataResponse = new HttpResponse();
    getApiDataResponse.setStatusCode(200);
    getApiDataResponse.setBody(
      '{"data":{"app":{"id":"894a95b7-e904-429a-a37f-467823927648"},"auth_status":"authenticated","capabilities":["app_store","global_users","oauth"],"dms_version":"10.2.2838","user":{"customer_id":337,"email":"test@gdsi.com","id":"TEST","name":"test","ssid":"386600337554908195","user_type":"enterprise"},"versions":[{"name":"v2","url":"https://cloudimanage.com/work/api/v2","version":"2.1.766"}],"work":{"libraries":[{"alias":"Active","is_classic_client_compatible":false,"type":"worksite"}],"preferred_library":"Active"}}}'
    );

    String dialogToken = 'f42516d6-acca-4629-a8d3-be63776094ad';
    HttpResponse getDialogTokenResponse = new HttpResponse();
    getDialogTokenResponse.setStatusCode(200);
    getDialogTokenResponse.setBody(
      '{"data":{"dialog_token":"' +
      dialogToken +
      '"}}'
    );

    String folderId = 'Active!917';
    HttpResponse searchFolderIdResponse = new HttpResponse();
    searchFolderIdResponse.setStatusCode(200);
    searchFolderIdResponse.setBody(
      '{"data":[{"id":"' +
      folderId +
      '","wstype":"workspace"}],"overflow":false}'
    );

    Map<String, HttpResponse> responses = new Map<String, HttpResponse>{
      '/dialog-tokens' => getDialogTokenResponse,
      '/workspaces/search' => searchFolderIdResponse,
      'callout:iManageCreds/api' => getApiDataResponse
    };
    EchoHttpMock.setTestMockResponse(responses);

    Test.startTest();

    String matterId = '0001';
    String clientId = '0001-11';
    String result = iManageIFrameDialog.GetIFrameFolder(clientId, matterId);
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
}

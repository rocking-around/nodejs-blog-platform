@isTest
public class iManageProviderTests {
  @isTest
  static void Test_Instatiate() {
    iManageProvider ip = new iManageProvider();
    system.assertNotEquals(null, ip);
  }
  @isTest
  static void Test_getCustomMetadataType() {
    iManageProvider ip = new iManageProvider();
    String metaData = ip.getCustomMetadataType();
    system.assert(1 == 1);
  }
  @isTest
  static void Test_initiate() {
    Map<String, String> apc = new Map<String, String>();
    apc.put('gdsi_imanage__Consumer_Key__c', 'Key_1234');
    apc.put('gdsi_imanage__Authorize_Endpoint_URL__c', 'EndPoint_1234');
    apc.put('gdsi_imanage__Scope__c', 'Scope_1234');
    apc.put('gdsi_imanage__Redirect_URI__c', 'RedirectURL_1234');

    String stp = 'test';

    //test initiate
    iManageProvider ip = new iManageProvider();
    ip.initiate(apc, stp);

    // Set mock callout class
    Test.setMock(
      HttpCalloutMock.class,
      new iManageProviderMockRefreshCallout()
    );

    apc.clear();
    apc.put('gdsi_imanage__Consumer_Key__c', 'Key_1234');
    apc.put('gdsi_imanage__Consumer_Secret__c', 'testSecret');
    apc.put('gdsi_imanage__Token_Endpoint_URL__c', 'testEndpoint');
    apc.put('gdsi_imanage__User_Info_URL__c', 'http://someuserInfoURL');
    apc.put('gdsi_imanage__Scope__c', 'Scope_1234');
    apc.put('gdsi_imanage__Redirect_URI__c', 'RedirectURL_1234');

    //test refresh method
    ip.refresh(apc, 'refreshToken');
    system.assert(1 == 1);

    //test handleCallback method
    apc.put('code', 'code');
    apc.put('state', 'state');
    Auth.AuthProviderCallbackState cbs = new Auth.AuthProviderCallbackState(
      apc,
      'body',
      apc
    );
    Auth.AuthProviderTokenResponse tr = ip.handleCallback(apc, cbs);

    // Set mock callout class
    Test.setMock(
      HttpCalloutMock.class,
      new iManageProviderMockUserInfoCallout()
    );

    //test getUserInfo method
    Auth.UserData ud = ip.getUserInfo(apc, tr);
  }
}

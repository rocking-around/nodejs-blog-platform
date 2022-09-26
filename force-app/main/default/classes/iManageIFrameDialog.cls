public class iManageIFrameDialog {
  private static iManageProvider.IManageApiDataResponse GetApiData() {
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:iManageCreds/api');
    req.setHeader('content-type', 'application/json');
    req.setHeader('X-Auth-Token', '{!$Credential.AuthorizationHeaderValue}');
    req.setMethod('GET');

    Http http = new Http();
    HTTPResponse res = http.send(req);
    String responseBody = res.getBody();
    system.debug(responseBody);

    return (iManageProvider.IManageApiDataResponse) JSON.deserialize(
      responseBody,
      iManageProvider.IManageApiDataResponse.class
    );
  }

  private static DialogTokenResult GetDialogToken(
    iManageProvider.IManageApiDataResponse apiData
  ) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint(
      'callout:iManageCreds/api/v2/customers/' +
      apiData.data.user.customer_id +
      '/dialog-tokens'
    );
    req.setHeader('content-type', 'application/json');
    req.setHeader('X-Auth-Token', '{!$Credential.AuthorizationHeaderValue}');
    req.setMethod('POST');

    Http http = new Http();
    HTTPResponse res = http.send(req);
    String responseBody = res.getBody();
    return (DialogTokenResult) JSON.deserialize(
      responseBody,
      DialogTokenResult.class
    );
  }

  /*@AuraEnabled
    public static String GetIFrameImange() {
        DialogTokenResult result = GetDialogToken();
        iManageSettings__c mc = iManageSettings__c.getOrgDefaults();
        return mc.Url__c + '/' + mc.Client_Id__c + '/dialogs/file-picker/?protocol=postmessage&dialogToken=' + EncodingUtil.urlEncode(result.data.dialog_token,'UTF-8') + '&mode=open&type=WORD,WORDX';
    }*/

  @AuraEnabled
  public static String GetIFrameFolder(String id) {
    iManageProvider.IManageApiDataResponse apiData = GetApiData();
    system.debug(apiData);
    DialogTokenResult result = GetDialogToken(apiData);
    iManageSettings__c mc = iManageSettings__c.getOrgDefaults();
    return mc.Url__c +
      '/work/partner-apps/' +
      EncodingUtil.urlEncode(mc.Client_Id__c, 'UTF-8') +
      '/dialogs/file-picker/?protocol=postmessage&dialogToken=' +
      EncodingUtil.urlEncode(result.data.dialog_token, 'UTF-8') +
      '&mode=emm&multiselect=false&start=' +
      EncodingUtil.urlEncode(apiData.data.work.preferred_library, 'UTF-8') +
      '!' +
      EncodingUtil.urlEncode(id, 'UTF-8');

    //return 'https://cloudimanage.com/work/partner-apps/894a95b7-e904-429a-a37f-467823927648/dialogs/file-picker/?protocol=postmessage&dialogToken=74bf477e-c35b-4210-9b32-9f11989a251f&mode=browse&multiselect=false&start=Active!446';
  }

  public class DialogTokenResult {
    public DialogTokenData data;
  }

  public class DialogTokenData {
    public String dialog_token;
  }
}

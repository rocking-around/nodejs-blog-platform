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

  public static DialogTokenResult GetDialogToken(
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

  private static SearchResult SearchFolderId(
    String clientId,
    String matterId,
    iManageProvider.IManageApiDataResponse apiData,
    iManageSettings__c mc
  ) {
    //iManageProvider.IManageApiDataResponse apiData = GetApiData();
    HttpRequest req = new HttpRequest();
    req.setEndpoint(
      'callout:iManageCreds/work/api/v2/customers/' +
      apiData.data.user.customer_id +
      '/workspaces/search'
    );
    req.setHeader('content-type', 'application/json');
    req.setHeader('X-Auth-Token', '{!$Credential.AuthorizationHeaderValue}');
    req.setMethod('POST');
    String body =
      '{"limit": 1, "profile_fields": { "folder": [ "name" ] }, ' +
      '"filters": { "libraries": "' +
      apiData.data.work.preferred_library +
      '", ' +
      '"' +
      mc.ClientField__c +
      '": "' +
      clientId +
      '", "' +
      mc.MatterField__c +
      '": "' +
      matterId +
      '" }}';
    System.debug(body);
    req.setBody(body);
    Http http = new Http();
    HTTPResponse res = http.send(req);
    String responseBody = res.getBody();
    system.debug(responseBody);
    return (SearchResult) JSON.deserialize(responseBody, SearchResult.class);
  }

  @AuraEnabled
  public static String GetIFrameFolder(String entityId) {
    //IManageLink__c link = [SELECT ClientId__c, MatterId__c FROM IManageLink__c WHERE EntityId__c = :entityId];
    IManageMappingHelper.IManageIFrameData link = IManageMappingHelper.getMappingData(
      entityId
    );
    iManageProvider.IManageApiDataResponse apiData = GetApiData();
    DialogTokenResult result = GetDialogToken(apiData);
    iManageSettings__c mc = iManageSettings__c.getOrgDefaults();
    SearchResult searchResult = SearchFolderId(
      link.ClientId,
      link.MatterId,
      apiData,
      mc
    );
    return mc.Url__c +
      '/work/partner-apps/' +
      EncodingUtil.urlEncode(mc.Client_Id__c, 'UTF-8') +
      '/dialogs/file-picker/?protocol=postmessage&dialogToken=' +
      EncodingUtil.urlEncode(result.data.dialog_token, 'UTF-8') +
      '&mode=emm&multiselect=false&start=' +
      EncodingUtil.urlEncode(searchResult.data[0].id, 'UTF-8');
  }

  public class DialogTokenResult {
    public DialogTokenData data;
  }

  public class DialogTokenData {
    public String dialog_token;
  }

  public class SearchResult {
    public List<SearchData> data;
  }

  public class SearchData {
    public String id;
    public String wstype;
  }
}

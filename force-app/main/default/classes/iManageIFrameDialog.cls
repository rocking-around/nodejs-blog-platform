public class iManageIFrameDialog {
  private static iManageProvider.IManageApiDataResponse GetApiData() {
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:iManageCreds/api');
    req.setHeader('content-type', 'application/json');
    req.setHeader('X-Auth-Token', '{!$Credential.AuthorizationHeaderValue}');
    req.setMethod('GET');

    Http http = new Http();
    HTTPResponse res = http.send(req);
    if(res.getStatusCode() == 401)
      throw new IManageExceptions.IManageUnauthorizedException();
    String responseBody = res.getBody();

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
    if(res.getStatusCode() == 401)
      throw new IManageExceptions.IManageUnauthorizedException();
      
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
      
    req.setBody(body);

    Http http = new Http();
    HTTPResponse res = http.send(req);
    if(res.getStatusCode() == 401)
      throw new IManageExceptions.IManageUnauthorizedException();

    String responseBody = res.getBody();
    return (SearchResult) JSON.deserialize(responseBody, SearchResult.class);
  }

  @AuraEnabled
  public static IManageBaseResponse GetIFrameFolder(String entityId) {
    IManageMappingHelper.IManageIFrameData link = IManageMappingHelper.getMappingData(entityId);
    if(link.ClientId == null || link.MatterId == null)
      return IManageBaseResponse.BuildError(
        IManageBaseHelper.IManageErrors.EMPTY_CLIENT_OR_MATTER.name(),
        'Matters and Parties should contains mapping data for the iManage Client and iManage Matter fields.'
      );
    try {
      iManageProvider.IManageApiDataResponse apiData = GetApiData();
      DialogTokenResult dialogTokenResult = GetDialogToken(apiData);
      iManageSettings__c mc = iManageSettings__c.getOrgDefaults();
      
      if(mc == null)
        return IManageBaseResponse.BuildError(
          IManageBaseHelper.IManageErrors.EMPTY_CUSTOM_RESOURCE.name(),
          'Missed required Custom Settings: iManageSettings.'
        );

      SearchResult searchResult = SearchFolderId(
        link.ClientId,
        link.MatterId,
        apiData,
        mc
      );

      String dialogUrl = mc.Url__c +
      '/work/partner-apps/' +
      EncodingUtil.urlEncode(mc.Client_Id__c, 'UTF-8') +
      '/dialogs/file-picker/?protocol=postmessage&dialogToken=' +
      EncodingUtil.urlEncode(dialogTokenResult.data.dialog_token, 'UTF-8') +
      '&mode=emm&multiselect=false';

      if(searchResult == null || searchResult.data == null ||
          searchResult.data.size() == 0 || searchResult.data[0].id == null) {
          IManageBaseResponse result = IManageBaseResponse.BuildError(
            IManageBaseHelper.IManageErrors.FOLDER_NOT_FOUND.name(),
            'The system haven\'t access to the iManage. Please check Named Credentials or contact with Administrator.'
          );
          result.Data = dialogUrl;
      }

      IManageBaseResponse result = new IManageBaseResponse();
      result.Data = dialogUrl + '&start=' + EncodingUtil.urlEncode(searchResult.data[0].id, 'UTF-8');

      return result;
    }
    catch(IManageExceptions.IManageUnauthorizedException ex) {
      return IManageBaseResponse.BuildError(
        IManageBaseHelper.IManageErrors.UNAUTHORIZED.name(),
        'The system haven\'t access to the iManage. Please check Named Credentials or contact with Administrator.'
      );
    }
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
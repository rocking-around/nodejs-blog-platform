public class iManageIFrameDialog {
  private static void FakeCallForRefreshToken() {
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:iManageCreds/api/v2/customers/0/dialog-tokens');
    req.setHeader('content-type', 'application/json');
    req.setHeader('X-Auth-Token', '{!$Credential.AuthorizationHeaderValue}');
    req.setMethod('POST');

    Http http = new Http();
    HTTPResponse res = http.send(req);
  }

  private static iManageProvider.IManageApiDataResponse GetApiData() {
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:iManageCreds/api');
    req.setHeader('content-type', 'application/json');
    req.setHeader('X-Auth-Token', '{!$Credential.AuthorizationHeaderValue}');
    req.setMethod('GET');

    Http http = new Http();
    HTTPResponse res = http.send(req);
    if (res.getStatusCode() == 401)
      throw new IManageExceptions.IManageUnauthorizedException();
    String responseBody = res.getBody();

    iManageProvider.IManageApiDataResponse response = (iManageProvider.IManageApiDataResponse) JSON.deserialize(
      responseBody,
      iManageProvider.IManageApiDataResponse.class
    );
    if (response.data.auth_status == 'not-authenticated') {
      FakeCallForRefreshToken();
      return GetApiData();
    }

    return response;
  }

  private static DialogTokenResult GetDialogToken(
    iManageProvider.IManageApiDataResponse apiData
  ) {
    String customer_id = apiData?.data?.user?.customer_id == null
      ? '0'
      : apiData.data.user.customer_id;
    System.debug('customer_id: ' + customer_id);
    HttpRequest req = new HttpRequest();
    req.setEndpoint(
      'callout:iManageCreds/api/v2/customers/' +
      customer_id +
      '/dialog-tokens'
    );
    req.setHeader('content-type', 'application/json');
    req.setHeader('X-Auth-Token', '{!$Credential.AuthorizationHeaderValue}');
    req.setMethod('POST');

    Http http = new Http();
    HTTPResponse res = http.send(req);
    if (res.getStatusCode() == 401)
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
    if (res.getStatusCode() == 401)
      throw new IManageExceptions.IManageUnauthorizedException();

    String responseBody = res.getBody();
    return (SearchResult) JSON.deserialize(responseBody, SearchResult.class);
  }

  @AuraEnabled
  public static String GetIFrameFolder(String entityId) {
    // Check licensing
    LicenseService.CheckOrganizationLicense();

    IManageMappingHelper.IManageIFrameData link = IManageMappingHelper.getMappingData(
      entityId
    );
    if (link == null || link.ClientId == null || link.MatterId == null)
      throw IManageBaseHelper.BuildException(
        IManageBaseHelper.IManageErrors.EMPTY_CLIENT_OR_MATTER
      );
    try {
      iManageProvider.IManageApiDataResponse apiData = GetApiData();
      DialogTokenResult dialogTokenResult = GetDialogToken(apiData);
      iManageSettings__c mc = iManageSettings__c.getOrgDefaults();

      if (mc == null)
        throw IManageBaseHelper.BuildException(
          IManageBaseHelper.IManageErrors.EMPTY_CUSTOM_RESOURCE
        );

      SearchResult searchResult = SearchFolderId(
        link.ClientId,
        link.MatterId,
        apiData,
        mc
      );

      String dialogUrl =
        mc.Url__c +
        '/work/partner-apps/' +
        EncodingUtil.urlEncode(mc.Client_Id__c, 'UTF-8') +
        '/dialogs/file-picker/?protocol=postmessage&dialogToken=' +
        EncodingUtil.urlEncode(dialogTokenResult.data.dialog_token, 'UTF-8') +
        '&mode=emm&multiselect=false';

      if (
        searchResult == null ||
        searchResult.data == null ||
        searchResult.data.size() == 0 ||
        searchResult.data[0].id == null
      ) {
        return dialogUrl;
      }

      return dialogUrl +
        '&start=' +
        EncodingUtil.urlEncode(searchResult.data[0].id, 'UTF-8');
    } catch (IManageExceptions.IManageUnauthorizedException ex) {
      throw IManageBaseHelper.BuildException(
        IManageBaseHelper.IManageErrors.UNAUTHORIZED
      );
    }
  }

  @AuraEnabled
  public static String GetIFrameFolderPicker() {
    // Check licensing
    LicenseService.CheckOrganizationLicense();

    try {
      iManageProvider.IManageApiDataResponse apiData = GetApiData();
      DialogTokenResult dialogTokenResult = GetDialogToken(apiData);
      iManageSettings__c mc = iManageSettings__c.getOrgDefaults();
      return mc.Url__c +
        '/work/partner-apps/' +
        mc.Client_Id__c +
        '/dialogs/file-picker/?protocol=postmessage&dialogToken=' +
        EncodingUtil.urlEncode(dialogTokenResult.data.dialog_token, 'UTF-8') +
        '&mode=browse&multiselect=false&types=folder';
    } catch (IManageExceptions.IManageUnauthorizedException ex) {
      throw IManageBaseHelper.BuildException(
        IManageBaseHelper.IManageErrors.UNAUTHORIZED
      );
    }
  }

  @AuraEnabled
  public static String GetIFrameFilePicker() {
    // Check licensing
    LicenseService.CheckOrganizationLicense();

    try {
      iManageProvider.IManageApiDataResponse apiData = GetApiData();
      DialogTokenResult dialogTokenResult = GetDialogToken(apiData);
      iManageSettings__c mc = iManageSettings__c.getOrgDefaults();
      return mc.Url__c +
        '/work/partner-apps/' +
        mc.Client_Id__c +
        '/dialogs/file-picker/?protocol=postmessage&dialogToken=' +
        EncodingUtil.urlEncode(dialogTokenResult.data.dialog_token, 'UTF-8') +
        '&mode=open';
    } catch (IManageExceptions.IManageUnauthorizedException ex) {
      throw IManageBaseHelper.BuildException(
        IManageBaseHelper.IManageErrors.UNAUTHORIZED
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

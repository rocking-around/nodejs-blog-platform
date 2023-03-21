public class iManageWrapper {
  // iManage api problems
  private static void FakeCallForRefreshToken() {
    HttpRequest req = new HttpRequest();
    req.setEndpoint(
      'callout:iManageCreds/work/api/v2/customers/0/dialog-tokens'
    );
    req.setHeader('content-type', 'application/json');
    req.setHeader('X-Auth-Token', '{!$Credential.AuthorizationHeaderValue}');
    req.setMethod('POST');

    Http http = new Http();

    HTTPResponse res = http.send(req);
  }

  public static iManageProvider.IManageApiDataResponse GetApi() {
    Logger.getInstance().info('iManageWrapper::GetApi, query=/api');
    String responseBody = IManageRequestHelper.Get('/api');
    Logger.getInstance()
      .info('iManageWrapper::GetApi, response=' + responseBody);

    iManageProvider.IManageApiDataResponse response = (iManageProvider.IManageApiDataResponse) JSON.deserialize(
      responseBody,
      iManageProvider.IManageApiDataResponse.class
    );
    if (response.data.auth_status == 'not-authenticated') {
      Logger.getInstance()
        .warn(
          'iManageWrapper::FakeCallForRefreshToken, Detected iManage problem with authentication. We should do additional call for the fire refresh user token flow'
        );
      FakeCallForRefreshToken();
      return GetApi();
    }

    return response;
  }

  public static ApiInfo GetApiInfo() {
    iManageProvider.IManageApiDataResponse apiData = iManageWrapper.GetApi();
    ApiInfo apiInfo = new ApiInfo();
    apiInfo.customerId = apiData?.data?.user?.customer_id == null
      ? '0'
      : apiData.data.user.customer_id;
    apiInfo.library = apiData?.data?.work?.preferred_library == null
      ? 'ACTIVE'
      : apiData.data.work.preferred_library;

    return apiInfo;
  }

  public static iManageDocument GetDocument(
    String customerId,
    String library,
    String documentId
  ) {
    String query =
      '/work/api/v2/customers/' +
      customerId +
      '/libraries/' +
      library +
      '/documents/' +
      documentId;

    Logger.getInstance().info('iManageWrapper::GetDocument, query=' + query);
    String response = IManageRequestHelper.Get(query);
    Logger.getInstance()
      .info('iManageWrapper::PostDocument, response=' + response);
    return (iManageDocument) JSON.deserialize(response, iManageDocument.class);
  }

  public static iManageDocument PostDocument(
    String customerId,
    String library,
    String folderId,
    String name,
    String extension,
    Blob data
  ) {
    string contentType = vNHttpFormBuilder.GetContentType();

    JSONGenerator gen = JSON.createGenerator(true);
    gen.writeStartObject();
    gen.writeFieldName('doc_profile');
    gen.writeStartObject();
    gen.writeStringField('name', name);
    gen.writeStringField('extension', extension);
    gen.writeEndObject();
    gen.writeBooleanField('warnings_for_required_and_disabled_fields', true);
    gen.writeEndObject();
    string json = gen.getAsString();
    blob jsonBlob = blob.valueOf(json);
    blob formBlob = GetFormBase64(jsonBlob, data);
    string contentLength = string.valueOf(formBlob.size());

    String query =
      '/work/api/v2/customers/' +
      customerId +
      '/libraries/' +
      library +
      '/folders/' +
      folderId +
      '/documents';
    Logger.getInstance().info('iManageWrapper::PostDocument, query=' + query);
    String response = IManageRequestHelper.PostFile(
      query,
      formBlob,
      contentLength,
      contentType
    );
    Logger.getInstance()
      .info('iManageWrapper::PostDocument, response=' + response);
    return (iManageDocument) System.JSON.deserialize(
      response,
      iManageDocument.class
    );
  }

  public static Blob DownloadFile(
    String customerId,
    String library,
    String documentId
  ) {
    String query =
      '/work/api/v2/customers/' +
      customerId +
      '/libraries/' +
      library +
      '/documents/' +
      documentId +
      '/download';

    Logger.getInstance().info('iManageWrapper::DownloadFile, query=' + query);
    return IManageRequestHelper.GetFile(query);
  }

  public static iManageWorkspaceSearch SearchWorkspace(
    String customerId,
    String library,
    String clientField,
    String clientId,
    String matterField,
    String matterId
  ) {
    String query =
      '/work/api/v2/customers/' +
      customerId +
      '/libraries/' +
      library +
      '/workspaces?' +
      clientField +
      '=' +
      clientId +
      '&' +
      matterField +
      '=' +
      matterId;
    /*String body =
            '{"limit": 1, "profile_fields": { "folder": [ "name" ] }, ' +
            '"filters": { "' +
            clientField +
            '": "' +
            clientId +
            '", "' +
            matterField +
            '": "' +
            matterId +
            '" } }';*/
    Logger.getInstance()
      .info('iManageWrapper::SearchWorkspace, query=' + query);
    String responseBody = IManageRequestHelper.Get(query);
    Logger.getInstance()
      .info('iManageWrapper::SearchWorkspace, response=' + responseBody);
    try {
      return (iManageWorkspaceSearch) JSON.deserialize(
        responseBody,
        iManageWorkspaceSearch.class
      );
    } catch (Exception ex) {
      // Try to de-serialize again for on-premise iManage version
      Logger.getInstance()
        .warn(
          'iManageWrapper::SearchWorkspace, Cannot parse. Try to parse for on-prem version'
        );
      iManageWorkspaceOnPremiseSearch onPremResult = (iManageWorkspaceOnPremiseSearch) JSON.deserialize(
        responseBody,
        iManageWorkspaceOnPremiseSearch.class
      );

      iManageWorkspaceSearch result = new iManageWorkspaceSearch();
      result.data = onPremResult.data.results;

      return result;
    }
  }

  public static iManageFolder GetFolder(
    String customerId,
    String library,
    String folderId
  ) {
    String query =
      '/work/api/v2/customers/' +
      customerId +
      '/libraries/' +
      library +
      '/folders/' +
      folderId;
    Logger.getInstance().info('iManageWrapper::GetFolder, query=' + query);
    String responseBody = IManageRequestHelper.Get(query);
    Logger.getInstance()
      .info('iManageWrapper::GetFolder, response=' + responseBody);
    iManageFolderResponse response = (iManageFolderResponse) JSON.deserialize(
      responseBody,
      iManageFolderResponse.class
    );
    return response == null ? null : response.data;
  }

  public static iManageFolderResponse PostFolderToWorkspace(
    String customerId,
    String library,
    String workspaceId,
    String name,
    String clientField,
    String clientId,
    String matterField,
    String matterId
  ) {
    String query =
      '/work/api/v2/customers/' +
      customerId +
      '/libraries/' +
      library +
      '/workspaces/' +
      workspaceId +
      '/folders';
    String body =
      '{"name": "' +
      name +
      '", "default_security": "inherit", "profile": { "' +
      clientField +
      '": "' +
      clientId +
      '", "' +
      matterField +
      '": "' +
      matterId +
      '" }';
    body += '}';
    Logger.getInstance()
      .info(
        'iManageWrapper::PostFolderToWorkspace, query=' +
        query +
        '; body=' +
        body
      );
    String responseBody = IManageRequestHelper.Post(query, body);
    Logger.getInstance()
      .info('iManageWrapper::PostFolderToWorkspace, response=' + responseBody);
    system.debug(responseBody);
    return (iManageFolderResponse) JSON.deserialize(
      responseBody,
      iManageFolderResponse.class
    );
  }

  public static iManageFolderResponse PostFolder(
    String customerId,
    String library,
    String name,
    String parentId,
    String clientField,
    String clientId,
    String matterField,
    String matterId
  ) {
    String query =
      '/work/api/v2/customers/' +
      customerId +
      '/libraries/' +
      library +
      '/folders/' +
      parentId +
      '/subfolders';
    String body =
      '{"name": "' +
      name +
      '", "default_security": "inherit", "profile": { "' +
      clientField +
      '": "' +
      clientId +
      '", "' +
      matterField +
      '": "' +
      matterId +
      '" }';

    body += '}';

    Logger.getInstance()
      .info('iManageWrapper::PostFolder, query=' + query + '; body=' + body);
    String responseBody = IManageRequestHelper.Post(query, body);
    Logger.getInstance()
      .info('iManageWrapper::PostFolder, response=' + responseBody);
    return (iManageFolderResponse) JSON.deserialize(
      responseBody,
      iManageFolderResponse.class
    );
  }

  public static iManageFolderSearch SearchFolder(
    String customerId,
    String library,
    String containerId,
    String name
  ) {
    String query =
      '/work/api/v2/customers/' +
      customerId +
      '/libraries/' +
      library +
      '/folders/search';
    String body =
      '{"limit": 1, "profile_fields": { "folder": [ "name" ] }, ' +
      '"filters": { "container_id": "' +
      containerId +
      '", "name": "' +
      name +
      '" }}';
    Logger.getInstance()
      .info('iManageWrapper::SearchFolder, query=' + query + '; body=' + body);
    String responseBody = IManageRequestHelper.Post(query, body);
    Logger.getInstance()
      .info('iManageWrapper::SearchFolder, response=' + responseBody);
    return (iManageFolderSearch) JSON.deserialize(
      responseBody,
      iManageFolderSearch.class
    );
  }

  public static iManageDialogToken GetDialogToken(String customerId) {
    String query = '/work/api/v2/customers/' + customerId + '/dialog-tokens';
    Logger.getInstance().info('iManageWrapper::GetDialogToken, query=' + query);
    String responseBody = IManageRequestHelper.Post(query, '');
    Logger.getInstance()
      .info('iManageWrapper::GetDialogToken, response=' + responseBody);

    return (iManageDialogToken) JSON.deserialize(
      responseBody,
      iManageDialogToken.class
    );
  }

  /* Private */

  private static Blob GetFormBase64(Blob jsonBlob, Blob data) {
    //  Compose the form
    string form64 = '';

    form64 += vNHttpFormBuilder.WriteBoundary();
    vNHttpFormBuilder.WriteFileResult resultJson = vNHttpFormBuilder.WriteFile(
      'profile',
      'test',
      'application/json',
      jsonBlob
    );

    form64 += resultJson.Content;
    form64 += vNHttpFormBuilder.WriteBoundary(resultJson.EndingType, false);

    vNHttpFormBuilder.WriteFileResult result = vNHttpFormBuilder.WriteFile(
      'file',
      'f1.txt',
      'application/octet-stream',
      data
    );
    form64 += result.Content;
    form64 += vNHttpFormBuilder.WriteBoundary(result.EndingType, true);
    return EncodingUtil.base64Decode(form64);
  }

  // definition classes

  public class iManageDocument {
    public iManageDocumentInfo data;
  }

  public class iManageDocumentInfo {
    public String id;
    public String name;
    public String extension;
  }

  public class ApiInfo {
    public String customerId;
    public String library;
  }

  public class iManageWorkspaceSearch {
    public List<iManageWorkspace> data;
  }

  public class iManageWorkspaceOnPremiseSearch {
    public iManageWorkspaceOnPremiseSearchResults data;
  }

  public class iManageWorkspaceOnPremiseSearchResults {
    public List<iManageWorkspace> results;
  }

  public class iManageWorkspace {
    public String author;
    //public String class;
    public String content_type;
    public DateTime create_date;
    public String database;
    public String default_security;
    public Integer document_number;
    public DateTime edit_date;
    public DateTime edit_profile_date;
    public DateTime file_create_date;
    public DateTime file_edit_date;
    public Boolean has_attachment;
    public Boolean has_documents;
    public Boolean has_subfolders;
    public String id;
    public Boolean in_use;
    public Boolean indexable;
    public Boolean is_checked_out;
    public Boolean is_container_saved_search;
    public Boolean is_content_saved_search;
    public Boolean is_external;
    public Boolean is_external_as_normal;
    public Boolean is_hipaa;
    public String iwl;
    public String last_user;
    public String location;
    public String name;
    public String operator;
    public String owner;
    public String owner_description;
    public Integer retain_days;
    public Integer size;
    public String subtype;
    public String type;
    public Integer version;
    public String workspace_id;
    public String wstype;
  }

  public class iManageFolderSearch {
    public List<iManageFolder> data;
  }

  public class iManageFolderResponse {
    public iManageFolder data;
  }

  public class iManageFolder {
    public DateTime activity_date;
    public String database;
    public String default_security;
    public DateTime edit_date;
    public String folder_type;
    public Boolean has_documents;
    public Boolean has_subfolders;
    public String id;
    public Boolean is_container_saved_search;
    public Boolean is_content_saved_search;
    public Boolean is_external_as_normal;
    public String name;
    public String owner;
    public String owner_description;
    public String parent_id;
    public String workspace_id;
    public String workspace_name;
    public String wstype;
  }

  public class iManageDialogToken {
    public iManageDialogTokenData data;
  }

  public class iManageDialogTokenData {
    public String dialog_token;
  }
}

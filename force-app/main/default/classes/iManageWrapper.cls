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

  // public static iManageWorkspaceSearch searchWorkspaceByName(
  //   String customerId,
  //   String libraryId,
  //   String name
  // ) {
  //   String nameEncoded = EncodingUtil.urlEncode(name, 'UTF-8');
  //   String query = String.format(
  //     '/work/api/v2/customers/{0}/libraries/{1}/workspaces?name={2}',
  //       new List<Object>{ customerId, libraryId, nameEncoded }
  //   );

  //   Logger.getInstance()
  //     .info('iManageWrapper::SearchWorkspaceByName, query=' + query);
  //   String responseBody = IManageRequestHelper.Get(query);
  //   Logger.getInstance()
  //     .info('iManageWrapper::SearchWorkspaceByName, response=' + responseBody);
  //   try {
  //     return (iManageWorkspaceSearch) JSON.deserialize(
  //       responseBody,
  //       iManageWorkspaceSearch.class
  //     );
  //   } catch (Exception ex) {
  //     // Try to de-serialize again for on-premise iManage version
  //     Logger.getInstance()
  //       .warn(
  //         'iManageWrapper::SearchWorkspaceByName, Cannot parse. Try to parse for on-prem version'
  //       );
  //     iManageWorkspaceOnPremiseSearch onPremResult = (iManageWorkspaceOnPremiseSearch) JSON.deserialize(
  //       responseBody,
  //       iManageWorkspaceOnPremiseSearch.class
  //     );

  //     iManageWorkspaceSearch result = new iManageWorkspaceSearch();
  //     result.data = onPremResult.data.results;

  //     return result;
  //   }
  // }

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

  public static List<iManageLibrary> GetLibraries(String customerId) {
    String query = '/work/api/v2/customers/' + customerId + '/libraries';
    Logger.getInstance().info('iManageWrapper::GetLibraries, query=' + query);
    String responseBody = IManageRequestHelper.Get(query);
    Logger.getInstance()
      .info('iManageWrapper::GetLibraries, response=' + responseBody);
    iManageLibraries response = (iManageLibraries) JSON.deserialize(
      responseBody,
      iManageLibraries.class
    );
    return response == null ? null : response.data;
  }

  public static IManageWFolder getFolderById(
    String folderId,
    String customerId,
    String libraryId
  ) {
    //GET https://{hostname}/work/api/{version}/customers/{customerId}/libraries/{libraryId}/folders/{folderId}
    String query = String.format(
      '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}',
      new List<Object>{ customerId, libraryId, folderId }
    );
    Logger.getInstance()
      .info('iManageWrapper::getFolderById, query=' + query);
    String responseBody = IManageRequestHelper.Get(query);
    Logger.getInstance()
      .info('iManageWrapper::getFolderById, response=' + responseBody);

    responseBody = responseBody.replace('"class"', '"klass"');
    iManageWFolderResponse response = (iManageWFolderResponse) JSON.deserialize(
      responseBody,
      iManageWFolderResponse.class
    );
    return response.data;
  }

  public static Map<String, String> getNameValuePair(
    String objectName,
    String folderId,
    String customerId,
    String libraryId
  ) {
    //GET https://{hostname}/work/api/{version}/customers/{customerId}/libraries/{libraryId}/folders/{folderId}/name-value-pairs
    String query = String.format(
      '/work/api/v2/customers/{0}/libraries/{1}/{2}/{3}/name-value-pairs',
      new List<Object>{ customerId, libraryId, objectName, folderId }
    );
    Logger.getInstance()
      .info('iManageWrapper::getNameValuePair, query=' + query);
    String responseBody = IManageRequestHelper.Get(query);
    Logger.getInstance()
      .info(
        'iManageWrapper::getNameValuePair, response=' + responseBody
      );

    iManageNameValuePairResponse response = (iManageNameValuePairResponse) JSON.deserialize(
      responseBody,
      iManageNameValuePairResponse.class
    );
    return response.data;
  }

  public static IManageWFolder getSearchFolderById(
    String folderId,
    String customerId,
    String libraryId
  ) {
    String query = String.format(
      '/work/api/v2/customers/{0}/libraries/{1}/search-folders/{2}',
      new List<Object>{ customerId, libraryId, folderId }
    );
    Logger.getInstance()
      .info('iManageWrapper::getSearchFolderById, query=' + query);
    String responseBody = IManageRequestHelper.Get(query);
    Logger.getInstance()
      .info('iManageWrapper::getSearchFolderById, response=' + responseBody);

    responseBody = responseBody.replace('"class"', '"klass"');
    iManageWFolderResponse response = (iManageWFolderResponse) JSON.deserialize(
      responseBody,
      iManageWFolderResponse.class
    );
    return response.data;
  }

  public static IManageWWorkspace getWorkspace(
    String workspaceId,
    String libraryId
  ) {
    LicenseService.CheckOrganizationLicense();
    iManageWrapper.ApiInfo apiInfo = iManageWrapper.GetApiInfo();

    // GET
    // https://{hostname}/work/api/{version}/customers/{customerId}/libraries/{libraryId}/workspaces/{workspaceId}
    String query =
      '/work/api/v2/customers/' +
      apiInfo.customerId +
      '/libraries/' +
      libraryId +
      '/workspaces/' +
      workspaceId;
    Logger.getInstance()
      .info('iManageWrapper::getWorkspace, query=' + query);
    String responseBody = IManageRequestHelper.Get(query);
    Logger.getInstance()
      .info('iManageWrapper::getWorkspace, response=' + responseBody);
    iManageWorkspaceResponse response = (iManageWorkspaceResponse) JSON.deserialize(
      responseBody,
      iManageWorkspaceResponse.class
    );

    return response == null ? null : response.data;
  }

  public static iManageTemplatesResponse searchTemplateWorkspace(
    String customerId,
    String libraryId,
    String templateName,
    Integer offset,
    Integer size) {
      String query = String.format(
        '/work/api/v2/customers/{0}/libraries/{1}/templates?offset={2}&limit={3}&total=true',
        new List<Object>{ customerId, libraryId, offset, size }
      );

      if (String.isNotBlank(templateName)) {
        query = query + '&name_or_description=' + templateName;
      }

      Logger.getInstance()
      .info('iManageWrapper::searchTemplateWorkspace, query=' + query);
      String responseBody = IManageRequestHelper.Get(query);
      Logger.getInstance()
        .info(
          'iManageWrapper::searchTemplateWorkspace, response=' +
          responseBody
        );

      iManageTemplatesResponse response = (iManageTemplatesResponse) JSON.deserialize(
        responseBody,
        iManageTemplatesResponse.class
      );
      return response;
  }

  public static IManageWWorkspace createWorkspaceApiCall(
    IManageWWorkspace templateWorkspace,
    String customerId,
    String libraryId
  ) {
    //POST https://{hostname}/work/api/{version}/customers/{customerId}/libraries/{libraryId}/workspaces
    String query = String.format(
      '/work/api/v2/customers/{0}/libraries/{1}/workspaces',
      new List<Object>{ customerId, libraryId }
    );
    Map<String, Object> reqBody = new Map<String, Object>{
      'name' => templateWorkspace.name,
      'database' => libraryId,
      'custom1' => templateWorkspace.custom1,
      'custom2' => templateWorkspace.custom2,
      'default_security' => templateWorkspace.default_security,
      'description' => templateWorkspace.description,
      'is_declared' => templateWorkspace.is_declared,
      'is_external_as_normal' => templateWorkspace.is_external_as_normal,
      'retain_days' => templateWorkspace.retain_days,
      'subclass' => templateWorkspace.subclass
    };

    reqBody = IManageUtils.removeNullItemsFromMap(reqBody, null);

    String body = JSON.serialize(reqBody, true);

    Logger.getInstance()
      .info(
        'iManageWrapper::createWorkspaceApiCall, query=' +
        query +
        '; body=' +
        body
      );
    String responseBody = IManageRequestHelper.Post(query, body);
    Logger.getInstance()
      .info(
        'iManageWrapper::createWorkspaceApiCall, response=' +
        responseBody
      );
    system.debug(responseBody);
    iManageWorkspaceResponse response = (iManageWorkspaceResponse) JSON.deserialize(
      responseBody,
      iManageWorkspaceResponse.class
    );

    return response.data;
  }

  public static IManageWFolder createFolder(
    String workspaceId,
    IManageWFolder sourceFolder,
    String parentFolderId,
    Boolean parentIsTab,
    String owner,
    String customerId,
    String libraryId
  ) {
    String query = '';
    if (String.isNotBlank(parentFolderId)) {
      if (parentIsTab == true) {
        query = String.format(
          '/work/api/v2/customers/{0}/libraries/{1}/tabs/{2}/folders',
          new List<Object>{ customerId, libraryId, parentFolderId }
        );
      } else {
        query = String.format(
          '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}/subfolders',
          new List<Object>{ customerId, libraryId, parentFolderId }
        );
      }
    } else {
      query = String.format(
        '/work/api/v2/customers/{0}/libraries/{1}/workspaces/{2}/folders',
        new List<Object>{ customerId, libraryId, workspaceId }
      );
    }

    Map<String, Object> reqBody = new Map<String, Object>{
      'name' => sourceFolder.name,
      'description' => sourceFolder.description,
      'default_security' => sourceFolder.default_security,
      'is_external_as_normal' => sourceFolder.is_external_as_normal,
      'email' => null,
      'owner' => owner != null ? owner : sourceFolder.owner,
      'parent_id' => workspaceId,
      'project_custom1' => sourceFolder.project_custom1,
      'project_custom2' => sourceFolder.project_custom2,
      'project_custom3' => sourceFolder.project_custom3,
      'database' => libraryId
    };
    reqBody = IManageUtils.removeNullItemsFromMap(reqBody, null);
    String body = JSON.serialize(reqBody, true);

    Logger.getInstance()
      .info(
        'iManageWrapper::createFolder, query=' +
        query +
        '; body=' +
        body
      );
    String responseBody = IManageRequestHelper.Post(query, body);
    Logger.getInstance()
      .info('iManageWrapper::createFolder, response=' + responseBody);
    System.debug(responseBody);

    iManageWFolderResponse response = (iManageWFolderResponse) JSON.deserialize(
      responseBody,
      iManageWFolderResponse.class
    );

    return response.data;
  }

  public static IManageWFolder createTab(
    IManageWFolder sourceTab,
    String workspaceId,
    String customerId,
    String libraryId
  ) {
    String query = String.format(
      '/work/api/v2/customers/{0}/libraries/{1}/workspaces/{2}/tabs',
      new List<Object>{ customerId, libraryId, workspaceId }
    );
    Map<String, Object> reqBody = sourceTab.toWFolderRequestMap();
    reqBody.put('database', libraryId);
    reqBody = IManageUtils.removeNullItemsFromMap(reqBody, null);
    String body = JSON.serialize(reqBody, true);

    Logger.getInstance()
      .info(
        'iManageWrapper::createTab, query=' +
        query +
        '; body=' +
        body
      );
    String responseBody = IManageRequestHelper.Post(query, body);
    Logger.getInstance()
      .info('iManageWrapper::createTab, response=' + responseBody);
    System.debug(responseBody);

    IManageTabResponse response = (IManageTabResponse) JSON.deserialize(
      responseBody,
      IManageTabResponse.class
    );

    return response.data;
  }

  public static IManageWFolder createSearchFolder(
    IManageWFolder sourceTab,
    String workspaceId,
    String parentFolderId,
    String customerId,
    String libraryId
  ) {
    String query = String.isNotBlank(parentFolderId)
      ? String.format(
        '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}/search-folders',
        new List<Object>{ customerId, libraryId, parentFolderId }
      )
      : String.format(
        '/work/api/v2/customers/{0}/libraries/{1}/workspaces/{2}/search-folders',
        new List<Object>{ customerId, libraryId, workspaceId }
      );
    Map<String, Object> reqBody = sourceTab.toWSearchFolderRequest();
    reqBody.put('database', libraryId);
    reqBody = IManageUtils.removeNullItemsFromMap(reqBody, null);
    String body = JSON.serialize(reqBody, true);

    Logger.getInstance()
      .info(
        'iManageWrapper::createSearchFolder, query=' +
        query +
        '; body=' +
        body
      );
    String responseBody = IManageRequestHelper.Post(query, body);
    Logger.getInstance()
      .info('iManageWrapper::createSearchFolder, response=' + responseBody);
    System.debug(responseBody);

    iManageWFolderResponse response = (iManageWFolderResponse) JSON.deserialize(
      responseBody,
      iManageWFolderResponse.class
    );

    return response.data;
  }

  public static iManageFoldersResponse getFoldersByWorkspace(
    String customerId,
    String libraryId,
    String workspaceTemplateId,
    Integer offset,
    Integer size
  ) {
    String logPrefix = 'iManageWrapper::getFoldersByWorkspace';
    String query =
      '/work/api/v2/customers/' +
      customerId +
      '/libraries/' +
      libraryId +
      '/folders?total=true&offset=' +
      String.valueOf(offset) +
      '&limit=' +
      String.valueOf(size) +
      '&container_id=' +
      workspaceTemplateId;
    Logger.getInstance()
      .info(logPrefix + ', query=' + query);
    String responseBody = IManageRequestHelper.Get(query);
    Logger.getInstance()
      .info(
        logPrefix + ', response=' +
        responseBody
      );

    iManageFoldersResponse response = (iManageFoldersResponse) JSON.deserialize(
      responseBody,
      iManageFoldersResponse.class
    );
    return response;
  }

  public static List<IManageWSecurity> getFolderACL(
    string folderId,
    String customerId,
    String libraryId
  ) {
    String query = String.format(
      '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}/security',
      new List<Object>{ customerId, libraryId, folderId }
    );
    Logger.getInstance()
      .info('iManageWrapper::getFolderACL, query=' + query);
    String responseBody = IManageRequestHelper.Get(query);
    Logger.getInstance()
      .info('iManageWrapper::getFolderACL, response=' + responseBody);

    iManageSecurityResponse response = (iManageSecurityResponse) JSON.deserialize(
      responseBody,
      iManageSecurityResponse.class
    );

    return response.data;
  }

  public static List<IManageWSecurity> getTabACL(
    string tabId,
    String customerId,
    String libraryId
  ) {
    String query = String.format(
      '/work/api/v2/customers/{0}/libraries/{1}/tabs/{2}/security',
      new List<Object>{ customerId, libraryId, tabId }
    );
    Logger.getInstance()
      .info('iManageWrapper::getTabACL, query=' + query);
    String responseBody = IManageRequestHelper.Get(query);
    Logger.getInstance()
      .info('iManageWrapper::getTabACL, response=' + responseBody);

    iManageSecurityResponse response = (iManageSecurityResponse) JSON.deserialize(
      responseBody,
      iManageSecurityResponse.class
    );

    return response.data;
  }

  public static iManageSecurityResponse getWorkspaceACL(
    string workspaceId,
    String customerId,
    String libraryId
  ) {
    String logPrefix = 'iManageWrapper::getFolderACL';
    String query = String.format(
      '/work/api/v2/customers/{0}/libraries/{1}/workspaces/{2}/security',
      new List<Object>{ customerId, libraryId, workspaceId }
    );
    Logger.getInstance()
      .info(logPrefix + ', query=' + query);
    String responseBody = IManageRequestHelper.Get(query);
    Logger.getInstance()
      .info(logPrefix + ', response=' + responseBody);

    iManageSecurityResponse response = (iManageSecurityResponse) JSON.deserialize(
      responseBody,
      iManageSecurityResponse.class
    );

    return response;
  }

  public static IManageWWorkspace patchWorkspaceApiCall(
    String workspaceId,
    Map<String, Object> patchData,
    String customerId,
    String libraryId
  ) {
    String logPrefix = 'iManageWrapper::patchWorkspaceApiCall';

    //PATCH https://{hostname}/work/api/{version}/customers/{customerId}/libraries/{libraryId}/workspaces/{workspaceId}

    String query = String.format(
      '/work/api/v2/customers/{0}/libraries/{1}/workspaces/{2}',
      new List<Object>{ customerId, libraryId, workspaceId }
    );
    Map<String, Object> reqBody = IManageUtils.removeNullItemsFromMap(patchData, null);

    String body = JSON.serialize(reqBody, true);

    Logger.getInstance()
      .info(
        logPrefix + ', query=' +
        query +
        '; body=' +
        body
      );
    String responseBody = IManageRequestHelper.Patch(query, body);
    Logger.getInstance()
      .info(
        logPrefix + ', response=' +
        responseBody
      );
    system.debug(responseBody);
    iManageWorkspaceResponse response = (iManageWorkspaceResponse) JSON.deserialize(
      responseBody,
      iManageWorkspaceResponse.class
    );

    return response.data;
  }

  public static Object patchFolder(
    String folderId,
    String customerId,
    String libraryId,
    Map<String, Object> data
  ) {
    String query = String.format(
      '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}',
      new List<Object>{ customerId, libraryId, folderId }
    );

    String body = JSON.serialize(data, true);
    Logger.getInstance()
      .info(
        'iManageWrapper::patchFolder, query=' +
        query +
        '; body=' +
        body
      );
    String responseBody = IManageRequestHelper.Patch(query, body);
    Logger.getInstance()
      .info('iManageWrapper::patchFolder, response=' + responseBody);

    Object response = JSON.deserializeUntyped(responseBody);
    return response;
  }

  public static Object patchNameValuePair(
    String objectName,
    String objectId,
    String customerId,
    String libraryId,
    Map<String, Object> data
  ) {
    String query = String.format(
      '/work/api/v2/customers/{0}/libraries/{1}/{2}/{3}/name-value-pairs',
      new List<Object>{ customerId, libraryId, objectName, objectId }
    );

    String body = JSON.serialize(data, true);
    Logger.getInstance()
      .info(
        'iManageWrapper::patchNameValuePair, query=' +
        query +
        '; body=' +
        body
      );
    String responseBody = IManageRequestHelper.Patch(query, body);
    Logger.getInstance()
      .info(
        'iManageWrapper::patchNameValuePair, response=' + responseBody
      );

    Object response = String.isNotBlank(responseBody)
      ? JSON.deserializeUntyped(responseBody)
      : null;
    return response;
  }

  public static List<IManageWSecurity> patchSecurityFolder(
    String id,
    String customerId,
    String libraryId,
    Object data
  ) {
    return patchSecurity(id, 'folders', customerId, libraryId, data);
  }

  public static List<IManageWSecurity> patchSecurityTab(
    String id,
    String customerId,
    String libraryId,
    Object data
  ) {
    return patchSecurity(id, 'tabs', customerId, libraryId, data);
  }

  public static List<IManageWSecurity> patchSecurityWorkspace(
    String id,
    String customerId,
    String libraryId,
    Object data
  ) {
    return patchSecurity(id, 'workspaces', customerId, libraryId, data);
  }

  private static List<IManageWSecurity> patchSecurity(
    String id,
    String resourceName,
    String customerId,
    String libraryId,
    Object data
  ) {
    String logPrefix = 'iManageWrapper::patchSecurity, resource = ' + resourceName;
    String query = String.format(
      '/work/api/v2/customers/{0}/libraries/{1}/{2}/{3}/security',
      new List<Object>{ customerId, libraryId, resourceName, id }
    );
    String body = JSON.serialize(data, true);

    Logger.getInstance()
      .info(
        logPrefix + ', query=' +
        query +
        '; body=' +
        body
      );
    String responseBody = IManageRequestHelper.Post(query, body);
    Logger.getInstance()
      .info(
        logPrefix + ', response=' + responseBody
      );
    System.debug(responseBody);

    iManageSecurityResponse response = (iManageSecurityResponse) JSON.deserialize(
      responseBody,
      iManageSecurityResponse.class
    );

    return response.data;
  }

  public static Map<String, Object> getCustomProperty(
    String alias,
    String customTable,
    String parentAlias,
    String customerId,
    String libraryId
  ) {
    String logPrefix = 'iManageWrapper::getCustomProperty';
    String query = String.format(
      '/work/api/v2/customers/{0}/libraries/{1}/customs/{2}/{3}',
      new List<Object>{ customerId, libraryId, customTable, alias }
    );
    if (String.isNotBlank(parentAlias)) {
      query += '?parent_alias=' + parentAlias;
    }

    Logger.getInstance()
      .info(logPrefix + ', query=' + query);
    String responseBody = IManageRequestHelper.Get(query);
    Logger.getInstance()
      .info(logPrefix + ', response=' + responseBody);

    Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(responseBody);

    return result;
  }

  public static Map<String, Object> createCustomProperty(
    String customTable,
    String alias,
    String description,
    Boolean enabled,
    Boolean hipaa,
    String parentAlias,
    String customerId,
    String libraryId
  ) {
    String logPrefix = 'iManageWrapper::createCustomProperty';
    String query = String.format(
      '/work/api/v2/customers/{0}/libraries/{1}/customs/{2}',
      new List<Object>{ customerId, libraryId, customTable }
    );
    Map<String, Object> reqBody = new Map<String, Object> {
      'id' => alias,
      'description' => description,
      'enabled' => enabled,
      'hipaa' => hipaa
    };
    if (String.isNotBlank(parentAlias)) {
      reqBody.put('parent', new Map<String, Object> {
          'id' => parentAlias
        }
      );
    }

    String body = JSON.serialize(reqBody);

    Logger.getInstance()
      .info(
        logPrefix + ', query=' +
        query + '; body=' + body
      );
    String responseBody = IManageRequestHelper.Post(query, body);
    Logger.getInstance()
      .info(logPrefix + ', response=' + responseBody);

    if (String.isBlank(responseBody)) {
      return new Map<String, Object> ();
    }

    Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(responseBody);

    return result;
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
    public List<IManageWWorkspace> data;
    public IManageResponseError error;
  }

  public class iManageWorkspaceOnPremiseSearch {
    public iManageWorkspaceOnPremiseSearchResults data;
    public IManageResponseError error;
  }

  public class iManageWorkspaceOnPremiseSearchResults {
    public List<IManageWWorkspace> results;
  }

  public class iManageLibraries {
    public List<iManageLibrary> data;
  }

  public class iManageLibrary {
    public String id;
    public String type;
    public Boolean is_hidden;
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

  public class iManageWFolderResponse {
    public IManageWFolder data;
  }

  // TODO: Deprecated. use iManageWFolderResponse
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

  public class iManageFoldersResponse {
    public List<IManageWFolder> data;
    public Integer total_count;
  }

  public class iManageTemplatesResponse {
    public iManageTemplates data;
    public Integer total_count;
  }

  public class iManageTemplates {
    public List<IManageWWorkspace> results;
  }

  public class IManageTabResponse {
    public IManageWFolder data;
  }

  public class iManageSecurityResponse {
    public List<IManageWSecurity> data;
    public String default_security;
  }

  public class iManageNameValuePairResponse {
    public Map<String, String> data;
  }

  public class iManageWorkspaceResponse {
    public IManageWWorkspace data;
  }

}

public class iManageWorkspacesHelper {
  public static String SearchWorkspace(iManageSettings__c mc, 
    iManageWrapper.ApiInfo apiData, IManageMappingHelper.IManageIFrameData link) {
    Logger.getInstance().info('iManageWorkspacesHelper::SearchWorkspace, start method');
    String libraries = mc?.iManage_Libraries__c == null || mc.iManage_Libraries__c == '' 
      ? apiData.library 
      : mc.iManage_Libraries__c;
    Logger.getInstance().info('iManageWorkspacesHelper::SearchWorkspace, list libraries: ' + libraries);
    for(String library : libraries.split(';')) {
      try {
        Logger.getInstance().info('iManageWorkspacesHelper::SearchWorkspace, search into library: ' + library);
        iManageWrapper.iManageWorkspaceSearch searchResult = iManageWrapper.SearchWorkspace(
          apiData.customerId,
          library,
          mc.ClientField__c,
          link.ClientId,
          mc.MatterField__c,
          link.MatterId
        );

        if (
          searchResult != null &&
          searchResult.data != null &&
          searchResult.data.size() != 0 &&
          searchResult.data[0].id != null
        ) {
          Logger.getInstance().info('iManageWorkspacesHelper::SearchWorkspace, found result: ' + searchResult.data[0].id);
          return searchResult.data[0].id;
        }
        
        Logger.getInstance().info('iManageWorkspacesHelper::SearchWorkspace, not found into library: ' + library);
      }
      catch(Exception ex) {
        Logger.getInstance().warn('iManageWorkspacesHelper::SearchWorkspace, error searching into library: ' + library);
        // Not found workspace
      }
    }
    
    Logger.getInstance().info('iManageWorkspacesHelper::SearchWorkspace, not found results');
    return '';
  }

  @AuraEnabled
  public static Map<String, Object> getFoldersByWorkspace(
    String workspaceTemplate,
    Integer offset,
    Integer size) {

    String[] wsData = workspaceTemplate.split('::', 2);
    String libraryId = wsData[0];
    String wsTemplateId = wsData[1];

    String logPrefix = 'iManageWorkspacesHelper::getFoldersByWorkspace';
    Map<String, Object> params = new Map<String, Object>{
      'workspaceTemplate' => workspaceTemplate,
      'offset' => offset,
      'size' => size
    };
    Logger.getInstance()
      .info(logPrefix + ', start method. Params: ' + JSON.serialize(params));

    LicenseService.CheckOrganizationLicense();

    try {
      iManageWrapper.ApiInfo apiInfo = iManageWrapper.GetApiInfo();
      Map<string, Object> results = iManageWrapper.GetFoldersByWorkspace(
        apiInfo.customerId,
        libraryId,
        wsTemplateId,
        offset,
        size
      );

      return results;

    } catch (Exception ex) {
      Logger.getInstance().error(ex, logPrefix);
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
  }

  @AuraEnabled
  public static Void createWorkspace(
    String custom1, // client alias
    String custom2, // matter alias
    String wsTemplate,
    String workspaceTemplate // "libraryId::templateId"
  ){
    String[] wsData = workspaceTemplate.split('::', 2);
    String libraryId = wsData[0];
    String wsTemplateId = wsData[1];

    String logPrefix = 'iManageWorkspacesHelper::createWorkspace';
    Map<String, Object> params = new Map<String, Object>{
      'workspaceTemplate' => workspaceTemplate
    };
    Logger.getInstance()
      .info(logPrefix + ', start method. Params: ' + JSON.serialize(params));

    LicenseService.CheckOrganizationLicense();

    try {
      Map<String, Object> generalSettings =  ConfigurationHelper.getGeneralSettings();
      iManageWrapper.ApiInfo apiInfo = iManageWrapper.GetApiInfo();
      Logger.getInstance().info(logPrefix + ': Get template workspace');
      IManageWorkspaceWrap templateWorkspaceWrap = getWorkspaceTemplateWrap(wsTemplateId, libraryId);

      if (templateWorkspaceWrap == null) {
        throw new IManageExceptions.IManageApplicationException('Workspace template not found. WS Template Id = ' + wsTemplateId);
      }

      // get list and reverse it
      List<IManageFolderWrap> templateFolders = new List<IManageFolderWrap>();
      List<IManageFolderWrap> tmpTemplateFolders = templateWorkspaceWrap.getFlatListAllFolders();
      for(Integer i = tmpTemplateFolders.size() - 1; i >= 0; i--){
        templateFolders.add(tmpTemplateFolders[i]);
      }
      //

      Logger.getInstance().info('Found ' + String.valueOf(templateFolders.size()) + ' template folders.');

      // clone templateWorkspaceWrap.wrapItem
      IManageWWorkspace templateWorkspace = ((IManageWWorkspace)templateWorkspaceWrap.wrapItem).cloneThis();

      Logger.getInstance().Info('Create destination workspace...');
      templateWorkspace.custom1 = custom1;
      templateWorkspace.custom2 = custom2;
      templateWorkspace.Name = wsTemplate;

      IManageWWorkspace sourceWorkspace = createWorkspaceApiCall(templateWorkspace, apiInfo.customerId, libraryId);
      Logger.getInstance().info('Workspace created.');

      Logger.getInstance().info('Compare folders and update by template.');

      IManageWorkspaceWrap sourceWorkspaceWrap = getWorkspaceContentWrap(sourceWorkspace.Id, libraryId, true, false);

      compareFoldersAndUpdateByTemplate(
        sourceWorkspaceWrap,
        templateFolders,
        customerId,
        libraryId,
        custom1,
        custom2
      );

    } catch (Exception ex) {
      Logger.getInstance().error(ex, logPrefix);
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
  }

  public static IManageWWorkspace createWorkspaceApiCall(
    IManageWWorkspace templateWorkspace,
    String customerId,
    String libraryId
  ) {
    //POST https://{hostname}/work/api/{version}/customers/{customerId}/libraries/{libraryId}/workspaces
    String query = String.format(
      '/work/api/v2/customers/{0}/libraries/{1}/workspaces',
      new List<Object> {customerId, libraryId }
    );
    String body =
        '{' +
          '"database": "' + libraryId + '",' +
          '"name": "' + templateWorkspace.name + '",' +
          '"custom1": "' + templateWorkspace.custom1 + '",' +
          '"custom2": "' + templateWorkspace.custom2 + '",' +
          '"default_security": "' + templateWorkspace.default_security + '",' +
          '"description":' + (templateWorkspace.description == null ? 'null' : '"'+ templateWorkspace.description + '"') + ',' +
          '"is_declared":' + String.valueOf(templateWorkspace.is_declared).toLowerCase() + ',' +
          '"is_external_as_normal":' + String.valueOf(templateWorkspace.is_external_as_normal).toLowerCase() + ',' +
          '"subclass":' + (templateWorkspace.subclass == null ? 'null' : '"'+ templateWorkspace.subclass + '"') + //',' +
          //'"profile":' + (templateWorkspace.profile == null ? 'null' : '{}') + //TODO: Serialize profile
        '}';

    Logger.getInstance().info('iManageWorkspacesHelper::createWorkspaceApiCall, query=' + query + '; body='+ body);
    String responseBody = IManageRequestHelper.Post(query, body);
    Logger.getInstance().info('iManageWorkspacesHelper::createWorkspaceApiCall, response=' + responseBody);
    system.debug(responseBody);
    iManageWorkspaceResponse response = (iManageWorkspaceResponse) JSON.deserialize(
        responseBody,
        iManageWorkspaceResponse.class
    );

    return response.data;
  }

  public static IManageWorkspaceWrap getWorkspaceContentWrap(
    String workspaceId,
    String libraryId,
    Boolean onlyFolders,
    Boolean foldersWithProfile
  ) {
    if (!onlyFolders)
    {
      throw new IManageExceptions.IManageApplicationException(
        String.format(
          'Not implemented. getWorkspaceContentWrap(... onlyFolders = {0} ...)',
          new List<Object> { onlyFolders }
        )
      );
    }

    return getWorkspaceTemplateWrap(workspaceId, libraryId);
  }

  public static IManageWorkspaceWrap getWorkspaceTemplateWrap(String workspaceId, String libraryId) {
    IManageWWorkspace workspace = getWorkspace(workspaceId, libraryId);
    List<IManageWFolder> folders = getAllFoldersByWorkspace(workspaceId, libraryId);

    return wrapWorkspaceContent(workspace, folders);
  }

  public static IManageWWorkspace getWorkspace(String workspaceId, String libraryId) {
    LicenseService.CheckOrganizationLicense();
    iManageWrapper.ApiInfo apiInfo = iManageWrapper.GetApiInfo();

    // GET
    // https://{hostname}/work/api/{version}/customers/{customerId}/libraries/{libraryId}/workspaces/{workspaceId}
    String query = '/work/api/v2/customers/' + apiInfo.customerId + '/libraries/' + libraryId + '/workspaces/' + workspaceId;
    Logger.getInstance().info('iManageWorkspacesHelper::getWorkspace, query=' + query);
    String responseBody = IManageRequestHelper.Get(query);
    Logger.getInstance().info('iManageWorkspacesHelper::getWorkspace, response=' + responseBody);
    iManageWorkspaceResponse response = (iManageWorkspaceResponse) JSON.deserialize(
        responseBody,
        iManageWorkspaceResponse.class
    );

    return response == null ? null : response.data;
  }

  public static List<IManageWFolder> getAllFoldersByWorkspace(String workspaceId, String libraryId) {
    Integer packageSize = 200;
    iManageWrapper.ApiInfo apiInfo = iManageWrapper.GetApiInfo();
    List<IManageWFolder> allFolders = new List<IManageWFolder>();

    for (Integer p = 0, total = 0; p == 0 || allFolders.size() < total; p++)
    {
        Integer offset = p * packageSize;

        iManageFoldersResponse packageFoldersResp = getFoldersByWorkspace(
          apiInfo.customerId,
          libraryId,
          workspaceId,
          offset,
          packageSize
        );
        allFolders.addAll(packageFoldersResp.data);

        if (p == 0) {
          total = packageFoldersResp.total_count;
        }

        if (p > 10) {
          throw new IManageExceptions.IManageApplicationException('Infinite loop');
        }
    }

    return allFolders;
  }

  public static iManageFoldersResponse getFoldersByWorkspace(
      String customerId,
      String libraryId,
      String workspaceTemplateId,
      Integer offset,
      Integer size
      ) {
      String query = '/work/api/v2/customers/' + customerId + '/libraries/' + libraryId + '/folders?total=true&offset=' + String.valueOf(offset)
          + '&limit=' + String.valueOf(size) + '&container_id=' + workspaceTemplateId;
      Logger.getInstance().info('iManageWorkspacesHelper::getFoldersByWorkspace, query=' + query);
      String responseBody = IManageRequestHelper.Get(query);
      Logger.getInstance().info('iManageWorkspacesHelper::getFoldersByWorkspace, response=' + responseBody);

      iManageFoldersResponse response = (iManageFoldersResponse) JSON.deserialize(
        responseBody,
        iManageFoldersResponse.class
      );
      return response;
  }

  public static IManageWorkspaceWrap wrapWorkspaceContent(IManageWWorkspace sourceWorkspace, List<IManageWFolder> folders) {
    IManageWorkspaceWrap workspaceWrap = new IManageWorkspaceWrap(sourceWorkspace);

    List<IManageFolderWrap> children = new List<IManageFolderWrap>();
    for (IManageWFolder folder: folders) {
      IManageFolderWrap f = new IManageFolderWrap(folder);
      f.workspaceId = sourceWorkspace.id;
      children.add(f);
    }
    workspaceWrap.children.addAll(children);

    for (Object x: workspaceWrap.children){
      IManageFolderWrap folderWrap = (IManageFolderWrap)x;
      mappingFolders(folderWrap, folders);
    }
    return workspaceWrap;
  }

  private static void mappingFolders(IManageFolderWrap folderWrap, List<IManageWFolder> folders)
  {
      List<IManageFolderWrap> children = new List<IManageFolderWrap>();
      for (IManageWFolder folder: folders) {
        if (folder.parent_id == ((IManageWFolder)folderWrap.wrapItem).id) {
          IManageFolderWrap fw = new IManageFolderWrap(folder);
          fw.parentFolder = folderWrap;
          fw.workspaceId = folderWrap.workspaceId;
          children.add(fw);
        }
      }
      folderWrap.children.addAll(children);

      for (Object x : folderWrap.children) {
        IManageFolderWrap fw = (IManageFolderWrap)x;
        mappingFolders(fw, folders);
      }
  }

  public static IManageWorkspaceWrap compareFoldersAndUpdateByTemplate(
    IManageWorkspaceWrap mappingWorkspaceWrap,
    List<IManageFolderWrap> templateFolders,
    String customerId,
    String libraryId,
    String clientId,
    String matterId
  ) {
    Logger.getInstance().info('iManageWorkspacesHelper::compareFoldersAndUpdateByTemplate, START');
    var clientMatterCode = String.format('{0}.{1}', new List<Object> {clientId, matterId});
    List<IManageFolderWrap> workspaceFolders = mappingWorkspaceWrap.getFlatListAllFolders();

    var mappedTemplateFolders = templateFolders.Select(tf =>
        new Tuple<FolderWrap, FolderWrap>(
          tf,
          workspaceFolders.FirstOrDefault(
            rf => rf.WrapItem.FolderType.Equals(tf.WrapItem.FolderType, StringComparison.OrdinalIgnoreCase)
            && rf.FolderFullPath.Equals(tf.FolderFullPath, StringComparison.OrdinalIgnoreCase)
          )
        )
      )
      .OrderBy(x => x.Item1.FolderFullPath.Length)
      .ToList();
    
    List<Map<String, Object>> mappedTemplateFolders = new List<Map<String, Object>>();
    for (IManageFolderWrap tf: templateFolders) {
      IManageFolderWrap fw = null; //TODO: calc
      Map<String, Object> mappedTemplateFoldersItem = new Map<String, Object> (
        'item1' => tf,
        'item1' => fw
      );
      mappedTemplateFolders.add(mappedTemplateFoldersItem); //TODO: sort
    }

    //var dbFoldersSecurity = await _dbClient.GetFoldersSecurityRows(matterRow.UID);
    //create new folders
    foreach (var templateFolderWrap in mappedTemplateFolders.Where(x => x.Item2 == null).Select(x => x.Item1))
    {
        workspaceFolders = mappingWorkspaceWrap.GetFlatListAllFolders();
        var parentDestFolder = workspaceFolders.FirstOrDefault(fw => fw.FolderFullPath.Equals(templateFolderWrap.ParentFolder?.FolderFullPath, StringComparison.OrdinalIgnoreCase))?.WrapItem;
        string parentDestFolderId = parentDestFolder?.Id;
        var parentIsTab = parentDestFolder?.FolderType == "tab";

        String folderType = ((IManageWFolder)templateFolderWrap.wrapItem).folder_type;
        if (folderType == 'regular')
        {
            var tf = await GetTemplateWFolder(templateFolderWrap.WrapItem.Id, clientApi);
            if (tf.IsOptional)
            {
                _log.Info($"Workspace: {clientMatterCode}. Optional Folder: {templateFolderWrap.FolderFullPath} add ignored.");
                continue;
            }

            if (templateFolderWrap.ParentFolder != null && parentDestFolder == null)
            {
                _log.Info($"Workspace: {clientMatterCode}. Folder: {templateFolderWrap.FolderFullPath} add ignored because the parent folder is optional.");
                continue;
            }

            tf = MappingProfileWorkspaceValues(mappingWorkspaceWrap.WrapItem, tf);

            var needEmail = !string.IsNullOrWhiteSpace(tf.Email);
            tf.Name = BuildFolderName(tf.Name, matterRow, folderVariableMatrixRows);
            var newDestFolder = await RetryHelper(async () =>
                    await clientApi.CreateFolderAsync(mappingWorkspaceWrap.WrapItem.Id,
                        tf, parentDestFolderId,
                      _main.AccessToken, parentIsTab: parentIsTab, owner: _main.UserId),
                      $"Create folder {clientMatterCode}-{templateFolderWrap.FolderFullPath}", throwException: true);
            await RetryHelper(async () =>
              await clientApi.PatchNameValuePair("folders", newDestFolder.Id, _main.AccessToken, new
              {
                  FolderTemplateId = tf.Id
              }), "Patch folder name-value-pair", throwException: true);

            if (needEmail)
            {
                _log.Info($"Patch Folder: {templateFolderWrap.FolderFullPath} email.");
                var email = $"{newDestFolder.Name.Replace(" ", "_")}.{newDestFolder.Id.Split('!')[1]}";
                await RetryHelper(async () =>
                    {
                        return await clientApi.PatchFolder(_main.AccessToken, newDestFolder.Id, new { email });
                    }, $"Patch folder {email} email", throwException: true);
            }
            _log.Info($"Workspace: {clientMatterCode}. Folder: {templateFolderWrap.FolderFullPath}  added");
            var dbFolderSecurity = dbFoldersSecurity.Where(fs => templateFolderWrap.FolderFullPath.ToLower().Replace("/", "\\") == fs.FolderName.ToLower()).ToList();
            if (newDestFolder.DefaultSecurity != "inherit" || dbFolderSecurity.Any())
            {
                var templateWsSecurity = await RetryHelper(async () =>
                await clientApi.GetFolderACL(_main.AccessToken, templateFolderWrap.WrapItem.Id), "Get template folder security", throwException: true);
                var fSecurityList = templateWsSecurity.Data.ToList();
                foreach (var wsAcl in dbFolderSecurity)
                {
                    var sourceFAcl = fSecurityList.FirstOrDefault(a => a.ID == wsAcl.UserOrGroup);
                    if (sourceFAcl == null)
                    {
                        fSecurityList.Add(new WSecurity { ID = wsAcl.UserOrGroup, AccessLevel = wsAcl.Access.ToLower(), Type = wsAcl.IsGroup ? "group" : "user" });
                    }
                }
                if (fSecurityList.Any())
                {

                    var include = fSecurityList.Select(d => new { id = d.ID, access_level = d.AccessLevel, type = d.Type });
                    await RetryHelper(async () =>
                    {
                        return await clientApi.PatchSecurityFolder(_main.AccessToken, newDestFolder.Id, new
                        {
                            default_security = newDestFolder.DefaultSecurity == "inherit" ? "public" : newDestFolder.DefaultSecurity,
                            include
                        });
                    }, "Update folder security", throwException: true);
                    _log.Info($"Workspace: {clientMatterCode}. Folder: {templateFolderWrap.FolderFullPath}  security added");
                }
            }
            mappingWorkspaceWrap.AddFolderAndResetMapping(newDestFolder);
        }
        else if (folderType == 'tab')
        {
          Logger.getInstance().info(
            String.format('The "{0}" type is not supported yet.', new List<Object>{folderType});
          );
        }
        else if (folderType == 'search')
        {
          Logger.getInstance().info(
            String.format('The "{0}" type is not supported yet.', new List<Object>{folderType});
          );
        }
        else
        {
            throw new IManageExceptions.IManageApplicationException(
              String.format('Unknown folder type: {0}', new List<Object>{folderType});
            );
        }
    }

    Logger.getInstance().info('iManageWorkspacesHelper::compareFoldersAndUpdateByTemplate, END');
  }

  public class iManageWorkspaceResponse {
    IManageWWorkspace data;
  }

  public class iManageFoldersResponse {
    List<IManageWFolder> data;
    Integer total_count;
  }
  // public class iManageFoldersResponseResults {
  //   List<IManageWFolder> results;
  // }
}

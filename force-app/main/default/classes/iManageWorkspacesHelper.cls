public class iManageWorkspacesHelper {
  public static String SearchWorkspace(
    iManageSettings__c mc,
    iManageWrapper.ApiInfo apiData,
    IManageMappingHelper.IManageIFrameData link
  ) {
    Logger.getInstance()
      .info('iManageWorkspacesHelper::SearchWorkspace, start method');
    String libraries = mc?.iManage_Libraries__c == null ||
      mc.iManage_Libraries__c == ''
      ? apiData.library
      : mc.iManage_Libraries__c;
    Logger.getInstance()
      .info(
        'iManageWorkspacesHelper::SearchWorkspace, list libraries: ' + libraries
      );
    for (String library : libraries.split(';')) {
      try {
        Logger.getInstance()
          .info(
            'iManageWorkspacesHelper::SearchWorkspace, search into library: ' +
            library
          );
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
          Logger.getInstance()
            .info(
              'iManageWorkspacesHelper::SearchWorkspace, found result: ' +
              searchResult.data[0].id
            );
          return searchResult.data[0].id;
        }

        Logger.getInstance()
          .info(
            'iManageWorkspacesHelper::SearchWorkspace, not found into library: ' +
            library
          );
      } catch (Exception ex) {
        Logger.getInstance()
          .warn(
            'iManageWorkspacesHelper::SearchWorkspace, error searching into library: ' +
            library
          );
        // Not found workspace
      }
    }

    Logger.getInstance()
      .info('iManageWorkspacesHelper::SearchWorkspace, not found results');
    return '';
  }

  @AuraEnabled
  public static Boolean isWorkspaceWithNameExists(
    String name
  ){
    String logPrefix = 'iManageWorkspacesHelper::searchWorkspaceByName';
    Map<String, Object> params = new Map<String, Object>{
      'name' => name
    };
    Logger.getInstance()
      .info(logPrefix + ', start method. Params: ' + JSON.serialize(params));

    if (String.isBlank(name)) {
      return false;
    }

    LicenseService.CheckOrganizationLicense();

    try {
      iManageWrapper.ApiInfo apiInfo = iManageWrapper.GetApiInfo();
      iManageWrapper.iManageWorkspaceSearch searchResult = iManageWrapper.searchWorkspaceByName(
        apiInfo.customerId,
        apiInfo.library,
        name
      );

      return searchResult != null && searchResult.data != null && searchResult.data.size() > 0;
    } catch (Exception ex) {
      Logger.getInstance().error(ex, logPrefix);
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
  }

  @AuraEnabled
  public static Map<String, Object> getFoldersByWorkspace(
    String workspaceTemplate,
    Integer offset,
    Integer size
  ) {
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
  public static IManageWWorkspace findTemplateWorkspaceByName(
    String templateName,
    String libraryId) {
    String logPrefix = 'iManageWorkspacesHelper::findTemplateWorkspaceByName';
    Map<String, Object> params = new Map<String, Object>{
      'libraryId' => libraryId,
      'templateName' => templateName
    };
    Logger.getInstance()
      .info(logPrefix + ', start method. Params: ' + JSON.serialize(params));

    LicenseService.CheckOrganizationLicense();

    try {
      iManageWrapper.ApiInfo apiInfo = iManageWrapper.GetApiInfo();

      Integer offset = 0;
      Integer batchSize = 2000;
      iManageWrapper.iManageTemplatesResponse resp = iManageWrapper.searchTemplateWorkspace(
        apiInfo.customerId,
        libraryId,
        templateName,
        offset,
        batchSize
      );

      // first or default
      if (resp != null && resp.total_count > 0) {
        return resp.data.results[0];
      }
      return null;
    } catch (Exception ex) {
      Logger.getInstance().error(ex, logPrefix);
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
  }

  @AuraEnabled
  public static Map<String, String> createWorkspace(
    String custom1, // client alias
    String custom2, // matter alias
    String wsName,
    String workspaceTemplate // "libraryId::templateId"
  ) {
    Map<String, String> result = new Map<String, String> {
      'id' => null,
      'name' => null
    };
    String[] wsData = workspaceTemplate.split('::', 2);
    String libraryId = wsData[0];
    String wsTemplateId = wsData[1];

    String logPrefix = 'iManageWorkspacesHelper::createWorkspace';
    Map<String, Object> params = new Map<String, Object>{
      'custom1' => custom1,
      'custom2' => custom2,
      'wsName' => wsName,
      'workspaceTemplate' => workspaceTemplate
    };
    Logger.getInstance()
      .info(logPrefix + ', start method. Params: ' + JSON.serialize(params));

    LicenseService.CheckOrganizationLicense();

    try {
      Map<String, Object> generalSettings = ConfigurationHelper.getGeneralSettings();
      iManageWrapper.ApiInfo apiInfo = iManageWrapper.GetApiInfo();
      Logger.getInstance().info(logPrefix + ': Get template workspace');
      IManageWorkspaceWrap templateWorkspaceWrap = getWorkspaceTemplateWrap(
        wsTemplateId,
        libraryId
      );

      if (templateWorkspaceWrap == null) {
        throw new IManageExceptions.IManageApplicationException(
          'Workspace template not found. WS Template Id = ' + wsTemplateId
        );
      }

      // get list and reverse it
      List<IManageFolderWrap> templateFolders = new List<IManageFolderWrap>();
      List<IManageFolderWrap> tmpTemplateFolders = templateWorkspaceWrap.getFlatListAllFolders();
      for (Integer i = tmpTemplateFolders.size() - 1; i >= 0; i--) {
        templateFolders.add(tmpTemplateFolders[i]);
      }
      //

      Logger.getInstance()
        .info(
          'Found ' +
          String.valueOf(templateFolders.size()) +
          ' template folders.'
        );

      // clone templateWorkspaceWrap.wrapItem
      IManageWWorkspace templateWorkspace = ((IManageWWorkspace) templateWorkspaceWrap.wrapItem)
        .cloneThis();

      Logger.getInstance().Info('Create destination workspace...');
      templateWorkspace.custom1 = custom1;
      templateWorkspace.custom2 = custom2;
      templateWorkspace.Name = wsName;

      IManageWWorkspace sourceWorkspace = createWorkspaceApiCall(
        templateWorkspace,
        apiInfo.customerId,
        libraryId
      );
      Logger.getInstance().info('Workspace created.');

      result.put('id', sourceWorkspace.id);
      result.put('name', sourceWorkspace.name);

      Logger.getInstance().info('Compare folders and update by template.');

      IManageWorkspaceWrap sourceWorkspaceWrap = getWorkspaceContentWrap(
        sourceWorkspace.Id,
        libraryId,
        true,
        false
      );

      compareFoldersAndUpdateByTemplate(
        sourceWorkspaceWrap,
        templateFolders,
        apiInfo.customerId,
        libraryId,
        custom1,
        custom2
      );

      return result;
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
      new List<Object>{ customerId, libraryId }
    );
    String body =
      '{' +
      '"database": "' +
      libraryId +
      '",' +
      '"name": "' +
      templateWorkspace.name +
      '",' +
      '"custom1": "' +
      templateWorkspace.custom1 +
      '",' +
      '"custom2": "' +
      templateWorkspace.custom2 +
      '",' +
      '"default_security": "' +
      templateWorkspace.default_security +
      '",' +
      '"description":' +
      (templateWorkspace.description == null
        ? 'null'
        : '"' + templateWorkspace.description + '"') +
      ',' +
      '"is_declared":' +
      String.valueOf(templateWorkspace.is_declared).toLowerCase() +
      ',' +
      '"is_external_as_normal":' +
      String.valueOf(templateWorkspace.is_external_as_normal).toLowerCase() +
      ',' +
      '"subclass":' +
      (templateWorkspace.subclass == null
        ? 'null'
        : '"' + templateWorkspace.subclass + '"') + //',' +
      //'"profile":' + (templateWorkspace.profile == null ? 'null' : '{}') + //TODO: Serialize profile
      '}';

    Logger.getInstance()
      .info(
        'iManageWorkspacesHelper::createWorkspaceApiCall, query=' +
        query +
        '; body=' +
        body
      );
    String responseBody = IManageRequestHelper.Post(query, body);
    Logger.getInstance()
      .info(
        'iManageWorkspacesHelper::createWorkspaceApiCall, response=' +
        responseBody
      );
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
    if (onlyFolders == false) {
      throw new IManageExceptions.IManageApplicationException(
        String.format(
          'Not implemented. getWorkspaceContentWrap(... onlyFolders = {0} ...)',
          new List<Object>{ onlyFolders }
        )
      );
    }

    return getWorkspaceTemplateWrap(workspaceId, libraryId);
  }

  public static IManageWorkspaceWrap getWorkspaceTemplateWrap(
    String workspaceId,
    String libraryId
  ) {
    IManageWWorkspace workspace = getWorkspace(workspaceId, libraryId);
    List<IManageWFolder> folders = getAllFoldersByWorkspace(
      workspaceId,
      libraryId
    );

    return wrapWorkspaceContent(workspace, folders);
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
      .info('iManageWorkspacesHelper::getWorkspace, query=' + query);
    String responseBody = IManageRequestHelper.Get(query);
    Logger.getInstance()
      .info('iManageWorkspacesHelper::getWorkspace, response=' + responseBody);
    iManageWorkspaceResponse response = (iManageWorkspaceResponse) JSON.deserialize(
      responseBody,
      iManageWorkspaceResponse.class
    );

    return response == null ? null : response.data;
  }

  public static List<IManageWFolder> getAllFoldersByWorkspace(
    String workspaceId,
    String libraryId
  ) {
    Integer packageSize = 200;
    iManageWrapper.ApiInfo apiInfo = iManageWrapper.GetApiInfo();
    List<IManageWFolder> allFolders = new List<IManageWFolder>();

    for (Integer p = 0, total = 0; p == 0 || allFolders.size() < total; p++) {
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
        throw new IManageExceptions.IManageApplicationException(
          'Infinite loop'
        );
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
      .info('iManageWorkspacesHelper::getFoldersByWorkspace, query=' + query);
    String responseBody = IManageRequestHelper.Get(query);
    Logger.getInstance()
      .info(
        'iManageWorkspacesHelper::getFoldersByWorkspace, response=' +
        responseBody
      );

    iManageFoldersResponse response = (iManageFoldersResponse) JSON.deserialize(
      responseBody,
      iManageFoldersResponse.class
    );
    return response;
  }

  public static IManageWorkspaceWrap wrapWorkspaceContent(
    IManageWWorkspace sourceWorkspace,
    List<IManageWFolder> folders
  ) {
    IManageWorkspaceWrap workspaceWrap = new IManageWorkspaceWrap(
      sourceWorkspace
    );

    List<IManageFolderWrap> children = new List<IManageFolderWrap>();
    for (IManageWFolder folder : folders) {
      IManageFolderWrap f = new IManageFolderWrap(folder);
      f.workspaceId = sourceWorkspace.id;
      children.add(f);
    }
    workspaceWrap.children.addAll(children);

    for (Object x : workspaceWrap.children) {
      IManageFolderWrap folderWrap = (IManageFolderWrap) x;
      mappingFolders(folderWrap, folders);
    }
    return workspaceWrap;
  }

  @TestVisible
  private static void mappingFolders(
    IManageFolderWrap folderWrap,
    List<IManageWFolder> folders
  ) {
    List<IManageFolderWrap> children = new List<IManageFolderWrap>();
    for (IManageWFolder folder : folders) {
      if (folder.parent_id == ((IManageWFolder) folderWrap.wrapItem).id) {
        IManageFolderWrap fw = new IManageFolderWrap(folder);
        fw.parentFolder = folderWrap;
        fw.workspaceId = folderWrap.workspaceId;
        children.add(fw);
      }
    }
    folderWrap.children.addAll(children);

    for (Object x : folderWrap.children) {
      IManageFolderWrap fw = (IManageFolderWrap) x;
      mappingFolders(fw, folders);
    }
  }

  public static Void compareFoldersAndUpdateByTemplate(
    IManageWorkspaceWrap mappingWorkspaceWrap,
    List<IManageFolderWrap> templateFolders,
    String customerId,
    String libraryId,
    String clientId,
    String matterId
  ) {
    Logger.getInstance()
      .info(
        'iManageWorkspacesHelper::compareFoldersAndUpdateByTemplate, START'
      );
    String clientMatterCode = String.format(
      '{0}.{1}',
      new List<Object>{ clientId, matterId }
    );
    List<IManageFolderWrap> workspaceFolders = mappingWorkspaceWrap.getFlatListAllFolders();

    List<Map<String, Object>> mappedTemplateFolders = new List<Map<String, Object>>();
    for (IManageFolderWrap tf : templateFolders) {
      IManageFolderWrap fw = null;
      // find first or default
      for (IManageFolderWrap wsFolder : workspaceFolders) {
        if (
          ((IManageWFolder) wsFolder.wrapItem)
            .folder_type.equalsIgnoreCase(
              ((IManageWFolder) tf.wrapItem).folder_type
            ) && wsFolder.folderFullPath.equalsIgnoreCase(tf.folderFullPath)
        ) {
          fw = wsFolder;
          break;
        }
      }
      Map<String, Object> mappedTemplateFoldersItem = new Map<String, Object>{
        'item1' => tf,
        'item2' => fw
      };

      // add to mappedTemplateFolders and sort by folderFullPath.length()
      Integer mappedTemplateFoldersSize = mappedTemplateFolders.size();
      if (mappedTemplateFoldersSize == 0) {
        mappedTemplateFolders.add(mappedTemplateFoldersItem);
      } else {
        for (Integer i = 0; i < mappedTemplateFoldersSize; i++) {
          Integer currentItemLength = ((IManageFolderWrap) mappedTemplateFolders.get(
                i
              )
              .get('item1'))
            .folderFullPath.length();
          Integer newItemLength = ((IManageFolderWrap) mappedTemplateFoldersItem.get(
              'item1'
            ))
            .folderFullPath.length();
          if (newItemLength <= currentItemLength) {
            mappedTemplateFolders.add(i, mappedTemplateFoldersItem);
            break;
          } else if (i == mappedTemplateFoldersSize - 1) {
            mappedTemplateFolders.add(mappedTemplateFoldersItem);
          }
        }
      }
    }

    //var dbFoldersSecurity = await _dbClient.GetFoldersSecurityRows(matterRow.UID);
    //create new folders
    for (Map<String, Object> mtfs : mappedTemplateFolders) {
      if (mtfs.get('item2') != null) {
        continue;
      }
      IManageFolderWrap templateFolderWrap = (IManageFolderWrap) mtfs.get(
        'item1'
      );

      workspaceFolders = mappingWorkspaceWrap.getFlatListAllFolders();

      IManageWFolder parentDestFolder = null;
      // first or default
      for (IManageFolderWrap wf : workspaceFolders) {
        IManageFolderWrap tfwParentFolder = templateFolderWrap.parentFolder;
        if (
          wf.folderFullPath.equalsIgnoreCase(
            tfwParentFolder == null ? null : tfwParentFolder.folderFullPath
          )
        ) {
          parentDestFolder = (IManageWFolder) wf.wrapItem;
          break;
        }
      }

      String parentDestFolderId = parentDestFolder == null
        ? null
        : parentDestFolder.id;
      Boolean parentIsTab =
        parentDestFolder != null &&
        parentDestFolder.folder_type == 'tab';

      String folderType = ((IManageWFolder) templateFolderWrap.wrapItem)
        .folder_type;
      if (folderType == 'regular') {
        IManageWFolder tf = getTemplateWFolder(
          ((IManageWFolder) templateFolderWrap.wrapItem).id,
          customerId,
          libraryId
        );

        if (tf.IsOptional == true) {
          Logger.getInstance()
            .info(
              String.format(
                'Workspace: {0}. Optional Folder: {1} add ignored.',
                new List<Object>{
                  clientMatterCode,
                  templateFolderWrap.folderFullPath
                }
              )
            );
          continue;
        }

        if (
          templateFolderWrap.parentFolder != null &&
          parentDestFolder == null
        ) {
          Logger.getInstance()
            .info(
              String.format(
                'Workspace: {0}. Optional Folder: {1} add ignored because the parent folder is optional.',
                new List<Object>{
                  clientMatterCode,
                  templateFolderWrap.folderFullPath
                }
              )
            );
          continue;
        }

        // TODO: Profiles not implemented.
        tf = mappingProfileWorkspaceValues((IManageWWorkspace)mappingWorkspaceWrap.wrapItem, tf);

        Boolean needEmail = String.isNotBlank(tf.email);
        //tf.Name = BuildFolderName(tf.Name, matterRow, folderVariableMatrixRows);

        Logger.getInstance()
          .info(
            String.format(
              'Create folder {0}-{1}',
              new List<Object>{
                clientMatterCode,
                templateFolderWrap.folderFullPath
              }
            )
          );
        IManageWFolder newDestFolder = createFolder(
          ((IManageWWorkspace) mappingWorkspaceWrap.wrapItem).id,
          tf,
          parentDestFolderId,
          parentIsTab,
          null,
          customerId,
          libraryId
        );

        Logger.getInstance().info('Patch folder name-value-pair');
        patchNameValuePair(
          'folders',
          newDestFolder.id,
          customerId,
          libraryId,
          new Map<String, Object>{ 'folderTemplateId' => tf.id }
        );

        if (needEmail == true) {
          String email = String.format(
            '{0}.{1}',
            new List<Object>{
              newDestFolder.name.replace(' ', '_'),
              newDestFolder.id.Split('!')[1]
            }
          );
          Logger.getInstance()
            .info(
              String.format(
                'Patch Folder: {0} email: {1}',
                new List<Object>{ templateFolderWrap.folderFullPath, email }
              )
            );
          patchFolder(
            newDestFolder.id,
            customerId,
            libraryId,
            new Map<String, Object>{ 'email' => email }
          );
        }

        Logger.getInstance()
          .info(
            String.format(
              'Workspace: {0}. Folder: {1} added',
              new List<Object>{
                clientMatterCode,
                templateFolderWrap.folderFullPath
              }
            )
          );

        List<Object> dbFolderSecurity = new List<Object>(); // dbFoldersSecurity.Where(fs => templateFolderWrap.FolderFullPath.ToLower().Replace("/", "\\") == fs.FolderName.ToLower()).ToList();

        if (
          newDestFolder.default_security != 'inherit' ||
          dbFolderSecurity.size() > 0
        ) {
          Logger.getInstance().info('Get template folder security');
          List<IManageWSecurity> fSecurityList = getFolderACL(
            ((IManageWFolder) templateFolderWrap.wrapItem).id,
            customerId,
            libraryId
          );

          for (Object wsAcl : dbFolderSecurity) {
            // Not implemented

            // var sourceFAcl = fSecurityList.FirstOrDefault(a => a.ID == wsAcl.UserOrGroup);
            // if (sourceFAcl == null)
            // {
            //     fSecurityList.Add(new WSecurity { ID = wsAcl.UserOrGroup, AccessLevel = wsAcl.Access.ToLower(), Type = wsAcl.IsGroup ? "group" : "user" });
            // }
          }
          if (fSecurityList.size() > 0) {
            Logger.getInstance().info('Update folder security');
            List<Map<String, Object>> include = new List<Map<String, Object>>();
            for (IManageWSecurity d : fSecurityList) {
              include.add(
                new Map<String, Object>{
                  'id' => d.id,
                  'access_level' => d.access_level,
                  'type' => d.type
                }
              );
            }

            patchSecurityFolder(
              newDestFolder.id,
              customerId,
              libraryId,
              include
            );

            Logger.getInstance()
              .info(
                String.format(
                  'Workspace: {0}. Folder: {1} security added',
                  new List<Object>{
                    clientMatterCode,
                    templateFolderWrap.folderFullPath
                  }
                )
              );
          }
        }
        mappingWorkspaceWrap.addFolderAndResetMapping(newDestFolder);
      } else if (folderType == 'tab') {
        createTabFolder(
          customerId,
          libraryId,
          clientMatterCode,
          templateFolderWrap,
          parentDestFolder,
          mappingWorkspaceWrap
        );
      } else if (folderType == 'search') {
        Logger.getInstance()
          .info(
            String.format(
              'The "{0}" type is not supported yet.',
              new List<Object>{ folderType }
            )
          );
      } else {
        throw new IManageExceptions.IManageApplicationException(
          String.format(
            'Unknown folder type: {0}',
            new List<Object>{ folderType }
          )
        );
      }
    }

    Logger.getInstance()
      .info('iManageWorkspacesHelper::compareFoldersAndUpdateByTemplate, END');
  }

  public static IManageWFolder getTemplateWFolder(
    String folderId,
    String customerId,
    String libraryId
  ) {
    Map<String, String> kvPair = getNameValuePair(
      'folders',
      folderId,
      customerId,
      libraryId
    );
    IManageWFolder folder = getFolderById(folderId, customerId, libraryId);
    if (kvPair.containsKey('IMCC_IsOptional')) {
      folder.IsOptional = Boolean.valueOf(kvPair.get('IMCC_IsOptional'));
    }
    return folder;
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
      .info('iManageWorkspacesHelper::getFolderById, query=' + query);
    String responseBody = IManageRequestHelper.Get(query);
    Logger.getInstance()
      .info('iManageWorkspacesHelper::getFolderById, response=' + responseBody);

    iManageFolderResponse response = (iManageFolderResponse) JSON.deserialize(
      responseBody,
      iManageFolderResponse.class
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
        'iManageWorkspacesHelper::patchFolder, query=' +
        query +
        '; body=' +
        body
      );
    String responseBody = IManageRequestHelper.Patch(query, body);
    Logger.getInstance()
      .info('iManageWorkspacesHelper::patchFolder, response=' + responseBody);

    Object response = JSON.deserializeUntyped(responseBody);
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
      .info('iManageWorkspacesHelper::getFolderACL, query=' + query);
    String responseBody = IManageRequestHelper.Get(query);
    Logger.getInstance()
      .info('iManageWorkspacesHelper::getFolderACL, response=' + responseBody);

    iManageFolderSecurityResponse response = (iManageFolderSecurityResponse) JSON.deserialize(
      responseBody,
      iManageFolderSecurityResponse.class
    );

    return response.data;
  }

  public static List<IManageWSecurity> patchSecurityFolder(
    String id,
    String customerId,
    String libraryId,
    Object data
  ) {
    String query = String.format(
      '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}/security',
      new List<Object>{ customerId, libraryId, id }
    );
    String body = JSON.serialize(data, true);

    Logger.getInstance()
      .info(
        'iManageWorkspacesHelper::patchSecurityFolder, query=' +
        query +
        '; body=' +
        body
      );
    String responseBody = IManageRequestHelper.Post(query, body);
    Logger.getInstance()
      .info(
        'iManageWorkspacesHelper::patchSecurityFolder, response=' + responseBody
      );
    System.debug(responseBody);

    iManageFolderSecurityResponse response = (iManageFolderSecurityResponse) JSON.deserialize(
      responseBody,
      iManageFolderSecurityResponse.class
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
      .info('iManageWorkspacesHelper::getNameValuePair, query=' + query);
    String responseBody = IManageRequestHelper.Get(query);
    Logger.getInstance()
      .info(
        'iManageWorkspacesHelper::getNameValuePair, response=' + responseBody
      );

    iManageNameValuePairResponse response = (iManageNameValuePairResponse) JSON.deserialize(
      responseBody,
      iManageNameValuePairResponse.class
    );
    return response.data;
  }

  public static Object patchNameValuePair(
    String objectName,
    String objectId,
    String customerId,
    String libraryId,
    Map<String, Object> data
  ) {
    String query = String.format(
      '/work/api/v2/customers/{0}/libraries/{1}/{2}/{3}',
      new List<Object>{ customerId, libraryId, objectName, objectId }
    );

    String body = JSON.serialize(data, true);
    Logger.getInstance()
      .info(
        'iManageWorkspacesHelper::patchNameValuePair, query=' +
        query +
        '; body=' +
        body
      );
    String responseBody = IManageRequestHelper.Patch(query, body);
    Logger.getInstance()
      .info(
        'iManageWorkspacesHelper::patchNameValuePair, response=' + responseBody
      );

    Object response = JSON.deserializeUntyped(responseBody);
    return response;
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

    String body = JSON.serialize(reqBody, true);

    Logger.getInstance()
      .info(
        'iManageWorkspacesHelper::createFolder, query=' +
        query +
        '; body=' +
        body
      );
    String responseBody = IManageRequestHelper.Post(query, body);
    Logger.getInstance()
      .info('iManageWorkspacesHelper::createFolder, response=' + responseBody);
    System.debug(responseBody);

    iManageFolderResponse response = (iManageFolderResponse) JSON.deserialize(
      responseBody,
      iManageFolderResponse.class
    );

    return response.data;
  }

  @TestVisible
  private static void createRegularFolder(
    String customerId,
    String libraryId,
    String clientMatterCode,
    IManageFolderWrap templateFolderWrap) {
      // TODO: move code from the compareFoldersAndUpdateByTemplate method here
  }

  @TestVisible
  private static void createTabFolder(
    String customerId,
    String libraryId,
    String clientMatterCode,
    IManageFolderWrap templateFolderWrap,
    IManageWFolder parentDestFolder,
    IManageWorkspaceWrap mappingWorkspaceWrap
  ) {
    IManageWFolder tf = getTemplateWFolder(
      ((IManageWFolder) templateFolderWrap.wrapItem).id,
      customerId,
      libraryId
    );
    if (tf.IsOptional == true) {
      Logger.getInstance()
        .info(
          String.format(
            'Workspace: {0}. Optional Tab: {1} add ignored.',
            new List<Object>{
              clientMatterCode,
              templateFolderWrap.folderFullPath
            }
          )
        );
      return;
    }

    if (
          templateFolderWrap.parentFolder != null &&
          parentDestFolder == null
        ) {
      Logger.getInstance()
        .info(
          String.format(
            'Workspace: {0}. Optional Folder: {1} add ignored because the parent folder is optional.',
            new List<Object>{
              clientMatterCode,
              templateFolderWrap.folderFullPath
            }
          )
        );
        return;
    }

        tf = MappingProfileWorkspaceValues((IManageWWorkspace)mappingWorkspaceWrap.wrapItem, tf);
        //tf.Name = BuildFolderName(tf.Name, matterRow, folderVariableMatrixRows);
        // var newDestTab = await RetryHelper(async () =>
        //         await clientApi.CreateTabAsync(tf, mappingWorkspaceWrap.WrapItem.Id,
        //                                                   _main.AccessToken),
        //                                                   $"Create tab {clientMatterCode}-{templateFolderWrap.FolderFullPath}", throwException: true);

        // await RetryHelper(async () =>
        //   await clientApi.PatchNameValuePair("folders", newDestTab.Id, _main.AccessToken, new
        //   {
        //       FolderTemplateId = tf.Id
        //   }), "Patch folder name-value-pair", throwException: true);

        // _log.Info($"Workspace: {clientMatterCode}. Tab: {templateFolderWrap.FolderFullPath}  added");
        // var dbFolderSecurity = dbFoldersSecurity
        //       .Where(fs => templateFolderWrap.FolderFullPath.ToLower().Replace("/", "\\") == fs.FolderName.ToLower()).ToList();
        // if (newDestTab.DefaultSecurity != "inherit" || dbFolderSecurity.Any())
        // {
        //     var templateWsSecurity = await RetryHelper(async () =>
        //     await clientApi.GetTabACL(_main.AccessToken, templateFolderWrap.WrapItem.Id), "Get template tab security", throwException: true);
        //     var fSecurityList = templateWsSecurity.Data.ToList();
        //     foreach (var wsAcl in dbFolderSecurity)
        //     {
        //         var sourceFAcl = fSecurityList.FirstOrDefault(a => a.ID == wsAcl.UserOrGroup);
        //         if (sourceFAcl == null)
        //         {
        //             fSecurityList.Add(new WSecurity { ID = wsAcl.UserOrGroup, AccessLevel = wsAcl.Access.ToLower(), Type = wsAcl.IsGroup ? "group" : "user" });
        //         }
        //     }
        //     if (fSecurityList.Any())
        //     {

        //         var include = fSecurityList.Select(d => new { id = d.ID, access_level = d.AccessLevel, type = d.Type });
        //         await RetryHelper(async () =>
        //         {
        //             return await clientApi.PatchSecurityTab(_main.AccessToken, newDestTab.Id, new
        //             {
        //                 default_security = newDestTab.DefaultSecurity == "inherit" ? "public" : newDestTab.DefaultSecurity,
        //                 include
        //             });
        //         }, "Update tab security", throwException: true);
        //         _log.Info($"Workspace: {clientMatterCode}. Tab: {templateFolderWrap.FolderFullPath}  security added");
        //     }
        // }
        // mappingWorkspaceWrap.AddFolderAndResetMapping(newDestTab);
  }

  @TestVisible
  private static IManageWFolder mappingProfileWorkspaceValues(
    IManageWWorkspace workspace,
    IManageWFolder templateFolder
  )
  {
      if (templateFolder.profile == null)
          return templateFolder;

      String mapTemplate = '%WORKSPACE_VALUE%';
      // var templateFolderProps = templateFolder.Profile.GetType()
      //               .GetProperties(System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Instance);
      // var workspaceProps = workspace.GetType()
      //               .GetProperties(System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Instance);
      // foreach (var templateProp in templateFolderProps)
      // {
      //     var value = templateProp.GetValue(templateFolder.Profile);
      //     if (value?.ToString() == mapTemplate)
      //     {
      //         var propName = templateProp.Name;
      //         var workspaceProp = workspaceProps.FirstOrDefault(p => p.Name == propName);
      //         if (workspaceProp != null)
      //         {
      //             templateProp.SetValue(templateFolder.Profile, workspaceProp.GetValue(workspace));
      //         }

      //     }
      // }
      return templateFolder;
  }

  public class iManageWorkspaceResponse {
    IManageWWorkspace data;
  }

  public class iManageFoldersResponse {
    List<IManageWFolder> data;
    Integer total_count;
  }

  public class iManageFolderResponse {
    IManageWFolder data;
  }

  public class iManageFolderSecurityResponse {
    List<IManageWSecurity> data;
    String default_security;
  }

  public class iManageNameValuePairResponse {
    Map<String, String> data;
  }
  // public class iManageFoldersResponseResults {
  //   List<IManageWFolder> results;
  // }
}

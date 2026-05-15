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

     if (mc.Mapping_LibraryField__c != null && mc.Mapping_LibraryField__c != '' && link.Library != null && link.Library != '' && link.Library != 'Other') 
      libraries = link.Library;

    Logger.getInstance()
      .info(
        'iManageWorkspacesHelper::SearchWorkspace, list libraries: ' + libraries
      );

    String clientId = link.ClientId;
    if(mc.iManage_UseOnlyCustom2__c) {
      clientId = null;
    }

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
          clientId,
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
  public static Map<String, String> findEntityWorkspaceInCache(Id entityId) {
    String logPrefix = 'iManageWorkspacesHelper::findEntityWorkspaceInCache';
    try {
      Map<String, String> result = new Map<String, String>(); // <-- library, workspaceId
      Map<String, Object> params = new Map<String, Object>{
        'entityId' => entityId
      };
      Logger.getInstance()
        .info(logPrefix + ', start method. Params: ' + JSON.serialize(params));

      Logger.getInstance()
        .info(
          logPrefix +
          ', Find information in the "IManage_WS_to_Entity_Mapping__c"'
        );

      List<IManage_WS_to_Entity_Mapping__c> records = [
        SELECT Id, EntityId__c, iManage_WS_Id__c, iManage_Library__c
        FROM IManage_WS_to_Entity_Mapping__c
        WHERE EntityId__c = :entityId
      ];
      Logger.getInstance()
        .info(
          logPrefix +
          ', Found: ' +
          records.size() +
          ' record(s) in the IManage_WS_to_Entity_Mapping__c'
        );

      if (records.size() > 0) {
        for (IManage_WS_to_Entity_Mapping__c item : records) {
          result.put(item.iManage_Library__c, item.iManage_WS_Id__c);
        }
      }

      Logger.getInstance()
        .info(logPrefix + ', Result = ' + JSON.serialize(result));

      return result;
    } catch (Exception ex) {
      Logger.getInstance().error(ex, logPrefix);
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
  }

  @AuraEnabled
  public static Map<String, String> findEntityWorkspaceInImanageAndPutToCache(
    Id entityId
  ) {
    String logPrefix = 'iManageWorkspacesHelper::findEntityWorkspaceInImanageAndPutToCache';
    try {
      Map<String, String> result = new Map<String, String>(); // <-- library, workspaceId
      Map<String, Object> params = new Map<String, Object>{
        'entityId' => entityId
      };
      Logger.getInstance()
        .info(logPrefix + ', start method. Params: ' + JSON.serialize(params));

      // Search in iManage
      Logger.getInstance().info(logPrefix + ', Find information in iManage');

      iManageSettings__c imSettings = iManageSettings__c.getOrgDefaults();

      IManageMappingHelper.IManageIFrameData imMapping = IManageMappingHelper.getMappingData(
        entityId
      );

      String clientId = imMapping.ClientId;
      if(imSettings.Mapping_LibraryField__c != null && imSettings.Mapping_LibraryField__c != '')   {
        clientId = null;
      }

      iManageWrapper.ApiInfo apiInfo = iManageWrapper.GetApiInfo();

      Set<String> libraries = new Set<String>();
      libraries.add(apiInfo.library);
      if (String.isNotBlank(imSettings?.iManage_Libraries__c)) {
        libraries.addAll(imSettings.iManage_Libraries__c.split(';'));
      }

      for (String library : libraries) {
        iManageWrapper.iManageWorkspaceSearch searchResult = iManageWrapper.SearchWorkspace(
          apiInfo.customerId,
          library,
          imSettings.ClientField__c,
          clientId,
          imSettings.MatterField__c,
          imMapping.MatterId
        );
        if (searchResult.error == null && searchResult.data != null) {
          for (IManageWWorkspace ws : searchResult.data) {
            Map<String, Object> wsMap = (Map<String, Object>) JSON.deserializeUntyped(
              JSON.serialize(ws)
            );
            // Check whether the results really match the conditions.
            // Because if you specify the wrong parameters, iManage will return all workspaces.
            if (
              wsMap.containsKey(imSettings.ClientField__c) &&
              wsMap.containsKey(imSettings.MatterField__c) &&
              wsMap.get(imSettings.ClientField__c) == imMapping.ClientId &&
              wsMap.get(imSettings.MatterField__c) == imMapping.MatterId
            ) {
              result.put(library, String.valueOf(ws.id));
            }
          }
        }
      }

      Logger.getInstance()
        .info(logPrefix + ', Result = ' + JSON.serialize(result));

      // save to IManage_WS_to_Entity_Mapping__c
      try {
        for (String lib : result.keySet()) {
          updateEntityToWsMapping(
            result.get(lib), // workspaceId
            lib,
            String.valueOf(entityId),
            false, // autoCreated
            'IM' // source
          );
        }
      } catch (Exception ex) {
        Logger.getInstance()
          .error(
            ex,
            logPrefix +
            ', saving to IManage_WS_to_Entity_Mapping__c, data = ' +
            JSON.serialize(result)
          );
      }

      return result;
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
    String libraryId
  ) {
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
  public static void createCustomFiledsIfNotExist(
    String entityId,
    String libraryId
  ) {
    String logPrefix = 'iManageWorkspacesHelper::createCustomFiledsIfNotExist';

    try {
      Map<String, Object> params = new Map<String, Object>{
        'entityId' => entityId,
        'libraryId' => libraryId
      };

      Logger.getInstance()
        .info(logPrefix + ', start method. Params: ' + JSON.serialize(params));

      LicenseService.CheckOrganizationLicense();
      iManageSettings__c mSettings = iManageSettings__c.getOrgDefaults();
      iManageWrapper.ApiInfo apiInfo = iManageWrapper.GetApiInfo();

      Map<String, Object> mappingData = IManageMappingHelper.getIManageDataFromSObject(
        entityId
      );
      String custom1Value = String.valueOf(mappingData.get('clientId'));
      String custom1Desc = String.valueOf(mappingData.get('clientName'));
      String custom2Value = String.valueOf(mappingData.get('matterId'));
      String custom2Desc = String.valueOf(mappingData.get('matterName'));

      if (String.isBlank(custom1Value)) {
        throw new IManageExceptions.IManageApplicationException(
          'The "' +
          mSettings.Mapping_ClientIdField__c +
          '" field is not populated.'
        );
      }

      if (String.isBlank(custom1Desc)) {
        throw new IManageExceptions.IManageApplicationException(
          'The "' +
          mSettings.Mapping_ClientNameField__c +
          '" field is not populated.'
        );
      }

      if (String.isBlank(custom2Value)) {
        throw new IManageExceptions.IManageApplicationException(
          'The "' +
          mSettings.Mapping_MatterIdField__c +
          '" field is not populated.'
        );
      }

      if (String.isBlank(custom2Desc)) {
        throw new IManageExceptions.IManageApplicationException(
          'The "' +
          mSettings.Mapping_ClientNameField__c +
          '" field is not populated.'
        );
      }
      // Custom 1

      Map<String, Object> cust1GetResponse = iManageWrapper.getCustomProperty(
        custom1Value,
        mSettings.ClientField__c,
        null, // parentAlias
        apiInfo.customerId,
        libraryId
      );

      if (cust1GetResponse.containsKey('error')) {
        Map<String, Object> cust1GetError = (Map<String, Object>) cust1GetResponse.get(
          'error'
        );
        if (String.valueOf(cust1GetError.get('code')) == 'NRC_NO_RECORD') {
          Logger.getInstance()
            .info(
              logPrefix +
              ': custom1 does not exist in iManage. Try to create. Alias = ' +
              custom1Value
            );

          Map<String, Object> cust1CreateResponse = iManageWrapper.createCustomProperty(
            mSettings.ClientField__c,
            custom1Value,
            custom1Desc,
            true, // enabled,
            false, //Boolean hipaa,
            null, // parentAlias,
            apiInfo.customerId,
            libraryId
          );
          if (cust1CreateResponse.containsKey('error')) {
            throw new IManageExceptions.IManageApplicationException(
              String.valueOf(cust1CreateResponse.get('code_message'))
            );
          } else {
            Logger.getInstance().info(logPrefix + ': custom1 created');
          }
        } else {
          throw new IManageExceptions.IManageApplicationException(
            String.valueOf(cust1GetError.get('code_message'))
          );
        }
      }

      // Custom 2
      Map<String, Object> cust2GetResponse = iManageWrapper.getCustomProperty(
        custom2Value,
        mSettings.MatterField__c,
        custom1Value, // parentAlias
        apiInfo.customerId,
        libraryId
      );

      if (cust2GetResponse.containsKey('error')) {
        Map<String, Object> cust2GetError = (Map<String, Object>) cust2GetResponse.get(
          'error'
        );
        if (String.valueOf(cust2GetError.get('code')) == 'NRC_NO_RECORD') {
          Logger.getInstance()
            .info(
              logPrefix +
              ': custom2 does not exist in iManage. Try to create. Alias = ' +
              custom2Value
            );

          Map<String, Object> cust2CreateResponse = iManageWrapper.createCustomProperty(
            mSettings.MatterField__c,
            custom2Value,
            custom2Desc,
            true, // enabled,
            false, // hipaa,
            custom1Value, // parentAlias,
            apiInfo.customerId,
            libraryId
          );
          if (cust2CreateResponse.containsKey('error')) {
            throw new IManageExceptions.IManageApplicationException(
              String.valueOf(cust2CreateResponse.get('code_message'))
            );
          } else {
            Logger.getInstance().info(logPrefix + ': custom2 created');
          }
        } else {
          throw new IManageExceptions.IManageApplicationException(
            String.valueOf(cust2GetError.get('code_message'))
          );
        }
      }
      else {
        String oldDescription = '';
        if (cust2GetResponse.containsKey('data')) {
          Map<String, Object> cust2Data = (Map<String, Object>) cust2GetResponse.get(
            'data'
          );
          oldDescription = String.valueOf(cust2Data.get('description'));
        }

        if (oldDescription != custom2Desc) {
          Map<String, Object> cust2PatchResponse = iManageWrapper.patchCustomProperty(
            mSettings.MatterField__c,
            custom2Value,
            custom2Desc,
            custom1Value, // parentAlias,
            apiInfo.customerId,
            libraryId
          );
        }
      }


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
    String logPrefix = 'iManageWorkspacesHelper::createWorkspace';
    try {
      Map<String, String> result = new Map<String, String>{
        'id' => null,
        'name' => null
      };

      Map<String, Object> params = new Map<String, Object>{
        'custom1' => custom1,
        'custom2' => custom2,
        'wsName' => wsName,
        'workspaceTemplate' => workspaceTemplate
      };
      Logger.getInstance()
        .info(logPrefix + ', start method. Params: ' + JSON.serialize(params));

      String[] wsData = workspaceTemplate.split('::', 2);
      String libraryId = wsData[0];
      String wsTemplateId = wsData[1];

      LicenseService.CheckOrganizationLicense();

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

      // System.debug('***** templateWorkspaceWrap = ' + JSON.serialize(templateWorkspaceWrap));

      // get list and reverse it
      List<IManageFolderWrap> templateFolders = new List<IManageFolderWrap>();
      List<IManageFolderWrap> tmpTemplateFolders = templateWorkspaceWrap.getFlatListAllFolders();

      // System.debug('***** tmpTemplateFolders = ' + JSON.serialize(tmpTemplateFolders));

      for (Integer i = tmpTemplateFolders.size() - 1; i >= 0; i--) {
        templateFolders.add(tmpTemplateFolders[i]);
      }

      // System.debug('***** templateFolders (reversed tmpTemplateFolders) = ' + JSON.serialize(templateFolders));
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
      // System.debug('***** templateWorkspace = ' + JSON.serialize(templateWorkspace));

      IManageWWorkspace sourceWorkspace = iManageWrapper.createWorkspaceApiCall(
        templateWorkspace,
        apiInfo.customerId,
        libraryId
      );
      Logger.getInstance().info('Workspace created.');

      Logger.getInstance().info('Patch workspace name-value-pair');
      iManageWrapper.patchNameValuePair(
        'workspaces',
        sourceWorkspace.Id,
        apiInfo.customerId,
        libraryId,
        new Map<String, Object>{ 'templateId' => templateWorkspace.Id }
      );

      result.put('id', sourceWorkspace.id);
      result.put('name', sourceWorkspace.name);
      result.put('database', sourceWorkspace.database);

      Logger.getInstance().info('Compare folders and update by template.');

      IManageWorkspaceWrap sourceWorkspaceWrap = getWorkspaceContentWrap(
        sourceWorkspace.Id,
        libraryId,
        true,
        false
      );
      // System.debug('***** sourceWorkspaceWrap = ' + JSON.serialize(sourceWorkspaceWrap));

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

  @AuraEnabled
  public static void updateWorkspace(
    String workspaceId,
    String library,
    String wsName,
    String client,
    String matter
  ) {
    LicenseService.CheckOrganizationLicense();
    String logPrefix = 'iManageWorkspacesHelper::updateWorkspace';
    try {
      // Log parameters
      Map<String, Object> params = new Map<String, Object>{
        'workspaceId' => workspaceId,
        'library' => library,
        'wsName' => wsName,
        'client' => client,
        'matter' => matter
      };

      Logger.getInstance()
        .info(logPrefix + ', start method. Params: ' + JSON.serialize(params));

      iManageSettings__c imSettings = iManageSettings__c.getOrgDefaults();
      iManageWrapper.ApiInfo apiInfo = iManageWrapper.GetApiInfo();
      String customerId = apiInfo.customerId;

      IManageWWorkspace sourceWorkspace = iManageWrapper.getWorkspace(
        workspaceId,
        library
      );

      if (sourceWorkspace == null) {
        throw new IManageExceptions.IManageApplicationException(
          String.format(
            'Workspace not found. Id = {0}, Library = {1}',
            new List<Object>{ workspaceId, library }
          )
        );
      }

      Map<String, String> kvPair = iManageWrapper.getNameValuePair(
        'workspaces',
        sourceWorkspace.Id,
        customerId,
        library
      );

      String wsTemplateId = kvPair.get('templateId');

      if (wsTemplateId == null) {
        throw new IManageExceptions.IManageApplicationException(
          'Workspace does not contain "templateId" in its properties (the "name-value-pairs" collection). Ws Id = ' +
          sourceWorkspace.Id
        );
      }

      IManageWorkspaceWrap templateWorkspaceWrap = getWorkspaceTemplateWrap(
        wsTemplateId,
        library
      );

      // get list and reverse it
      List<IManageFolderWrap> templateFolders = new List<IManageFolderWrap>();
      List<IManageFolderWrap> tmpTemplateFolders = templateWorkspaceWrap.getFlatListAllFolders();

      // System.debug('***** tmpTemplateFolders = ' + JSON.serialize(tmpTemplateFolders));

      for (Integer i = tmpTemplateFolders.size() - 1; i >= 0; i--) {
        templateFolders.add(tmpTemplateFolders[i]);
      }
      Logger.getInstance()
        .info('Found ' + templateFolders.size() + ' template folders');

      if (templateWorkspaceWrap == null) {
        throw new IManageExceptions.IManageApplicationException(
          'Workspace template not found. WS Template Id = ' + wsTemplateId
        );
      }

      // clone templateWorkspaceWrap.wrapItem
      IManageWWorkspace templateWorkspace = ((IManageWWorkspace) templateWorkspaceWrap.wrapItem)
        .cloneThis();

      //update workspace
      Map<String, Object> wsMap = (Map<String, Object>) JSON.deserializeUntyped(
        JSON.serialize(sourceWorkspace)
      );

      Map<String, Object> patchData = new Map<String, Object>();
      if (wsMap.size() == 0) {
        Logger.getInstance()
          .error(logPrefix + ', sourceWorkspace variable has no data');
        return;
      }

      if (String.isNotBlank(wsName) && (sourceWorkspace.name != wsName)) {
        patchData.put('name', wsName);
      }

      if (
        String.isNotBlank(client) &&
        (wsMap.get(imSettings.ClientField__c) != client)
      ) {
        patchData.put(imSettings.ClientField__c, client); // custom1
      }

      if (
        String.isNotBlank(matter) &&
        (wsMap.get(imSettings.MatterField__c) != matter)
      ) {
        patchData.put(imSettings.MatterField__c, matter); // custom2
      }

      Logger.getInstance().info(logPrefix + ', patchData = ' + patchData);

      if (patchData.size() > 0) {
        Logger.getInstance()
          .Info(
            logPrefix +
            '. Patch destination workspace (workspaceId = ' +
            workspaceId +
            ')...'
          );
        sourceWorkspace = iManageWrapper.patchWorkspaceApiCall(
          sourceWorkspace.Id,
          patchData,
          customerId,
          library
        );
      }

      Logger.getInstance().info('Patch workspace name-value-pair');
      iManageWrapper.patchNameValuePair(
        'workspaces',
        sourceWorkspace.Id,
        customerId,
        library,
        new Map<String, Object>{ 'templateId' => templateWorkspace.id }
      );

      if (sourceWorkspace.default_security != 'inherit') {
        Logger.getInstance().info('Get WS template security');
        iManageWrapper.iManageSecurityResponse wsTemplateSecurityResp = iManageWrapper.getWorkspaceACL(
          wsTemplateId,
          customerId,
          library
        );

        Logger.getInstance().info('Get WS security');
        iManageWrapper.iManageSecurityResponse wsSecurityResp = iManageWrapper.getWorkspaceACL(
          sourceWorkspace.id,
          customerId,
          library
        );

        Object patchSecurityWorkspaceData = mergeSecurityData(
          wsTemplateSecurityResp,
          wsSecurityResp,
          true,
          true,
          true,
          true
        );

        if (patchSecurityWorkspaceData != null) {
          Logger.getInstance().info('Update workspace security');

          iManageWrapper.patchSecurityWorkspace(
            sourceWorkspace.Id,
            customerId,
            library,
            patchSecurityWorkspaceData
          );
        }
      }

      //***************** */
      Logger.getInstance().info('Compare folders and update by template.');

      IManageWorkspaceWrap sourceWorkspaceWrap = getWorkspaceContentWrap(
        sourceWorkspace.Id,
        library,
        true,
        false
      );
      // System.debug('***** sourceWorkspaceWrap = ' + JSON.serialize(sourceWorkspaceWrap));

      compareFoldersAndUpdateByTemplate(
        sourceWorkspaceWrap,
        templateFolders,
        customerId,
        library,
        client,
        matter
      );
    } catch (Exception ex) {
      Logger.getInstance().error(ex, logPrefix);
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
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
    IManageWWorkspace workspace = iManageWrapper.getWorkspace(
      workspaceId,
      libraryId
    );
    // System.debug('***** getWorkspaceTemplateWrap: workspace = ' + JSON.serialize(workspace));
    List<IManageWFolder> folders = getAllFoldersByWorkspace(
      workspaceId,
      libraryId
    );
    // System.debug('***** getWorkspaceTemplateWrap: folders = ' + JSON.serialize(folders));
    return wrapWorkspaceContent(workspace, folders);
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

      iManageWrapper.iManageFoldersResponse packageFoldersResp = iManageWrapper.getFoldersByWorkspace(
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

  public static IManageWorkspaceWrap wrapWorkspaceContent(
    IManageWWorkspace sourceWorkspace,
    List<IManageWFolder> folders
  ) {
    IManageWorkspaceWrap workspaceWrap = new IManageWorkspaceWrap(
      sourceWorkspace
    );

    List<IManageFolderWrap> children = new List<IManageFolderWrap>();
    for (IManageWFolder folder : folders) {
      if (folder.parent_id == sourceWorkspace.id) {
        IManageFolderWrap f = new IManageFolderWrap(folder);
        f.workspaceId = sourceWorkspace.id;
        // System.debug('***** wrapWorkspaceContent: child folder = ' + JSON.serialize(f));
        children.add(f);
      }
    }
    // System.debug('***** wrapWorkspaceContent: workspaceWrap.children before addAll(children) = ' + JSON.serialize(workspaceWrap.children));
    // System.debug('***** wrapWorkspaceContent: children = ' + JSON.serialize(children));

    workspaceWrap.children.addAll(children);
    // System.debug('***** wrapWorkspaceContent: workspaceWrap.children = ' + JSON.serialize(workspaceWrap.children));
    // System.debug('***** wrapWorkspaceContent: workspaceWrap before mappingFolders = ' + JSON.serialize(workspaceWrap));
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
    // Logger.getInstance()
    // .info(
    //   'iManageWorkspacesHelper::compareFoldersAndUpdateByTemplate, templateFolders: ' + JSON.serialize(templateFolders)
    // );
    //   Logger.getInstance()
    //   .info(
    //     'iManageWorkspacesHelper::compareFoldersAndUpdateByTemplate, mappingWorkspaceWrap' + JSON.serialize(mappingWorkspaceWrap)
    //   );
    // Map<String, Object> params = new Map<String, Object>{
    //   'mappingWorkspaceWrap' => mappingWorkspaceWrap,
    //   'templateFolders' => templateFolders,
    //   'customerId' => customerId,
    //   'libraryId' => libraryId,
    //   'clientId' => clientId,
    //   'matterId' => matterId
    // };
    // Logger.getInstance()
    //   .info(
    //     'iManageWorkspacesHelper::compareFoldersAndUpdateByTemplate, Params: ' +
    //     JSON.serialize(params)
    //   );

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

    //System.debug('iManageWorkspacesHelper::compareFoldersAndUpdateByTemplate, mappedTemplateFolders: ' + JSON.serializePretty(mappedTemplateFolders));

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

      String folderType = ((IManageWFolder) templateFolderWrap.wrapItem)
        .folder_type;

      if (folderType == 'regular') {
        createRegularFolder(
          customerId,
          libraryId,
          clientMatterCode,
          templateFolderWrap,
          parentDestFolder,
          mappingWorkspaceWrap
        );
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
        createSearchFolder(
          customerId,
          libraryId,
          clientMatterCode,
          templateFolderWrap,
          parentDestFolder,
          mappingWorkspaceWrap
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
    Map<String, String> kvPair = iManageWrapper.getNameValuePair(
      'folders',
      folderId,
      customerId,
      libraryId
    );
    IManageWFolder folder = iManageWrapper.getFolderById(
      folderId,
      customerId,
      libraryId
    );
    if (kvPair.containsKey('IMCC_IsOptional')) {
      folder.isOptional = Boolean.valueOf(kvPair.get('IMCC_IsOptional'));
    }
    return folder;
  }

  public static IManageWFolder getSearchTemplateWFolder(
    String folderId,
    String customerId,
    String libraryId
  ) {
    Map<String, String> kvPair = iManageWrapper.getNameValuePair(
      'folders',
      folderId,
      customerId,
      libraryId
    );
    IManageWFolder folder = iManageWrapper.getSearchFolderById(
      folderId,
      customerId,
      libraryId
    );
    if (kvPair.containsKey('IMCC_IsOptional')) {
      folder.isOptional = Boolean.valueOf(kvPair.get('IMCC_IsOptional'));
    }
    return folder;
  }

  @AuraEnabled
  public static void updateEntityToWsMapping(
    String workspaceId,
    String libraryId,
    String entityId,
    Boolean autoCreated,
    String source
  ) {
    IManageWWorkspace workspace = iManageWrapper.getWorkspace(
      workspaceId,
      libraryId
    );
    IManage_WS_to_Entity_Mapping__c mapping = new IManage_WS_to_Entity_Mapping__c(
      Auto_created__c = autoCreated,
      EntityId__c = entityId,
      iManage_Workspace_Created_On__c = workspace.create_date,
      iManage_WS_Id__c = workspace.id,
      // OBSOLETE iManage_WS_Name__c = workspace.name,
      Source__c = source,
      iManage_Library__c = libraryId
    );
    insert mapping;
  }

  @TestVisible
  private static void createRegularFolder(
    String customerId,
    String libraryId,
    String clientMatterCode,
    IManageFolderWrap templateFolderWrap,
    IManageWFolder parentDestFolder,
    IManageWorkspaceWrap mappingWorkspaceWrap
  ) {
    String parentDestFolderId = parentDestFolder == null
      ? null
      : parentDestFolder.id;
    Boolean parentIsTab =
      parentDestFolder != null &&
      parentDestFolder.folder_type == 'tab';

    IManageWFolder tf = getTemplateWFolder(
      ((IManageWFolder) templateFolderWrap.wrapItem).id,
      customerId,
      libraryId
    );

    if (tf.isOptional == true) {
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
      return;
    }

    if (templateFolderWrap.parentFolder != null && parentDestFolder == null) {
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

    tf = mappingProfileWorkspaceValues(
      (IManageWWorkspace) mappingWorkspaceWrap.wrapItem,
      tf
    );

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
    IManageWFolder newDestFolder = iManageWrapper.createFolder(
      ((IManageWWorkspace) mappingWorkspaceWrap.wrapItem).id,
      tf,
      parentDestFolderId,
      parentIsTab,
      null,
      customerId,
      libraryId
    );

    Logger.getInstance().info('Patch folder name-value-pair');
    iManageWrapper.patchNameValuePair(
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
      iManageWrapper.patchFolder(
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

    if (newDestFolder.default_security != 'inherit') {
      Logger.getInstance().info('Get template folder security');
      List<IManageWSecurity> fSecurityList = iManageWrapper.getFolderACL(
        ((IManageWFolder) templateFolderWrap.wrapItem).id,
        customerId,
        libraryId
      );

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

        iManageWrapper.patchSecurityFolder(
          newDestFolder.id,
          customerId,
          libraryId,
          new Map<String, Object>{
            'default_security' => newDestFolder.default_security == 'inherit'
              ? 'public'
              : newDestFolder.default_security,
            'include' => include
          }
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
    if (tf.isOptional == true) {
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

    if (templateFolderWrap.parentFolder != null && parentDestFolder == null) {
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

    tf = MappingProfileWorkspaceValues(
      (IManageWWorkspace) mappingWorkspaceWrap.wrapItem,
      tf
    );
    //tf.Name = BuildFolderName(tf.Name, matterRow, folderVariableMatrixRows);

    Logger.getInstance()
      .info(
        String.format(
          'Create tab {0}-{1}',
          new List<Object>{
            clientMatterCode,
            templateFolderWrap.folderFullPath
          }
        )
      );
    IManageWFolder newDestTab = iManageWrapper.createTab(
      tf,
      ((IManageWWorkspace) mappingWorkspaceWrap.wrapItem).id,
      customerId,
      libraryId
    );

    Logger.getInstance().info('Patch folder name-value-pair');
    iManageWrapper.patchNameValuePair(
      'folders',
      newDestTab.id,
      customerId,
      libraryId,
      new Map<String, Object>{ 'folderTemplateId' => tf.id }
    );
    Logger.getInstance()
      .info(
        String.format(
          'Workspace: {0}. Tab: {1} added',
          new List<Object>{
            clientMatterCode,
            templateFolderWrap.folderFullPath
          }
        )
      );

    if (newDestTab.default_security != 'inherit') {
      Logger.getInstance().info('Get template tab security');
      List<IManageWSecurity> fSecurityList = iManageWrapper.getTabACL(
        ((IManageWFolder) templateFolderWrap.wrapItem).id,
        customerId,
        libraryId
      );

      if (fSecurityList.size() > 0) {
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

        Logger.getInstance().info('Update tab security');
        iManageWrapper.patchSecurityTab(
          newDestTab.id,
          customerId,
          libraryId,
          new Map<String, Object>{
            'default_security' => newDestTab.default_security == 'inherit'
              ? 'public'
              : newDestTab.default_security,
            'include' => include
          }
        );

        Logger.getInstance()
          .info(
            String.format(
              'Workspace: {0}. Tab: {1} security added',
              new List<Object>{
                clientMatterCode,
                templateFolderWrap.folderFullPath
              }
            )
          );
      }
    }

    mappingWorkspaceWrap.addFolderAndResetMapping(newDestTab);
  }

  @TestVisible
  private static void createSearchFolder(
    String customerId,
    String libraryId,
    String clientMatterCode,
    IManageFolderWrap templateFolderWrap,
    IManageWFolder parentDestFolder,
    IManageWorkspaceWrap mappingWorkspaceWrap
  ) {
    String parentDestFolderId = parentDestFolder == null
      ? null
      : parentDestFolder.id;

    IManageWFolder tf = getSearchTemplateWFolder(
      ((IManageWFolder) templateFolderWrap.wrapItem).id,
      customerId,
      libraryId
    );
    if (tf.isOptional == true) {
      Logger.getInstance()
        .info(
          String.format(
            'Workspace: {0}. Search Folder: {1} add ignored.',
            new List<Object>{
              clientMatterCode,
              templateFolderWrap.folderFullPath
            }
          )
        );
      return;
    }

    if (templateFolderWrap.parentFolder != null && parentDestFolder == null) {
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

    //tf.Name = BuildFolderName(tf.Name, matterRow, folderVariableMatrixRows);

    tf = mappingSearchProfileWorkspaceValues(
      (IManageWWorkspace) mappingWorkspaceWrap.wrapItem,
      tf
    );

    Logger.getInstance()
      .info(
        String.format(
          'Create search folder profile: {0}',
          new List<Object>{ JSON.serializePretty(tf, true) }
        )
      );

    Logger.getInstance()
      .info(
        String.format(
          'Create search folder {0}-{1}',
          new List<Object>{
            clientMatterCode,
            templateFolderWrap.folderFullPath
          }
        )
      );

    IManageWFolder newDestFolder = iManageWrapper.createSearchFolder(
      tf,
      ((IManageWWorkspace) mappingWorkspaceWrap.wrapItem).id,
      parentDestFolderId,
      customerId,
      libraryId
    );

    if (newDestFolder.default_security != 'inherit') {
      Logger.getInstance().info('Get template folder security');
      List<IManageWSecurity> fSecurityList = iManageWrapper.getFolderACL(
        ((IManageWFolder) templateFolderWrap.wrapItem).id,
        customerId,
        libraryId
      );

      if (fSecurityList.size() > 0) {
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
        Logger.getInstance().info('Update folder security');
        iManageWrapper.patchSecurityFolder(
          newDestFolder.id,
          customerId,
          libraryId,
          new Map<String, Object>{
            'default_security' => newDestFolder.default_security == 'inherit'
              ? 'public'
              : newDestFolder.default_security,
            'include' => include
          }
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
    Logger.getInstance()
      .info(
        String.format(
          'Workspace: {0}. Search Folder: {1} security added',
          new List<Object>{
            clientMatterCode,
            templateFolderWrap.folderFullPath
          }
        )
      );
  }

  @TestVisible
  private static IManageWFolder mappingProfileWorkspaceValues(
    IManageWWorkspace workspace,
    IManageWFolder templateFolder
  ) {
    String logPrefix = 'IManageWorkspacesHelper::mappingProfileWorkspaceValues';
    Logger.getInstance()
      .info(
        logPrefix +
        ': templateFolder.profile is null = ' +
        (templateFolder.profile == null)
      );
    if (templateFolder.profile == null) {
      return templateFolder;
    }

    Logger.getInstance()
      .info(
        logPrefix +
        ': templateFolder.profile before = ' +
        JSON.serialize(templateFolder.profile)
      );

    String mapTemplate = '%WORKSPACE_VALUE%';
    String jsonWorkspace = Json.serialize(workspace);
    Map<String, Object> mapWorkspace = (Map<String, Object>) JSON.deserializeUntyped(
      jsonWorkspace
    );

    String jsonTemolateFolderProfile = Json.serialize(templateFolder.profile);
    Map<String, Object> mapTemplateFolderProfile = (Map<String, Object>) JSON.deserializeUntyped(
      jsonTemolateFolderProfile
    );

    for (String templatePropName : mapTemplateFolderProfile.keySet()) {
      Object value = mapTemplateFolderProfile.get(templatePropName);
      if (String.valueOf(value) == mapTemplate) {
        if (mapWorkspace.containsKey(templatePropName)) {
          mapTemplateFolderProfile.put(
            templatePropName,
            mapWorkspace.get(templatePropName)
          );
        }
      }
    }

    templateFolder.profile = (IManageWFolderProfile) JSON.deserialize(
      JSON.serialize(mapTemplateFolderProfile),
      IManageWFolderProfile.class
    );

    Logger.getInstance()
      .info(
        logPrefix +
        ': templateFolder.profile after = ' +
        JSON.serialize(templateFolder.profile)
      );

    return templateFolder;
  }

  private static Boolean compareAcls(
    Boolean withAccess,
    IManageWSecurity newSecurity,
    IManageWSecurity existsSecurity
  ) {
    Boolean groupEquals =
      newSecurity.isGroup() &&
      existsSecurity.isGroup() &&
      newSecurity.id.toLowerCase() == existsSecurity.id.toLowerCase();
    Boolean userEquals =
      !newSecurity.isGroup() &&
      !existsSecurity.isGroup() &&
      newSecurity.id.toLowerCase() == existsSecurity.id.toLowerCase();
    if (!withAccess)
      return groupEquals || userEquals;
    else {
      Boolean accessNotEquals =
        newSecurity.access_level != existsSecurity.access_level;
      return (groupEquals && accessNotEquals) ||
        (userEquals && accessNotEquals);
    }
  }

  @TestVisible
  private static Object mergeSecurityData(
    iManageWrapper.iManageSecurityResponse existsSecurity,
    iManageWrapper.iManageSecurityResponse newSecurity,
    Boolean applyIncludedAcls,
    Boolean applyModifiedAcls,
    Boolean applyRemovedAcls,
    Boolean applyNewDefaultSecurity
  ) {
    if (applyNewDefaultSecurity && newSecurity.default_security == 'inherit') {
      return null;
    }

    List<IManageWSecurity> existsSecurityData = existsSecurity.data;
    List<IManageWSecurity> newSecurityData = newSecurity.Data;

    if (existsSecurityData.size() == 0 && newSecurityData.size() == 0) {
      return null;
    }

    List<IManageWSecurity> includeAcls = new List<IManageWSecurity>();
    if (applyIncludedAcls) {
      for (IManageWSecurity x : newSecurityData) {
        Boolean isInExist = false;
        for (IManageWSecurity y : existsSecurityData) {
          if (compareAcls(false, x, y)) {
            isInExist = true;
            break;
          }
        }
        if (!isInExist) {
          includeAcls.add(x);
        }
      }
    }

    List<IManageWSecurity> removeAcls = new List<IManageWSecurity>();
    if (applyModifiedAcls) {
      for (IManageWSecurity x : existsSecurityData) {
        Boolean isInNew = false;
        for (IManageWSecurity y : newSecurityData) {
          if (compareAcls(false, x, y)) {
            isInNew = true;
            break;
          }
        }
        if (!isInNew) {
          includeAcls.add(x);
        }
      }
    }

    List<IManageWSecurity> modifiedAcls = new List<IManageWSecurity>();
    if (applyRemovedAcls) {
      for (IManageWSecurity x : newSecurityData) {
        Boolean isInExist = false;
        for (IManageWSecurity y : existsSecurityData) {
          if (compareAcls(true, x, y)) {
            isInExist = true;
            break;
          }
        }
        if (isInExist) {
          includeAcls.add(x);
        }
      }
    }

    String defaultSecurity = applyNewDefaultSecurity &&
      existsSecurity.default_security != newSecurity.default_security
      ? newSecurity.default_security
      : existsSecurity.default_security;

    if (
      includeAcls.size() > 0 ||
      removeAcls.size() > 0 ||
      modifiedAcls.size() > 0 ||
      string.isNotBlank(defaultSecurity)
    ) {
      List<Map<String, Object>> include = new List<Map<String, Object>>();
      for (IManageWSecurity d : includeAcls) {
        include.add(
          new Map<String, Object>{
            'id' => d.id,
            'access_level' => d.access_level,
            'type' => d.type,
            'isModified' => false
          }
        );
      }
      for (IManageWSecurity d : modifiedAcls) {
        include.add(
          new Map<String, Object>{
            'id' => d.id,
            'access_level' => d.access_level,
            'type' => d.type,
            'isModified' => true
          }
        );
      }

      List<Map<String, Object>> remove = new List<Map<String, Object>>();
      for (IManageWSecurity d : removeAcls) {
        remove.add(new Map<String, Object>{ 'id' => d.id, 'type' => d.type });
      }
      Map<String, Object> securityData = new Map<String, Object>{
        'include' => include,
        'remove' => remove,
        'default_security' => defaultSecurity
      };

      return securityData;
    }
    return null;
  }

  @TestVisible
  private static IManageWFolder mappingSearchProfileWorkspaceValues(
    IManageWWorkspace workspace,
    IManageWFolder templateSearchFolder
  ) {
    String logPrefix = 'IManageWorkspacesHelper::mappingSearchProfileWorkspaceValues';
    Logger.getInstance()
      .info(
        logPrefix +
        ': templateSearchFolder.searchprofile is null = ' +
        (templateSearchFolder.searchprofile == null)
      );
    if (templateSearchFolder.searchprofile == null) {
      return templateSearchFolder;
    }

    Logger.getInstance()
      .info(
        logPrefix =
          ': templateSearchFolder.searchprofile before = ' +
          JSON.serialize(templateSearchFolder.searchprofile)
      );

    String mapTemplate = '%WORKSPACE_VALUE%';
    String jsonWorkspace = Json.serialize(workspace);
    Map<String, Object> mapWorkspace = (Map<String, Object>) JSON.deserializeUntyped(
      jsonWorkspace
    );

    String jsonSearchProfile = Json.serialize(
      templateSearchFolder.searchprofile
    );
    Map<String, Object> mapSearchProfile = (Map<String, Object>) JSON.deserializeUntyped(
      jsonSearchProfile
    );

    for (String templatePropName : mapSearchProfile.keySet()) {
      Object value = mapSearchProfile.get(templatePropName);
      if (String.valueOf(value) == mapTemplate) {
        if (mapWorkspace.containsKey(templatePropName)) {
          mapSearchProfile.put(
            templatePropName,
            mapWorkspace.get(templatePropName)
          );
        }
      }
    }
    templateSearchFolder.searchprofile = (IManageWSearchFolderProfile) JSON.deserialize(
      JSON.serialize(mapSearchProfile),
      IManageWSearchFolderProfile.class
    );

    Logger.getInstance()
      .info(
        logPrefix =
          ': templateSearchFolder.searchprofile after = ' +
          JSON.serialize(templateSearchFolder.searchprofile)
      );
    return templateSearchFolder;
  }
}
global class iManageFileSaver {
  global static void SaveFile(
    Blob data,
    string name,
    string extension,
    String entityId
  ) {
    Map<String, Object> params = new Map<String, Object>{
      'data' => '***',
      'name' => name,
      'extension' => extension,
      'entityId' => entityId
    };
    Logger.getInstance()
      .info(
        'iManageFileSaver::SaveFile, start method. Params: ' +
        JSON.serialize(params)
      );
    LicenseService.CheckOrganizationLicense();

    try {
      iManageSettings__c mc = iManageSettings__c.getOrgDefaults();
      if (mc.iManage_Default_Folder_Id__c == null)
        throw new IManageFileSaverException(
          'iManage Default folder not defined. Please configure it.'
        );

      IManageMappingHelper.IManageIFrameData link = IManageMappingHelper.getMappingData(
        entityId
      );
      if (link == null || link.ClientId == null || link.MatterId == null)
        throw new IManageFileSaverException(
          'iManage mapping not configured. Please configure it.'
        );

      iManageWrapper.ApiInfo apiInfo = iManageWrapper.GetApiInfo();
      String workspaceId = iManageWorkspacesHelper.SearchWorkspace(
        mc,
        apiInfo,
        link
      );
      Logger.getInstance()
        .info(
          'iManageFileSaver::SaveFile, start method. workspaceId = ' +
          workspaceId
        );

      String folderId = CreateFolderStructure(
        apiInfo,
        workspaceId,
        mc.iManage_Default_Folder_Id__c,
        mc,
        link
      );
      Logger.getInstance()
        .info(
          'iManageFileSaver::SaveFile, start method. folderId = ' + folderId
        );

      iManageWrapper.PostDocument(
        apiInfo.customerId,
        apiInfo.library,
        folderId,
        name,
        extension,
        data
      );
    } catch (IManageFileSaverException ex) {
      throw ex;
    } catch (Exception ex) {
      Logger.getInstance().error(ex, 'iManageFileSaver::SaveFile');
      throw ex;
    }
  }

  global static void SaveFileToFolder(
    Blob data,
    string name,
    string extension,
    String entityId,
    String folder
  ) {
    Map<String, Object> params = new Map<String, Object>{
      'data' => '***',
      'name' => name,
      'extension' => extension,
      'entityId' => entityId,
      'folder' => folder
    };
    Logger.getInstance()
      .info(
        'iManageFileSaver::SaveFile, start method. Params: ' +
        JSON.serialize(params)
      );
    LicenseService.CheckOrganizationLicense();

    try {
      iManageSettings__c mc = iManageSettings__c.getOrgDefaults();
      if (mc.iManage_Default_Folder_Id__c == null)
        throw new IManageFileSaverException(
          'iManage Default folder not defined. Please configure it.'
        );

      IManageMappingHelper.IManageIFrameData link = IManageMappingHelper.getMappingData(
        entityId
      );
      if (link == null || link.ClientId == null || link.MatterId == null)
        throw new IManageFileSaverException(
          'iManage mapping not configured. Please configure it.'
        );

      iManageWrapper.ApiInfo apiInfo = iManageWrapper.GetApiInfo();
      String workspaceId = iManageWorkspacesHelper.SearchWorkspace(
        mc,
        apiInfo,
        link
      );
      Logger.getInstance()
        .info(
          'iManageFileSaver::SaveFile, start method. workspaceId = ' +
          workspaceId
        );

      String f = folder == null || String.isEmpty(folder) ? mc.iManage_Default_Folder_Id__c : folder;

      String folderId = CreateFolderStructure(
        apiInfo,
        workspaceId,
        f,
        mc,
        link
      );
      Logger.getInstance()
        .info(
          'iManageFileSaver::SaveFile, start method. folderId = ' + folderId
        );

        iManageWrapper.PostDocument(
        apiInfo.customerId,
        apiInfo.library,
        folderId,
        name,
        extension,
        data
      );
    } catch (IManageFileSaverException ex) {
      Logger.getInstance().error(ex, 'iManageFileSaver::SaveFile');
      throw ex;
    } catch (Exception ex) {
      Logger.getInstance().error(ex, 'iManageFileSaver::SaveFile');
      throw ex;
    }
  }

  @TestVisible
  private static String GetFolderByStructure(
    iManageWrapper.ApiInfo apiInfo,
    String workspaceId,
    String folderStructure
  ) {
    Map<String, Object> params = new Map<String, Object>{
      'apiInfo' => apiInfo,
      'workspaceId' => workspaceId,
      'folderStructure' => folderStructure
    };
    Logger.getInstance()
      .info(
        'iManageFileSaver::GetFolderByStructure, start method. Params: ' +
        JSON.serialize(params)
      );

    String[] folders = folderStructure.split('/');
    String id = workspaceId;
    for (String folder : folders) {
      iManageWrapper.iManageFolderSearch searchResult = iManageWrapper.SearchFolder(
        apiInfo.customerId,
        apiInfo.library,
        id,
        folder
      );
      id = GetFolderFirstOrDefault(searchResult);
    }
    Logger.getInstance()
      .info('iManageFileSaver::GetFolderByStructure, result: ' + id);
    return id;
  }

  @TestVisible
  private static String CreateFolderStructure(
    iManageWrapper.ApiInfo apiInfo,
    String workspaceId,
    String folderStructure,
    iManageSettings__c mc,
    IManageMappingHelper.IManageIFrameData link
  ) {
    Map<String, Object> params = new Map<String, Object>{
      'apiInfo' => apiInfo,
      'workspaceId' => workspaceId,
      'folderStructure' => folderStructure,
      'mc' => mc,
      'link' => link
    };
    Logger.getInstance()
      .info(
        'iManageFileSaver::CreateFolderStructure, start method. Params: ' +
        JSON.serialize(params)
      );

    String[] folders = folderStructure.split('/');
    String id = workspaceId;
    for (String folder : folders) {
      iManageWrapper.iManageFolderSearch searchResult = iManageWrapper.SearchFolder(
        apiInfo.customerId,
        apiInfo.library,
        id,
        folder
      );

      system.debug(searchResult);
      Logger.getInstance()
        .info(
          'iManageFileSaver::CreateFolderStructure, searchResult = ' +
          searchResult
        );
      String parentId = id;

      Logger.getInstance()
        .info(
          'iManageFileSaver::CreateFolderStructure, Before GetFolderFirstOrDefault(): id = ' +
          id
        );
      id = GetFolderFirstOrDefault(searchResult);
      Logger.getInstance()
        .info(
          'iManageFileSaver::CreateFolderStructure, After GetFolderFirstOrDefault(): id = ' +
          id
        );
      if (id == null || id == 'null' || id == '' || id == workspaceId) {
        iManageWrapper.iManageFolderResponse newFolder = null;
        if (parentId == workspaceId)
          newFolder = iManageWrapper.PostFolderToWorkspace(
            apiInfo.customerId,
            apiInfo.library,
            workspaceId,
            folder,
            mc.gdsi_imanage__ClientField__c,
            link.ClientId,
            mc.gdsi_imanage__MatterField__c,
            link.MatterId
          );
        else
          newFolder = iManageWrapper.PostFolder(
            apiInfo.customerId,
            apiInfo.library,
            folder,
            parentId,
            mc.gdsi_imanage__ClientField__c,
            link.ClientId,
            mc.gdsi_imanage__MatterField__c,
            link.MatterId
          );
        system.debug(newFolder.data);
        Logger.getInstance()
          .info(
            'iManageFileSaver::CreateFolderStructure, newFolder.data = ' +
            newFolder?.data
          );
        id = newFolder.data == null ? '' : newFolder.data.id;
      }
    }
    Logger.getInstance()
      .info('iManageFileSaver::CreateFolderStructure, result: ' + id);
    return id;
  }

  @TestVisible
  private static String GetFolderFirstOrDefault(
    iManageWrapper.iManageFolderSearch searchResult
  ) {
    Map<String, Object> params = new Map<String, Object>{
      'searchResult' => searchResult
    };
    Logger.getInstance()
      .info(
        'iManageFileSaver::GetFolderFirstOrDefault, start method. Params: ' +
        JSON.serialize(params)
      );
    if (
      searchResult == null ||
      searchResult.data == null ||
      searchResult.data.size() == 0 ||
      searchResult.data[0].id == null ||
      searchResult.data[0].id == 'null'
    ) {
      return '';
    }

    String result = searchResult.data[0].id;
    Logger.getInstance()
      .info('iManageFileSaver::GetFolderFirstOrDefault, Result: ' + result);
    return result;
  }

  public class IManageFileSaverException extends Exception {
  }
}
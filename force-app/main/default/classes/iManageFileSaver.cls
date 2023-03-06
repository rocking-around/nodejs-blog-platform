global class iManageFileSaver {
  global static void SaveFile(
    Blob data,
    string name,
    string extension,
    String entityId
  ) {
    LicenseService.CheckOrganizationLicense();
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
    iManageWrapper.iManageWorkspaceSearch searchResult = iManageWrapper.SearchWorkspace(
      apiInfo.customerId,
      apiInfo.library,
      mc.gdsi_imanage__ClientField__c,
      link.ClientId,
      mc.gdsi_imanage__MatterField__c,
      link.MatterId
    );
    String workspaceId = GetWorkspaceFirstOrDefault(searchResult);
    system.debug(workspaceId);
    String folderId = CreateFolderStructure(
      apiInfo,
      workspaceId,
      mc.iManage_Default_Folder_Id__c,
      mc,
      link
    );
    system.debug(folderId);
    iManageWrapper.PostDocument(
      apiInfo.customerId,
      apiInfo.library,
      folderId,
      name,
      extension,
      data
    );
  }

  private static String GetFolderByStructure(
    iManageWrapper.ApiInfo apiInfo,
    String workspaceId,
    String folderStructure
  ) {
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
    return id;
  }

  private static String CreateFolderStructure(
    iManageWrapper.ApiInfo apiInfo,
    String workspaceId,
    String folderStructure,
    iManageSettings__c mc,
    IManageMappingHelper.IManageIFrameData link
  ) {
    system.debug('Create new folders structure for the ' + folderStructure);
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
      String parentId = id;

      system.debug(id);
      id = GetFolderFirstOrDefault(searchResult);
      system.debug(id);
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
        id = newFolder.data == null ? '' : newFolder.data.id;
      }
    }
    return id;
  }

  private static String GetWorkspaceFirstOrDefault(
    iManageWrapper.iManageWorkspaceSearch searchResult
  ) {
    if (
      searchResult == null ||
      searchResult.data == null ||
      searchResult.data.results == null ||
      searchResult.data.results.size() == 0 ||
      searchResult.data.results[0].id == null
    ) {
      return '';
    }

    return searchResult.data.results[0].id;
  }

  private static String GetFolderFirstOrDefault(
    iManageWrapper.iManageFolderSearch searchResult
  ) {
    if (
      searchResult == null ||
      searchResult.data == null ||
      searchResult.data.size() == 0 ||
      searchResult.data[0].id == null ||
      searchResult.data[0].id == 'null'
    ) {
      return '';
    }

    return searchResult.data[0].id;
  }

  public class IManageFileSaverException extends Exception {
  }
}

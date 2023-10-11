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
  public static Void createWorkspace(String workspaceTemplate){
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
      IManageWorkspaceWrap templateWorkspaceWrap = getWorkspaceTemplateWrap(matterRow.Template, clientApi);

      if (templateWorkspaceWrap == null) {
        throw new IManageExceptions.IManageApplicationException('Workspace template not found. WS Template Id = ' + wsTemplateId);
      }

      List<IManageFolderWrap> templateFolders = templateWorkspaceWrap.GetFlatListAllFolders().Reverse().ToList();
      Logger.getInstance().info('Found ' + String.valueOf(templateFolders.size()) + ' template folders.');

      // clone templateWorkspaceWrap.wrapItem
      IManageWWorkspace templateWorkspace = ((IManageWWorkspace)templateWorkspaceWrap.wrapItem).cloneThis();

      Logger.getInstance().Info('Create destination workspace...');
      templateWorkspace.custom1 = generalSettings['general:ClientField']; // TODO: get Custom1
      templateWorkspace.custom2 = generalSettings['general:MatterField']; // TODO: get Custom2
      templateWorkspace.Name = 'WS'; //TODO: build ws name?

      IManageWWorkspace sourceWorkspace = createWorkspaceApiCall(templateWorkspace);
      Logger.getInstance().info('Workspace created.');

      Logger.getInstance().info('Compare folders and update by template.');
      compareFoldersAndUpdateByTemplate();

    } catch (Exception ex) {
      Logger.getInstance().error(ex, logPrefix);
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
  }

  public IManageWWorkspace createWorkspaceApiCall(IManageWWorkspace templateWorkspace) {
    return null;
  }

  public static IManageWorkspaceWrap getWorkspaceTemplateWrap() {
    return null;
  }

  public static IManageWorkspaceWrap compareFoldersAndUpdateByTemplate() {

  }
}

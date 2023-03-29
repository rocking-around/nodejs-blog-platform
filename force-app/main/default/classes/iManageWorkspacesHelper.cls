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
          apiData.library,
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
}

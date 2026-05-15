public class iManageIFrameDialog {
  @AuraEnabled
  public static String GetIFrameFolder(String entityId) {
    Logger.getInstance()
      .info('iManageIFrameDialog::GetIFrameFolder, start method');
    // Check licensing
    LicenseService.CheckOrganizationLicense();

    try {
      String dialogUrl = GetDialogUrl(entityId);
      Logger.getInstance()
        .info('iManageIFrameDialog::GetIFrameFolder, result=' + dialogUrl);
      return dialogUrl;
    } catch (IManageExceptions.IManageUnauthorizedException ex) {
      Logger.getInstance()
        .error(ex, 'iManageIFrameDialog::GetIFrameFolder');
      throw IManageBaseHelper.BuildException(
        IManageBaseHelper.IManageErrors.UNAUTHORIZED
      );
    } finally {
      Logger.getInstance().Flush();
    }
  }

  @AuraEnabled
  public static String GetIFrameFolderPicker() {
    Logger.getInstance()
      .info('iManageIFrameDialog::GetIFrameFolderPicker, start method');
    // Check licensing
    LicenseService.CheckOrganizationLicense();

    try {
      iManageWrapper.ApiInfo apiData = iManageWrapper.GetApiInfo();
      iManageWrapper.iManageDialogToken dialogTokenResult = iManageWrapper.GetDialogToken(
        apiData.customerId
      );
      iManageSettings__c mc = iManageSettings__c.getOrgDefaults();
      String result =
        mc.Url__c +
        '/work/partner-apps/' +
        mc.Client_Id__c +
        '/dialogs/file-picker/?protocol=postmessage&dialogToken=' +
        EncodingUtil.urlEncode(dialogTokenResult.data.dialog_token, 'UTF-8') +
        '&mode=browse&multiselect=false&types=folder';
      Logger.getInstance()
        .info('iManageIFrameDialog::GetIFrameFolderPicker, result=' + result);
      return result;
    } catch (IManageExceptions.IManageUnauthorizedException ex) {
      Logger.getInstance()
        .error(ex, 'iManageIFrameDialog::GetIFrameFolderPicker');
      throw IManageBaseHelper.BuildException(
        IManageBaseHelper.IManageErrors.UNAUTHORIZED
      );
    } finally {
      Logger.getInstance().Flush();
    }
  }

  @AuraEnabled
  public static String GetIFrameFilePicker() {
    Logger.getInstance()
      .info('iManageIFrameDialog::GetIFrameFilePicker, start method');
    // Check licensing
    LicenseService.CheckOrganizationLicense();

    try {
      iManageWrapper.ApiInfo apiData = iManageWrapper.GetApiInfo();
      iManageWrapper.iManageDialogToken dialogTokenResult = iManageWrapper.GetDialogToken(
        apiData.customerId
      );
      iManageSettings__c mc = iManageSettings__c.getOrgDefaults();
      String result =
        mc.Url__c +
        '/work/partner-apps/' +
        mc.Client_Id__c +
        '/dialogs/file-picker/?protocol=postmessage&dialogToken=' +
        EncodingUtil.urlEncode(dialogTokenResult.data.dialog_token, 'UTF-8') +
        '&mode=open&multiselect=true';
      Logger.getInstance()
        .info('iManageIFrameDialog::GetIFrameFilePicker, result=' + result);
      return result;
    } catch (IManageExceptions.IManageUnauthorizedException ex) {
      Logger.getInstance()
        .error(ex, 'iManageIFrameDialog::GetIFrameFilePicker');
      throw IManageBaseHelper.BuildException(
        IManageBaseHelper.IManageErrors.UNAUTHORIZED
      );
    } finally {
      Logger.getInstance().Flush();
    }
  }

  @AuraEnabled
  public static String GetIFrameFilePickerForEntity(String entityId) {
    Logger.getInstance()
      .info('iManageIFrameDialog::GetIFrameFilePickerForEntity, start method');
    // Check licensing
    LicenseService.CheckOrganizationLicense();

    try {
      iManageWrapper.ApiInfo apiData = iManageWrapper.GetApiInfo();
      iManageWrapper.iManageDialogToken dialogTokenResult = iManageWrapper.GetDialogToken(
        apiData.customerId
      );
      iManageSettings__c mc = iManageSettings__c.getOrgDefaults();

      String result =
        mc.Url__c +
        '/work/partner-apps/' +
         EncodingUtil.urlEncode(mc.Client_Id__c, 'UTF-8') +
        '/dialogs/file-picker/?protocol=postmessage&dialogToken=' +
        EncodingUtil.urlEncode(dialogTokenResult.data.dialog_token, 'UTF-8') +
        '&mode=open&multiselect=true';

      IManageMappingHelper.IManageIFrameData link = null;
      
      try
      { 
        link = IManageMappingHelper.getMappingData(
          entityId
        );
      }
      catch (Exception ex) {
      }

      if (link == null || link.ClientId == null || link.MatterId == null)
      {
        Logger.getInstance()
          .info('iManageIFrameDialog::GetIFrameFilePickerForEntity, result=' + result);
        return result;
      }

      String workspaceId = iManageWorkspacesHelper.SearchWorkspace(
        mc,
        apiData,
        link
      );

      if (workspaceId == null || workspaceId == '')
      {
        Logger.getInstance()
          .info('iManageIFrameDialog::GetIFrameFilePickerForEntity, result=' + result);
        return result;
      }

      result = result + '&start=' + EncodingUtil.urlEncode(workspaceId, 'UTF-8'); 

      Logger.getInstance()
          .info('iManageIFrameDialog::GetIFrameFilePickerForEntity, result=' + result);
      return result;
    
    } catch (IManageExceptions.IManageUnauthorizedException ex) {
      Logger.getInstance()
        .error(ex, 'iManageIFrameDialog::GetIFrameFilePickerForEntity');
      throw IManageBaseHelper.BuildException(
        IManageBaseHelper.IManageErrors.UNAUTHORIZED
      );
    } finally {
      Logger.getInstance().Flush();
    }
  }


  private static String GetDialogUrl(String entityId) {
    IManageMappingHelper.IManageIFrameData link = IManageMappingHelper.getMappingData(
      entityId
    );

    iManageWrapper.ApiInfo apiData = iManageWrapper.GetApiInfo();
    iManageWrapper.iManageDialogToken dialogTokenResult = iManageWrapper.GetDialogToken(
      apiData.customerId
    );
    iManageSettings__c mc = iManageSettings__c.getOrgDefaults();

    if (mc == null)
      throw IManageBaseHelper.BuildException(
        IManageBaseHelper.IManageErrors.EMPTY_CUSTOM_RESOURCE
      );
    String dialogUrl =
      mc.Url__c +
      '/work/partner-apps/' +
      EncodingUtil.urlEncode(mc.Client_Id__c, 'UTF-8') +
      '/dialogs/file-picker/?protocol=postmessage&dialogToken=' +
      EncodingUtil.urlEncode(dialogTokenResult.data.dialog_token, 'UTF-8') +
      '&mode=emm&multiselect=false';

    if (link == null || link.ClientId == null || link.MatterId == null)
      return dialogUrl;

    String workspaceId = iManageWorkspacesHelper.SearchWorkspace(
      mc,
      apiData,
      link
    );

    if (workspaceId == null || workspaceId == '')
      return dialogUrl;

    return dialogUrl + '&start=' + EncodingUtil.urlEncode(workspaceId, 'UTF-8');
  }
}
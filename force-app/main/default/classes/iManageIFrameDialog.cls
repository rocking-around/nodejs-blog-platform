public class iManageIFrameDialog {
    @AuraEnabled
    public static String GetIFrameFolder(String entityId) {
        // Check licensing
        LicenseService.CheckOrganizationLicense();
        
        IManageMappingHelper.IManageIFrameData link = IManageMappingHelper.getMappingData(
            entityId
        );
        
        /*if (link == null || link.ClientId == null || link.MatterId == null)
            throw IManageBaseHelper.BuildException(
                IManageBaseHelper.IManageErrors.EMPTY_CLIENT_OR_MATTER
            );*/
        
        try {
            iManageWrapper.ApiInfo apiData = iManageWrapper.GetApiInfo();
            iManageWrapper.iManageDialogToken dialogTokenResult = iManageWrapper.GetDialogToken(apiData.customerId);
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
            
            iManageWrapper.iManageWorkspaceSearch searchResult = 
                iManageWrapper.SearchWorkspace(apiData.customerId, apiData.library, mc.ClientField__c, 
                                               link.ClientId, mc.MatterField__c, link.MatterId);
            
            if (
                searchResult == null ||
                searchResult.data == null ||
                searchResult.data.size() == 0 ||
                searchResult.data[0].id == null
            ) {
                return dialogUrl;
            }
            
            return dialogUrl +
                '&start=' +
                EncodingUtil.urlEncode(searchResult.data[0].id, 'UTF-8');
        } catch (IManageExceptions.IManageUnauthorizedException ex) {
            throw IManageBaseHelper.BuildException(
                IManageBaseHelper.IManageErrors.UNAUTHORIZED
            );
        }
    }

    @AuraEnabled
    public static String GetIFrameFolderPicker() {
        // Check licensing
        LicenseService.CheckOrganizationLicense();
        
        try {
            iManageWrapper.ApiInfo apiData = iManageWrapper.GetApiInfo();
            iManageWrapper.iManageDialogToken dialogTokenResult = iManageWrapper.GetDialogToken(apiData.customerId);
            iManageSettings__c mc = iManageSettings__c.getOrgDefaults();
            return mc.Url__c +
                '/work/partner-apps/' +
                mc.Client_Id__c +
                '/dialogs/file-picker/?protocol=postmessage&dialogToken=' +
                EncodingUtil.urlEncode(dialogTokenResult.data.dialog_token, 'UTF-8') +
                '&mode=browse&multiselect=false&types=folder';
        } catch (IManageExceptions.IManageUnauthorizedException ex) {
            throw IManageBaseHelper.BuildException(
                IManageBaseHelper.IManageErrors.UNAUTHORIZED
            );
        }
    }
    
    @AuraEnabled
    public static String GetIFrameFilePicker() {
        // Check licensing
        LicenseService.CheckOrganizationLicense();
        
        try {
            iManageWrapper.ApiInfo apiData = iManageWrapper.GetApiInfo();
            iManageWrapper.iManageDialogToken dialogTokenResult = iManageWrapper.GetDialogToken(apiData.customerId);
            iManageSettings__c mc = iManageSettings__c.getOrgDefaults();
            return mc.Url__c +
                '/work/partner-apps/' +
                mc.Client_Id__c +
                '/dialogs/file-picker/?protocol=postmessage&dialogToken=' +
                EncodingUtil.urlEncode(dialogTokenResult.data.dialog_token, 'UTF-8') +
                '&mode=open';
        } catch (IManageExceptions.IManageUnauthorizedException ex) {
            throw IManageBaseHelper.BuildException(
                IManageBaseHelper.IManageErrors.UNAUTHORIZED
            );
        }
    }
}
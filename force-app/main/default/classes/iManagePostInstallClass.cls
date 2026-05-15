global class iManagePostInstallClass implements InstallHandler {
  global void onInstall(InstallContext context) {
    if (context.previousVersion() == null) {
      /*if(!PackagesChecker.IsRequiredPackagesExists()) {
                iManagePostInstallException ex = new iManagePostInstallException();
                ex.setMessage('Sorry, the Litify package cannot be found on your Salesforce. Please install Litify before continuing the Litify/iManage installation.');
                throw ex;
            }*/
      // String litify_main_package = 'litify_pm';
      // String litify_corporate_package = 'LegalStratusISV';
      // List<String> packageList = new String[] { litify_main_package, litify_corporate_package };
      // PackageLicense[] packages = [SELECT Id FROM PackageLicense WHERE NamespacePrefix IN :packageList];

      // if(packages.size() < 1) {
      //     iManagePostInstallException ex = new iManagePostInstallException();
      //     ex.setMessage('Sorry, the Litify package cannot be found on your Salesforce. Please install Litify before continuing the Litify/iManage installation.');
      //     throw ex;
      // }
      PackagesChecker.IsRequiredPackagesExists();
      LicenseService.SendOrganizationInfo(true);
    }
  }

  // public class iManagePostInstallException extends Exception {
  // }
}
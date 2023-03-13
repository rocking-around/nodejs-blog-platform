global with sharing class PackagesChecker {
  private static final String LITIFY_MAIN_PACKAGE = 'litify_pm';
  private static final String LITIFY_CORPORATE_PACKAGE = 'LegalStratusISV';

  // public static Boolean IsRequiredPackagesExists() {
  //     List<String> packageList = new String[] { LITIFY_MAIN_PACKAGE, LITIFY_CORPORATE_PACKAGE };
  //     PackageLicense[] packages = [SELECT Id FROM PackageLicense WHERE NamespacePrefix IN :packageList];
  //     return packages.size() > 0;
  // }

  @future(callout=true)
  public static void IsRequiredPackagesExists() {
    List<String> packageList = new List<String>{
      LITIFY_MAIN_PACKAGE,
      LITIFY_CORPORATE_PACKAGE
    };
    PackageLicense[] packages = [
      SELECT Id
      FROM PackageLicense
      WHERE NamespacePrefix IN :packageList
    ];
    if (packages.size() < 1) {
      iManageRequiredPackagesException ex = new iManageRequiredPackagesException();
      ex.setMessage(
        'Sorry, the Litify package cannot be found on your Salesforce. Please install Litify before continuing the Litify/iManage installation.'
      );
      throw ex;
    }
  }

  public class iManageRequiredPackagesException extends Exception {
  }
}

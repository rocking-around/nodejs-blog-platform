@isTest
private class PackagesCheckerTests {
  // @isTest
  // static void IsRequiredPackagesLitifyExistsTest() {
  //     PackageLicense[] packagesLitify = [SELECT Id FROM PackageLicense WHERE NamespacePrefix = 'litify_pm'];
  //     PackageLicense[] packagesCorporateLitify = [SELECT Id FROM PackageLicense WHERE NamespacePrefix = 'LegalStratusISV'];
  //     Boolean isPackageExists = PackagesChecker.IsRequiredPackagesExists();

  //     System.assert(packagesLitify.size() > 0 || packagesCorporateLitify.size() > 0 == isPackageExists, 'Packages not checked properly');
  // }

  @isTest
  static void IsRequiredPackagesLitifyExistsTest() {
    PackageLicense[] packagesLitify = [
      SELECT Id
      FROM PackageLicense
      WHERE NamespacePrefix = 'litify_pm'
    ];
    PackageLicense[] packagesCorporateLitify = [
      SELECT Id
      FROM PackageLicense
      WHERE NamespacePrefix = 'LegalStratusISV'
    ];

    try {
      Test.startTest();
      PackagesChecker.IsRequiredPackagesExists();
      Test.stopTest();
      System.assert(
        packagesLitify.size() > 0 ||
        packagesCorporateLitify.size() > 0,
        'Packages not checked properly'
      );
    } catch (Exception ex) {
      System.assert(
        packagesLitify.size() == 0 &&
        packagesCorporateLitify.size() == 0,
        'Packages not checked properly'
      );
    }
  }
}

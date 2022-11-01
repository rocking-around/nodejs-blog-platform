// ISV PACKAGED
//
@isTest
private class DescribePackageCustomLabelsTests {
  static testMethod void describeLabelLsTest() {
    Boolean TestOk = DescribePackageCustomLabels.describeLabelLs();
    system.assert(TestOk == true);
  }
}

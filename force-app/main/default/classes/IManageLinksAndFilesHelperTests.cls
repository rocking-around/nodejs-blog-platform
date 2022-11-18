@isTest
private class IManageLinksAndFilesHelperTests {
  @isTest
  static void getLinksTest() {
    String id = '00U4H000011y36GUAQ';
    IManage_File_Link__c fl = new IManage_File_Link__c(
      ParentId__c = id,
      Version__c = '2',
      File_Link__c = 'http://google.com?q=test'
    );
    insert fl;

    Test.startTest();
    List<IManage_File_Link__c> links = IManageLinksAndFilesHelper.getLinks(id);
    Test.stopTest();
    System.assert(links.size() > 0, 'The list is empty');
    IManage_File_Link__c link = links.get(0);
    System.assertEquals(
      link.ParentId__c,
      fl.ParentId__c,
      'ParentId__c has wrong value'
    );
    System.assertEquals(
      link.File_Link__c,
      fl.File_Link__c,
      'File_Link__c has wrong value'
    );
    System.assertEquals(
      link.Version__c,
      fl.Version__c,
      'File_Link__c has wrong value'
    );
  }
}

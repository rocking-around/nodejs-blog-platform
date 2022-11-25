@isTest
private class IManageLinksAndFilesHelperTests {
  @isTest
  static void getLinksTest() {
    // Insert File_Link
    String recordId = '00U4H000011y36GUAQ';
    String fileLinkUrl = 'http://google.com?q=test';
    String vers = '2';
    IManage_File_Link__c fileLink = new IManage_File_Link__c(
      ParentId__c = recordId,
      Version__c = vers,
      File_Link__c = fileLinkUrl
    );

    insert fileLink;
    Test.startTest();
    List<IManage_File_Link__c> links = IManageLinksAndFilesHelper.getLinks(
      recordId,
      100,
      0
    );
    Integer count = IManageLinksAndFilesHelper.getLinksCount(recordId);
    Test.stopTest();

    System.assert(links.size() > 0, 'The list is empty');
    IManage_File_Link__c link = links.get(0);
    System.assertEquals(
      link.ParentId__c,
      recordId,
      'ParentId__c has wrong value'
    );
    System.assertEquals(
      link.File_Link__c,
      fileLinkUrl,
      'File_Link__c has wrong value'
    );
    System.assertEquals(link.Version__c, vers, 'File_Link__c has wrong value');

    System.assert(count == 1, 'Wrong links count');
  }

  @isTest
  static void getFilesTest() {
    //insert parent Object
    Opportunity opp = new Opportunity(
      Name = 'Test Opportunity',
      Closedate = System.today(),
      StageName = 'Prospecting'
    );
    insert opp;

    //insert file
    String fileName = 'Test';
    String fileExt = 'txt';
    ContentVersion cv = new ContentVersion(
      ContentLocation = 'S', // S = Stored in Salesforce
      PathOnClient = fileName + '.' + fileExt,
      Title = 'Test',
      VersionData = Blob.valueof('Test content')
    );
    insert cv;
    ContentVersion contentVersion = [
      SELECT Id, ContentDocumentId
      FROM ContentVersion
      WHERE Id = :cv.Id
      LIMIT 1
    ];

    ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
      ContentDocumentId = contentVersion.ContentDocumentId,
      LinkedEntityId = opp.Id,
      ShareType = 'I', // Inferred permission
      Visibility = 'AllUsers'
    );
    insert contentDocumentLink;

    Test.startTest();
    List<SObject> files = IManageLinksAndFilesHelper.getFiles(opp.Id, 100, 0);
    Integer count = IManageLinksAndFilesHelper.getFilesCount(opp.Id);
    Test.stopTest();

    System.assert(files.size() > 0, 'The list is empty');
    SObject file = files.get(0);
    String fileTitle = (String) file.getSObject('ContentDocument').get('Title');
    String fileExtension = (String) file.getSObject('ContentDocument')
      .get('FileExtension');
    System.assertEquals(
      fileTitle,
      fileName,
      'Title has wrong value = ' +
      fileTitle +
      ', Expexted = ' +
      fileName
    );
    System.assertEquals(
      fileExtension,
      fileExt,
      'Extension has wrong value = ' +
      fileExtension +
      ', Expexted = ' +
      fileExt
    );
    System.assert(count == 1, 'Wrong files count');
  }
}

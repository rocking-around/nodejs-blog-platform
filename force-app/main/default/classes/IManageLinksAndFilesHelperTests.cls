@isTest
private class IManageLinksAndFilesHelperTests {
  @testSetup
  static void methodName() {
    //insert parent Object
    Opportunity opp = new Opportunity(
      Name = 'Test Opportunity',
      Closedate = System.today(),
      StageName = 'Prospecting'
    );
    insert opp;
  }

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

  static testMethod void deleteFileTest() {
    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
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

    System.assert(files.size() > 0, 'The list is empty');
    SObject file = files.get(0);

    String fileId = (Id) file.getSObject('ContentDocument').get('Id');
    IManageLinksAndFilesHelper.deleteFile(fileId);

    Integer count = IManageLinksAndFilesHelper.getFilesCount(opp.Id);
    Test.stopTest();

    System.assert(count == 0, 'File was not deleted');
  }

  static testMethod void deleteLinkTest() {
    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

    String fileLinkUrl = 'http://google.com?q=test';
    String vers = '2';
    IManage_File_Link__c fileLink = new IManage_File_Link__c(
      ParentId__c = opp.Id,
      Version__c = vers,
      File_Link__c = fileLinkUrl
    );
    insert fileLink;

    Test.startTest();
    List<IManage_File_Link__c> links = IManageLinksAndFilesHelper.getLinks(
      opp.Id,
      100,
      0
    );

    System.assert(links.size() > 0, 'The list is empty');
    IManage_File_Link__c link = links.get(0);

    IManageLinksAndFilesHelper.deleteLink(link.Id);
    Integer count = IManageLinksAndFilesHelper.getLinksCount(opp.Id);
    Test.stopTest();

    System.assert(count == 0, 'Link was not deleted');
  }

  static testMethod void isEnabledForRecordTest() {
    // add settings
    iManageDocumentSettings__c docSettings = new iManageDocumentSettings__c();
    docSettings.Calendar__c = true;
    docSettings.Task__c = false;
    docSettings.Intake_Document__c = true;
    docSettings.Matter_Document__c = true;
    docSettings.Matter__c = true;
    insert docSettings;

    Test.startTest();
    // '00U4H000011y36GUAQ', - MEETING
    Boolean isCalendarEnabled = IManageLinksAndFilesHelper.isEnabledForRecord(
      Id.valueOf('00U4H000011y36GUAQ')
    );
    // '00T4H00008mUsp7UAC', - ТАСК
    Boolean isTaskEnabled = IManageLinksAndFilesHelper.isEnabledForRecord(
      Id.valueOf('00T4H00008mUsp7UAC')
    );
    // 'a0L4x00000AF5VYEA1' - МАТТЕR
    //Boolean isMatterEnabled = IManageLinksAndFilesHelper.isEnabledForRecord(Id.valueOf('a0L4x00000AF5VYEA1'));
    Test.stopTest();

    System.assert(isCalendarEnabled, 'Calendar is enabled');
    System.assert(!isTaskEnabled, 'Task is not enabled');
    //System.assert(isMatterEnabled, 'Matter is enabled');
  }
}

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

  static testMethod void getFilesAndLinksPagedTest() {
    TestUtils.setupMockActiveLicense();

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

     String mName = 'Metadata Name';
     String mVers = '5';
     String mDocNumber = 'Metadata Doc #1';
     String mAuthor = 'Metadata Author1';
     String mDocClass = 'DOCUMENT';
     String mDocSubClass = 'SubDOCUMENT';

     iManageDocumentMetadata__c md = new iManageDocumentMetadata__c(
      EntityId__c = contentVersion.ContentDocumentId,
      Name = mName,
      Document_Version__c = mVers,
      DocNumber__c = mDocNumber,
      Document_Author__c = mAuthor,
      Document_Class__c = mDocClass,
      Document_SubClass__c = mDocSubClass
    );
    insert md;

    // Insert File_Link
    String fileLinkUrl = 'http://google.com?q=test';
    String vers = '2';
    IManage_File_Link__c fileLink = new IManage_File_Link__c(
      ParentId__c = opp.Id,
      Version__c = vers,
      File_Link__c = fileLinkUrl
    );

    insert fileLink;

    String mName2 = 'Metadata Name2';
    String mVers2 = '2';
    String mDocNumber2 = 'Metadata Doc #2';
    String mAuthor2 = 'Metadata Author2';
    String mDocClass2 = 'DOCUMENT2';
    String mDocSubClass2 = 'SubDOCUMENT2';

    iManageDocumentMetadata__c md2 = new iManageDocumentMetadata__c(
      EntityId__c = fileLink.Id,
      Name = mName2,
      Document_Version__c = mVers2,
      DocNumber__c = mDocNumber2,
      Document_Author__c = mAuthor2,
      Document_Class__c = mDocClass2,
      Document_SubClass__c = mDocSubClass2
    );
    insert md2;

    // Insert File_Link
    IManage_File_Link__c fileLink2 = new IManage_File_Link__c(
      ParentId__c = opp.Id,
      Version__c = vers,
      File_Link__c = fileLinkUrl
    );

    insert fileLink2;

    iManageDocumentMetadata__c md3 = new iManageDocumentMetadata__c(
      EntityId__c = fileLink2.Id,
      Name = mName2,
      Document_Version__c = mVers2,
      DocNumber__c = 'Metadata Doc #0',
      Document_Author__c = mAuthor2,
      Document_Class__c = mDocClass2,
      Document_SubClass__c = mDocSubClass2
    );
    insert md3;

    // Insert File_Link
    IManage_File_Link__c fileLink3 = new IManage_File_Link__c(
      ParentId__c = opp.Id,
      Version__c = vers,
      File_Link__c = fileLinkUrl
    );

    insert fileLink3;

    iManageDocumentMetadata__c md4 = new iManageDocumentMetadata__c(
      EntityId__c = fileLink3.Id,
      Name = mName2,
      Document_Version__c = mVers2,
      DocNumber__c = 'Metadata Doc #3',
      Document_Author__c = mAuthor2,
      Document_Class__c = mDocClass2,
      Document_SubClass__c = mDocSubClass2
    );
    insert md4;

    
    Test.startTest();
      GridData result = IManageLinksAndFilesHelper.getFilesAndLinksPaged(
        opp.Id, 2, 1, 'DocNumber__c', 'asc');
    Test.stopTest();

    System.assertEquals(2, result.Data.size(), 'Wrong files count');
    System.assertEquals(4, result.Total, 'Wrong files total');

    Map<String, Object> item1 = result.Data[0];
    System.assertEquals(contentVersion.ContentDocumentId, item1.get('Id'), 'Wrong Id');
    System.assertEquals('Test', item1.get('Title'), 'Wrong Title');
    System.assertEquals(opp.Id, item1.get('LinkedEntityId'), 'Wrong LinkedEntityId');
    System.assertEquals(fileExt, item1.get('FileExtension'), 'Wrong FileExtension');
    System.assertEquals(mName, item1.get('Name'), 'Wrong Name');
    System.assertEquals(mDocNumber, item1.get('DocNumber__c'), 'Wrong DocNumber__c');
    System.assertEquals(mDocClass, item1.get('Document_Class__c'), 'Wrong Document_Class__c');
    System.assertEquals(mDocSubClass, item1.get('Document_SubClass__c'), 'Wrong Document_SubClass__c');
    //System.assertEquals(mAuthor, item1.get('Document_Author__c'), 'Wrong Document_Author__c');

    Map<String, Object> item2 = result.Data[1];
    System.assertEquals(fileLink.Id, item2.get('Id'), 'Wrong Id');
    System.assertEquals(fileLinkUrl, item2.get('FileLink'), 'Wrong FileLink');
    System.assertEquals(opp.Id, item2.get('LinkedEntityId'), 'Wrong LinkedEntityId');
    System.assertEquals(mName2, item2.get('Name'), 'Wrong Name');
    System.assertEquals(mDocNumber2, item2.get('DocNumber__c'), 'Wrong DocNumber__c');
    System.assertEquals(mDocClass2, item2.get('Document_Class__c'), 'Wrong Document_Class__c');
    System.assertEquals(mDocSubClass2, item2.get('Document_SubClass__c'), 'Wrong Document_SubClass__c');
    //System.assertEquals(mAuthor2, item2.get('Document_Author__c'), 'Wrong Document_Author__c');
  }

  static testMethod void getLinksTest() {
    TestUtils.setupMockActiveLicense();

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
    TestUtils.setupMockActiveLicense();

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
    TestUtils.setupMockActiveLicense();

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
    TestUtils.setupMockActiveLicense();

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
    TestUtils.setupMockActiveLicense();

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
    // '00T4H00008mUsp7UAC', - ТАSК
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

  static testMethod void isEnabledForRecord2Test() {
    TestUtils.setupMockActiveLicense();

    // add settings
    iManageDocumentSettings__c docSettings = new iManageDocumentSettings__c();
    docSettings.Calendar__c = true;
    docSettings.Task__c = false;
    docSettings.Intake_Document__c = true;
    docSettings.Matter_Document__c = true;
    docSettings.Matter__c = true;
    insert docSettings;

    Test.startTest();
    // MEETING
    Boolean isCalendarEnabled = IManageLinksAndFilesHelper.isEnabledForRecord(
      'Event'
    );
    // ТАSК
    Boolean isTaskEnabled = IManageLinksAndFilesHelper.isEnabledForRecord(
      'Task'
    );
    // МАТТЕR
    Boolean isMatterEnabled = IManageLinksAndFilesHelper.isEnabledForRecord(
      'litify_pm__Matter__c'
    );
    Boolean isIntakeEnabled = IManageLinksAndFilesHelper.isEnabledForRecord(
      'litify_pm__Intake__c'
    );
    Boolean isNoteEnabled = IManageLinksAndFilesHelper.isEnabledForRecord(
      'litify_pm__lit_Note__c'
    );

    try {
      IManageLinksAndFilesHelper.isEnabledForRecord('NOT EXISTS');
    } catch (Exception ex) {
      System.assert(
        ex instanceof IManageExceptions.IManageSettingsException,
        'Wrong exception type'
      );
    }
    Test.stopTest();

    System.assert(isCalendarEnabled, 'Calendar is enabled');
    System.assert(!isTaskEnabled, 'Task is not enabled');
    System.assert(isMatterEnabled, 'Matter is enabled');
    System.assert(isIntakeEnabled, 'Intake is not enabled');
    System.assert(isNoteEnabled, 'Note is not enabled');
  }

  //Metadata Tests
  static testMethod void saveAndGetIManageDocumentsMetadataTest() {
    TestUtils.setupMockActiveLicense();

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

    String mName = 'Metadata Name';
    String mVers = '5';
    String mDocNumber = 'Metadata Doc #';
    String mAuthor = 'Metadata Author';
    String mDocClass = 'DOCUMENT';
    String mDocSubClass = 'SubDOCUMENT';
    Map<String, Object> metadata = new Map<String, Object>{
      'name' => mName,
      'version' => mVers,
      'document_number' => mDocNumber,
      'author' => mAuthor,
      'document_class' => mDocClass,
      'document_subclass' => mDocSubClass
    };
    Test.startTest();
    IManageLinksAndFilesHelper.saveIManageDocumentMetadata(
      fileLink.Id,
      metadata
    );
    List<Map<String, Object>> docsMetadata = IManageLinksAndFilesHelper.getIManageDocumentsMetadata(
      new List<Id>{ fileLink.Id }
    );
    Test.stopTest();

    System.assert(docsMetadata.size() > 0, 'Metadata not found');
    iManageDocumentMetadata__c docMetadata = (iManageDocumentMetadata__c) createSObjectFromMap(
      'iManageDocumentMetadata__c',
      docsMetadata.get(0)
    );
    System.assertEquals(
      docMetadata.EntityId__c,
      fileLink.Id,
      'EntityId__c has wrong value'
    );
    System.assertEquals(docMetadata.Name, mName, 'Name has wrong value');
    System.assertEquals(
      docMetadata.Document_Version__c,
      mVers,
      'Document_Version__c has wrong value'
    );
    System.assertEquals(
      docMetadata.DocNumber__c,
      mDocNumber,
      'DocNumber__c has wrong value'
    );
    System.assertEquals(
      docMetadata.Document_Class__c,
      mDocClass,
      'Document_Class__c has wrong value'
    );
    System.assertEquals(
      docMetadata.Document_SubClass__c,
      mDocSubClass,
      'Document_SubClass__c has wrong value'
    );
    System.assertEquals(
      docMetadata.Document_Author__c,
      mAuthor,
      'Document_Author__c has wrong value'
    );
  }

  static testMethod void changeIManageDocumentMetadataEntityTest() {
    TestUtils.setupMockActiveLicense();

    // Insert File_Link
    String recordId = '00U4H000011y36GUAQ';
    String fileLinkUrl = 'http://google.com?q=test';
    String vers = '2';
    IManage_File_Link__c fileLink1 = new IManage_File_Link__c(
      ParentId__c = recordId,
      Version__c = vers,
      File_Link__c = fileLinkUrl
    );
    insert fileLink1;

    IManage_File_Link__c fileLink2 = new IManage_File_Link__c(
      ParentId__c = recordId,
      Version__c = vers,
      File_Link__c = fileLinkUrl
    );

    insert fileLink2;

    String mName = 'Metadata Name';
    String mVers = '5';
    String mDocNumber = 'Metadata Doc #';
    String mAuthor = 'Metadata Author';
    String mDocClass = 'DOCUMENT';
    String mDocSubClass = 'SubDOCUMENT';
    Map<String, Object> metadata = new Map<String, Object>{
      'name' => mName,
      'version' => mVers,
      'document_number' => mDocNumber,
      'author' => mAuthor,
      'document_class' => mDocClass,
      'document_subclass' => mDocSubClass
    };
    Test.startTest();
    IManageLinksAndFilesHelper.saveIManageDocumentMetadata(
      fileLink1.Id,
      metadata
    );
    List<Map<String, Object>> docsMetadata1 = IManageLinksAndFilesHelper.getIManageDocumentsMetadata(
      new List<Id>{ fileLink1.Id, fileLink2.Id }
    );

    IManageLinksAndFilesHelper.changeIManageDocumentMetadataEntity(
      fileLink1.Id,
      fileLink2.Id
    );
    List<Map<String, Object>> docsMetadata2 = IManageLinksAndFilesHelper.getIManageDocumentsMetadata(
      new List<Id>{ fileLink1.Id, fileLink2.Id }
    );
    Test.stopTest();

    System.assert(
      docsMetadata1.size() == 1,
      'Expecten only 1 Metadata information'
    );
    System.assert(
      docsMetadata2.size() == 1,
      'Expecten only 1 Metadata information'
    );
    iManageDocumentMetadata__c docMetadata1 = (iManageDocumentMetadata__c) createSObjectFromMap(
      'iManageDocumentMetadata__c',
      docsMetadata1.get(0)
    );
    iManageDocumentMetadata__c docMetadata2 = (iManageDocumentMetadata__c) createSObjectFromMap(
      'iManageDocumentMetadata__c',
      docsMetadata2.get(0)
    );
    System.assertEquals(
      docMetadata1.EntityId__c,
      fileLink1.Id,
      'EntityId__c has wrong value'
    );
    System.assertEquals(
      docMetadata2.EntityId__c,
      fileLink2.Id,
      'EntityId__c has wrong value'
    );
    System.assertEquals(docMetadata1.Name, mName, 'Name has wrong value');
    System.assertEquals(docMetadata2.Name, mName, 'Name has wrong value');
    System.assertEquals(
      docMetadata1.Document_Version__c,
      mVers,
      'Document_Version__c has wrong value'
    );
    System.assertEquals(
      docMetadata2.Document_Version__c,
      mVers,
      'Document_Version__c has wrong value'
    );
    System.assertEquals(
      docMetadata1.DocNumber__c,
      mDocNumber,
      'DocNumber__c has wrong value'
    );
    System.assertEquals(
      docMetadata2.DocNumber__c,
      mDocNumber,
      'DocNumber__c has wrong value'
    );
    System.assertEquals(
      docMetadata1.Document_Class__c,
      mDocClass,
      'Document_Class__c has wrong value'
    );
    System.assertEquals(
      docMetadata2.Document_Class__c,
      mDocClass,
      'Document_Class__c has wrong value'
    );
    System.assertEquals(
      docMetadata1.Document_SubClass__c,
      mDocSubClass,
      'Document_SubClass__c has wrong value'
    );
    System.assertEquals(
      docMetadata2.Document_SubClass__c,
      mDocSubClass,
      'Document_SubClass__c has wrong value'
    );
    System.assertEquals(
      docMetadata1.Document_Author__c,
      mAuthor,
      'Document_Author__c has wrong value'
    );
    System.assertEquals(
      docMetadata2.Document_Author__c,
      mAuthor,
      'Document_Author__c has wrong value'
    );
  }

  @IsTest
  static void folderLinksCRUDTest() {
    TestUtils.setupMockActiveLicense();

    // insert folder link
    String entityId = TestUtils.getFakeId(Opportunity.SObjectType);
    String imFolderId = 'ACTIVE!3038';
    String imLibrary = 'ACTIVE';
    String name = 'Test';
    IManage_Folder_Link__c sobj = new IManage_Folder_Link__c(
        EntityId__c = entityId,
        iManage_Id__c = imFolderId,
        iManage_Library__c = imLibrary,
        Name = name
      );
    insert sobj;

    Test.startTest();
    List<IManage_Folder_Link__c> result = IManageLinksAndFilesHelper.getFolderLinks(
      entityId,
      10,
      0
    );
    IManage_Folder_Link__c result0 = result.get(0);
    Integer count = IManageLinksAndFilesHelper.getFolderLinksCount(entityId);

    IManageLinksAndFilesHelper.deleteFolderLink(sobj.Id);

    List<IManage_Folder_Link__c> result2 = IManageLinksAndFilesHelper.getFolderLinks(
      entityId,
      10,
      0
    );
    Test.stopTest();

    System.assert(count > 0, 'Wrong Folder links count');
    System.assert(result0.EntityId__c == entityId, 'Wrong EntityId__c value');
    System.assert(result0.iManage_Id__c == imFolderId, 'Wrong iManage_Id__c value');
    System.assert(result0.iManage_Library__c == imLibrary, 'Wrong iManage_Library__c value');
    System.assert(result0.Name == name, 'Wrong Name value');
    // del result
    System.assert(result2.size() == 0, 'Wrong Folder links count after delete operation');
  }

  @IsTest
  static void saveFolderLinkFromIManageTest() {
    String entityId = TestUtils.getFakeId(Opportunity.SObjectType);
    String imFolderId = 'test_f_1';
    String imLib = 'ACTIVE';
    String imFolderName = 'test_f_Name';

    Map<String, Object> folderData = new Map<String, String> {
      'id' => imFolderId,
      'database' => imLib,
      'name' => imFolderName
    };

    Test.startTest();
    Id linkId = IManageLinksAndFilesHelper.saveFolderLinkFromIManage(
      entityId,
      folderData
    );

    IManage_Folder_Link__c result = [
      SELECT Id, LastModifiedDate, Name, EntityId__c, iManage_Id__c, iManage_Library__c
      FROM IManage_Folder_Link__c
      WHERE Id = :linkId
    ];
    Test.stopTest();

    System.assert(result.Id == linkId, 'Wrong Id value');
    System.assert(result.EntityId__c == entityId, 'Wrong EntityId__c value');
    System.assert(result.iManage_Id__c == imFolderId, 'Wrong iManage_Id__c value');
    System.assert(result.iManage_Library__c == imLib, 'Wrong iManage_Library__c value');
    System.assert(result.Name == imFolderName, 'Wrong Name value');
  }

  @IsTest
  static void deleteIManageDocumentMetadataTest() {
    TestUtils.setupMockActiveLicense();
    String entityId = TestUtils.getFakeId(Opportunity.SObjectType);
    iManageDocumentMetadata__c md = new iManageDocumentMetadata__c(
      EntityId__c = entityId,
      Name = 'test name',
      Document_Version__c = 'v1',
      DocNumber__c = '1',
      Document_Author__c = 'author',
      Document_Class__c = 'd_class',
      Document_SubClass__c = 'd_subclass'
    );
    insert md;

    Test.startTest();
    Integer countAfterIns = Database.countQuery('select count() from iManageDocumentMetadata__c');

    IManageLinksAndFilesHelper.deleteIManageDocumentMetadata(entityId);

    Integer countAfterDel = Database.countQuery('select count() from iManageDocumentMetadata__c');
    Test.stopTest();

    System.assert(countAfterIns > 0, 'Wrong count after Insert operation');
    System.assert(countAfterDel == 0, 'Wrong count after Delete operation');
  }

  private static SObject createSObjectFromMap(
    String sobjectName,
    Map<String, Object> fields
  ) {
    SObject obj = (SObject) Type.forName('Schema', sobjectName).newInstance();
    for (String key : fields.keySet()) {
      obj.put(key, fields.get(key));
    }
    return obj;
  }
}

@isTest
private class IManageCsvHelperTests {
  @isTest
  static void isCsvExportEnabledTest() {
    iManageSettings__c mcSetting = new iManageSettings__c();
    mcSetting.Client_Id__c = 'val1';
    mcSetting.ClientField__c = 'val2';
    mcSetting.MatterField__c = 'val3';
    mcSetting.Url__c = 'val4';
    mcSetting.Enable_CSV_Export__c = true;
    insert mcSetting;

    Boolean value = IManageCsvHelper.isCsvExportEnabled();
    System.assert(
      value,
      'IManageCsvHelper.isCsvExportEnabled() has wrong value'
    );
  }

  @isTest
  static void getEntitiesByIdsTest() {
    TestUtils.setupMockActiveLicense();
    // Create mappoing
    IManageMapping mapping = new IManageMapping();
    mapping.EntityType = 'Opportunity';
    mapping.EntityMatterIdObjectField = 'Opportunity';
    mapping.MatterIdField = 'Id';
    mapping.MatterNameField = 'Name';
    mapping.EntityClientIdObjectField = 'AccountId';
    mapping.ClientIdField = 'Id';
    mapping.ClientNameField = 'Name';

    // Create Account
    Account acc = new Account(Name = 'Donald Duck');
    if (TestUtils.isFieldExist('Account', 'litify_pm__Last_Name__c')) {
      acc.litify_pm__Last_Name__c = 'Duck';
    }
    insert acc;

    // Create oppporunity
    Opportunity opp = new Opportunity(
      AccountId = acc.Id,
      Name = 'Test Opportunity Name',
      StageName = '100',
      CloseDate = system.now().addDays(30).date()
    );
    insert opp;

    Id oppId = opp.Id;
    Id accId = acc.Id;
    opp = [
      SELECT Id, LastModifiedDate, Name
      FROM Opportunity
      WHERE Id = :oppId
      LIMIT 1
    ];
    acc = [
      SELECT Id, LastModifiedDate, Name
      FROM Account
      WHERE Id = :accId
      LIMIT 1
    ];

    Set<Id> ids = new Set<Id>{ oppId };

    Test.startTest();
    List<IManageCsvHelper.CsvRow> csvRows = IManageCsvHelper.getEntitiesByIds(
      mapping,
      ids
    );
    Test.stopTest();

    System.assert(
      csvRows.size() > 0,
      'IManageCsvHelper.getEntitiesByIds() return empty List'
    );

    IManageCsvHelper.CsvRow row = csvRows.get(0);
    System.assert(row.Id == opp.Id, 'Id has wrong value');
    System.assert(
      row.LastModifiedDate == opp.LastModifiedDate,
      'LastModifiedDate has wrong value: ' +
      String.valueOf(row.LastModifiedDate) +
      ' != ' +
      String.valueOf(opp.LastModifiedDate)
    );
    System.assert(
      row.MatterId == String.valueOf(opp.Id),
      'MatterId has wrong value'
    );
    System.assert(row.MatterName == opp.Name, 'MatterName has wrong value');
    System.assert(
      row.MatterLastModifiedDate == opp.LastModifiedDate,
      'MatterLastModifiedDate has wrong value'
    );
    System.assert(
      row.ClientId == String.valueOf(acc.Id),
      'ClientId has wrong value'
    );
    System.assert(row.ClientName == acc.Name, 'ClientName has wrong value');
    System.assert(
      row.ClientLastModifiedDate == acc.LastModifiedDate,
      'ClientLastModifiedDate has wrong value'
    );
  }

  @isTest
  static void getDataTest() {
    TestUtils.setupMockActiveLicense();

    // Create mappoing
    iManageSettings__c mapping = new iManageSettings__c(
      Client_Id__c = 'val1',
      ClientField__c = 'val2',
      MatterField__c = 'val3',
      Url__c = 'val4',
      Enable_CSV_Export__c = true,
      Mapping_EntityType__c = 'Opportunity',
      Mapping_EntityMatterIdObjectField__c = 'Opportunity',
      Mapping_MatterIdField__c = 'Id',
      Mapping_MatterNameField__c = 'Name',
      Mapping_EntityClientIdObjectField__c = 'AccountId',
      Mapping_ClientIdField__c = 'Id',
      Mapping_ClientNameField__c = 'Name'
    );
    insert mapping;

    // Create Account
    Account acc = new Account(Name = 'Donald Duck');
    if (TestUtils.isFieldExist('Account', 'litify_pm__Last_Name__c')) {
      acc.litify_pm__Last_Name__c = 'Duck';
    }
    insert acc;

    // Create oppporunity
    Opportunity opp = new Opportunity(
      AccountId = acc.Id,
      Name = 'Test Opportunity Name',
      StageName = '100',
      CloseDate = system.now().addDays(30).date()
    );
    insert opp;

    Id oppId = opp.Id;
    Id accId = acc.Id;
    opp = [
      SELECT Id, LastModifiedDate, Name
      FROM Opportunity
      WHERE Id = :oppId
      LIMIT 1
    ];
    acc = [
      SELECT Id, LastModifiedDate, Name
      FROM Account
      WHERE Id = :accId
      LIMIT 1
    ];

    Set<Id> ids = new Set<Id>{ oppId };

    Test.startTest();
    List<IManageCsvHelper.CsvRow> csvRows = IManageCsvHelper.getData(
      System.now().addDays(-10).date(),
      System.now().addDays(10).date()
    );
    Test.stopTest();

    System.assert(
      csvRows.size() > 0,
      'IManageCsvHelper.getData() return empty List'
    );

    IManageCsvHelper.CsvRow row = csvRows.get(0);
    System.assert(row.Id == opp.Id, 'Id has wrong value');
    System.assert(
      row.LastModifiedDate == opp.LastModifiedDate,
      'LastModifiedDate has wrong value: ' +
      String.valueOf(row.LastModifiedDate) +
      ' != ' +
      String.valueOf(opp.LastModifiedDate)
    );
    System.assert(
      row.MatterId == String.valueOf(opp.Id),
      'MatterId has wrong value'
    );
    System.assert(row.MatterName == opp.Name, 'MatterName has wrong value');
    System.assert(
      row.MatterLastModifiedDate == opp.LastModifiedDate,
      'MatterLastModifiedDate has wrong value'
    );
    System.assert(
      row.ClientId == String.valueOf(acc.Id),
      'ClientId has wrong value'
    );
    System.assert(row.ClientName == acc.Name, 'ClientName has wrong value');
    System.assert(
      row.ClientLastModifiedDate == acc.LastModifiedDate,
      'ClientLastModifiedDate has wrong value'
    );
  }

  @isTest
  static void getFieldRelationshipNameTest() {
    TestUtils.setupMockActiveLicense();

    String nullValue = IManageCsvHelper.getFieldRelationshipName(
      'Opportunity',
      'Id'
    );
    String value = IManageCsvHelper.getFieldRelationshipName(
      'Opportunity',
      'AccountId'
    );
    System.assert(nullValue == null, 'Wrong relationship name');
    System.assertEquals(value, 'Account', 'Wrong relationship name');
  }

  @isTest
  static void getFieldReferenceNameTest() {
    TestUtils.setupMockActiveLicense();

    String value = IManageCsvHelper.getFieldReferenceName(
      'Opportunity',
      'AccountId'
    );
    System.assertEquals(value, 'Account', 'Wrong reference name');
  }
}

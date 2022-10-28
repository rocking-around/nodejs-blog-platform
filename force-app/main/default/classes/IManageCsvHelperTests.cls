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
    // Create mappoing
    IManageMapping__c mapping = new IManageMapping__c(
      EntityType__c = 'Opportunity',
      EntityMatterIdObjectField__c = 'Opportunity',
      MatterIdField__c = 'Id',
      MatterNameField__c = 'Name',
      EntityClientIdObjectField__c = 'AccountId',
      ClientIdField__c = 'Id',
      ClientNameField__c = 'Name'
    );
    insert mapping;

    // Create Account
    Account acc = new Account(Name = 'Donald Duck');
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
    // Create mappoing
    IManageMapping__c mapping = new IManageMapping__c(
      EntityType__c = 'Opportunity',
      EntityMatterIdObjectField__c = 'Opportunity',
      MatterIdField__c = 'Id',
      MatterNameField__c = 'Name',
      EntityClientIdObjectField__c = 'AccountId',
      ClientIdField__c = 'Id',
      ClientNameField__c = 'Name'
    );
    insert mapping;

    // Create Account
    Account acc = new Account(Name = 'Donald Duck');
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
      null,
      System.now().addDays(-10).date(),
      System.now().addDays(1).date()
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
    String value = IManageCsvHelper.getFieldReferenceName(
      'Opportunity',
      'AccountId'
    );
    System.assertEquals(value, 'Account', 'Wrong reference name');
  }
}

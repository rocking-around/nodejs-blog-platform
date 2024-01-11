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
    mapping.EntityClientIdObjectField = 'Opportunity';
    mapping.ClientIdField = 'Id';
    mapping.ClientNameField = 'Name';

    // Create oppporunity
    Opportunity opp = new Opportunity(
      Name = 'Test Opportunity Name',
      StageName = '100',
      CloseDate = system.now().addDays(30).date()
    );
    insert opp;

    Id oppId = opp.Id;
    opp = [
      SELECT Id, LastModifiedDate, Name
      FROM Opportunity
      WHERE Id = :oppId
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
      row.ClientId == String.valueOf(opp.Id),
      'ClientId has wrong value'
    );
    System.assert(row.ClientName == opp.Name, 'ClientName has wrong value');
    System.assert(
      row.ClientLastModifiedDate == opp.LastModifiedDate,
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
      Mapping_EntityClientIdObjectField__c = 'Opportunity',
      Mapping_ClientIdField__c = 'Id',
      Mapping_ClientNameField__c = 'Name'
    );
    insert mapping;

    // Create oppporunity
    Opportunity opp = new Opportunity(
      Name = 'Test Opportunity Name',
      StageName = '100',
      CloseDate = system.now().addDays(30).date()
    );
    insert opp;

    Id oppId = opp.Id;
    opp = [
      SELECT Id, LastModifiedDate, Name
      FROM Opportunity
      WHERE Id = :oppId
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
      row.ClientId == String.valueOf(opp.Id),
      'ClientId has wrong value'
    );
    System.assert(row.ClientName == opp.Name, 'ClientName has wrong value');
    System.assert(
      row.ClientLastModifiedDate == opp.LastModifiedDate,
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
}

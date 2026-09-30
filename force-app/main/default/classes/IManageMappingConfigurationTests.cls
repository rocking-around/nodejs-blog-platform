@IsTest
private class IManageMappingConfigurationTests {
  @IsTest
  static void savesReadsAndDeletesMappingRows() {
    TestUtils.setupMockActiveLicense();
    IManageMapping opportunityMapping = mappingDto('Opportunity');

    Test.startTest();
    IManageMapping saved = IManageMappingHelper.saveMappingConfiguration(
      opportunityMapping
    );
    IManageMapping loaded = IManageMappingHelper.getMappingSettings(
      'Opportunity'
    );
    IManageMappingHelper.deleteMappingConfiguration(saved.MappingId);
    Test.stopTest();

    System.assertNotEquals(null, saved.MappingId);
    System.assertEquals('Opportunity', loaded.EntityType);
    System.assertEquals('AccountId', loaded.EntityClientIdObjectField);
    System.assertEquals('Description', loaded.WsTemplateField);
    System.assertEquals(true, loaded.UseOnlyCustom2);
    System.assertEquals(
      0,
      [SELECT COUNT() FROM IManage_Mapping_Configuration__c]
    );
  }

  @IsTest
  static void selectsMappingByRecordType() {
    insert mappingRecord('Opportunity', 'Opportunity');
    insert mappingRecord('Account', 'Account');
    Opportunity opportunity = new Opportunity(
      Name = 'Mapping test',
      CloseDate = System.today(),
      StageName = 'Prospecting'
    );
    insert opportunity;

    IManageMapping selected = IManageMappingHelper.getMappingSettingsForEntityId(
      opportunity.Id
    );

    System.assertEquals('Opportunity', selected.EntityType);
  }

  @IsTest
  static void emptyGridDoesNotReadLegacySettings() {
    insert new iManageSettings__c(
      Client_Id__c = 'test-client',
      Url__c = 'https://example.invalid',
      Customer_Id__c = 'test-customer',
      Mapping_EntityType__c = 'Opportunity',
      Mapping_EntityClientIdObjectField__c = 'Opportunity',
      Mapping_ClientIdField__c = 'Id',
      Mapping_EntityMatterIdObjectField__c = 'Opportunity',
      Mapping_MatterIdField__c = 'Id'
    );

    System.assertEquals(0, IManageMappingHelper.getAllMappingSettings().size());
    try {
      IManageMappingHelper.getMappingSettings('Opportunity');
      System.assert(false, 'A missing mapping must raise an error.');
    } catch (IManageExceptions.IManageMappingException error) {
      System.assert(error.getMessage().contains('no mapping'));
    }
  }

  @IsTest
  static void rejectsDuplicateEntityTypeWithAControlledError() {
    TestUtils.setupMockActiveLicense();
    insert mappingRecord('Opportunity', 'Opportunity');

    try {
      IManageMappingHelper.saveMappingConfiguration(mappingDto('Opportunity'));
      System.assert(false, 'A duplicate entity mapping must be rejected.');
    } catch (AuraHandledException error) {
      System.assertNotEquals(null, error);
    }

    System.assertEquals(
      1,
      [SELECT COUNT() FROM IManage_Mapping_Configuration__c]
    );
  }

  @IsTest
  static void savesMappingWithoutOptionalNameFields() {
    TestUtils.setupMockActiveLicense();
    IManageMapping mapping = mappingDto('Opportunity');
    mapping.ClientNameField = null;
    mapping.MatterNameField = null;

    IManageMappingHelper.saveMappingConfiguration(mapping);

    List<IManage_Mapping_Configuration__c> rows = [
      SELECT Entity_Type__c, Client_Name_Field__c, Matter_Name_Field__c
      FROM IManage_Mapping_Configuration__c
    ];
    System.assertEquals(
      1,
      rows.size(),
      'Name fields are optional and must not block a save.'
    );
    System.assertEquals(null, rows[0].Client_Name_Field__c);
    System.assertEquals(null, rows[0].Matter_Name_Field__c);
  }

  @IsTest
  static void rejectsMappingWithoutIdentifierFields() {
    TestUtils.setupMockActiveLicense();
    IManageMapping mapping = mappingDto('Opportunity');
    mapping.ClientIdField = null;

    try {
      IManageMappingHelper.saveMappingConfiguration(mapping);
      System.assert(false, 'A missing identifier field must be rejected.');
    } catch (AuraHandledException error) {
      System.assertNotEquals(null, error);
    }

    System.assertEquals(
      0,
      [SELECT COUNT() FROM IManage_Mapping_Configuration__c]
    );
  }

  private static IManageMapping mappingDto(String entityType) {
    IManageMapping mapping = new IManageMapping();
    mapping.EntityType = entityType;
    mapping.EntityClientIdObjectField = 'AccountId';
    mapping.ClientIdField = 'Id';
    mapping.ClientNameField = 'Name';
    mapping.EntityMatterIdObjectField = entityType;
    mapping.MatterIdField = 'Id';
    mapping.MatterNameField = 'Name';
    mapping.WsTemplateField = 'Description';
    mapping.LibraryField = 'Type';
    mapping.UseOnlyCustom2 = true;
    return mapping;
  }

  private static IManage_Mapping_Configuration__c mappingRecord(
    String entityType,
    String objectField
  ) {
    return new IManage_Mapping_Configuration__c(
      Entity_Type__c = entityType,
      Entity_Client_Id_Object_Field__c = objectField,
      Client_Id_Field__c = 'Id',
      Entity_Matter_Id_Object_Field__c = objectField,
      Matter_Id_Field__c = 'Id'
    );
  }
}

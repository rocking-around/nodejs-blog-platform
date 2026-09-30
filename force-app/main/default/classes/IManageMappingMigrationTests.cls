@IsTest
private class IManageMappingMigrationTests {
  @IsTest
  static void migratesLegacyMappingWithoutChangingLegacySettings() {
    iManageSettings__c legacy = new iManageSettings__c(
      Client_Id__c = 'test-client',
      Url__c = 'https://example.invalid',
      Customer_Id__c = 'test-customer',
      Mapping_EntityType__c = 'Opportunity',
      Mapping_EntityClientIdObjectField__c = 'AccountId',
      Mapping_ClientIdField__c = 'Id',
      Mapping_ClientNameField__c = 'Name',
      Mapping_EntityMatterIdObjectField__c = 'Opportunity',
      Mapping_MatterIdField__c = 'Id',
      Mapping_MatterNameField__c = 'Name',
      Mapping_WSTemplateField__c = 'Description',
      Mapping_LibraryField__c = 'Type',
      iManage_UseOnlyCustom2__c = true
    );
    insert legacy;

    Test.startTest();
    IManageMappingMigration.migrateForUpgrade(new Version(2, 80));
    Test.stopTest();

    IManage_Mapping_Configuration__c migrated = [
      SELECT
        Entity_Type__c,
        Entity_Client_Id_Object_Field__c,
        Client_Id_Field__c,
        Client_Name_Field__c,
        Entity_Matter_Id_Object_Field__c,
        Matter_Id_Field__c,
        Matter_Name_Field__c,
        Workspace_Template_Field__c,
        Library_Field__c,
        Use_Only_Custom2__c
      FROM IManage_Mapping_Configuration__c
    ];
    System.assertEquals('Opportunity', migrated.Entity_Type__c);
    System.assertEquals('AccountId', migrated.Entity_Client_Id_Object_Field__c);
    System.assertEquals('Id', migrated.Client_Id_Field__c);
    System.assertEquals('Name', migrated.Client_Name_Field__c);
    System.assertEquals(
      'Opportunity',
      migrated.Entity_Matter_Id_Object_Field__c
    );
    System.assertEquals('Id', migrated.Matter_Id_Field__c);
    System.assertEquals('Name', migrated.Matter_Name_Field__c);
    System.assertEquals('Description', migrated.Workspace_Template_Field__c);
    System.assertEquals('Type', migrated.Library_Field__c);
    System.assertEquals(true, migrated.Use_Only_Custom2__c);

    iManageSettings__c unchanged = iManageSettings__c.getOrgDefaults();
    System.assertEquals('Opportunity', unchanged.Mapping_EntityType__c);
    System.assertEquals(
      'AccountId',
      unchanged.Mapping_EntityClientIdObjectField__c
    );
  }

  @IsTest
  static void existingGridDataPreventsMigration() {
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
    insert mappingRecord('Account');

    IManageMappingMigration.migrateLegacyMapping();

    List<IManage_Mapping_Configuration__c> rows = [
      SELECT Entity_Type__c
      FROM IManage_Mapping_Configuration__c
    ];
    System.assertEquals(1, rows.size());
    System.assertEquals('Account', rows[0].Entity_Type__c);
  }

  @IsTest
  static void versionGateRunsOnlyForLegacyUpgrade() {
    System.assertEquals(
      false,
      IManageMappingMigration.isUpgradeFromLegacyVersion(null)
    );
    System.assertEquals(
      true,
      IManageMappingMigration.isUpgradeFromLegacyVersion(new Version(2, 80))
    );
    System.assertEquals(
      false,
      IManageMappingMigration.isUpgradeFromLegacyVersion(new Version(2, 81))
    );
  }

  @IsTest
  static void incompleteLegacyMappingDoesNotCreateGridRow() {
    insert new iManageSettings__c(
      Client_Id__c = 'test-client',
      Url__c = 'https://example.invalid',
      Customer_Id__c = 'test-customer',
      Mapping_EntityType__c = 'litify_pm__Matter__c'
    );

    IManageMappingMigration.migrateLegacyMapping();

    System.assertEquals(
      0,
      [SELECT COUNT() FROM IManage_Mapping_Configuration__c]
    );
  }

  @IsTest
  static void migratesLegacyMappingWithoutNameFields() {
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

    IManageMappingMigration.migrateLegacyMapping();

    List<IManage_Mapping_Configuration__c> rows = [
      SELECT Entity_Type__c, Client_Name_Field__c, Matter_Name_Field__c
      FROM IManage_Mapping_Configuration__c
    ];
    System.assertEquals(
      1,
      rows.size(),
      'A legacy mapping without name fields must still migrate.'
    );
    System.assertEquals('Opportunity', rows[0].Entity_Type__c);
    System.assertEquals(null, rows[0].Client_Name_Field__c);
    System.assertEquals(null, rows[0].Matter_Name_Field__c);
  }

  @IsTest
  static void migratesDefaultEntityTypeWithOptionalSettingOnly() {
    insert new iManageSettings__c(
      Client_Id__c = 'test-client',
      Url__c = 'https://example.invalid',
      Customer_Id__c = 'test-customer',
      Mapping_EntityType__c = 'litify_pm__Matter__c',
      iManage_UseOnlyCustom2__c = true
    );

    IManageMappingMigration.migrateLegacyMapping();

    List<IManage_Mapping_Configuration__c> rows = [
      SELECT Entity_Type__c, Use_Only_Custom2__c, Client_Id_Field__c
      FROM IManage_Mapping_Configuration__c
    ];
    System.assertEquals(
      1,
      rows.size(),
      'An explicit optional setting is user data and must be preserved.'
    );
    System.assertEquals('litify_pm__Matter__c', rows[0].Entity_Type__c);
    System.assertEquals(true, rows[0].Use_Only_Custom2__c);
    System.assertEquals(null, rows[0].Client_Id_Field__c);
  }

  @IsTest
  static void blankEntityTypeSkipsMigrationAndLeavesDiagnostic() {
    insert new iManageSettings__c(
      Client_Id__c = 'test-client',
      Url__c = 'https://example.invalid',
      Customer_Id__c = 'test-customer',
      Verbose_Logging__c = false,
      Mapping_EntityType__c = null,
      Mapping_LibraryField__c = 'Type'
    );

    IManageMappingMigration.migrateLegacyMapping();

    System.assertEquals(
      0,
      [SELECT COUNT() FROM IManage_Mapping_Configuration__c],
      'A blank entity type cannot identify a row to create.'
    );
    System.assertEquals(
      'Type',
      iManageSettings__c.getOrgDefaults().Mapping_LibraryField__c,
      'Legacy settings must survive a skipped migration.'
    );

    List<Log__c> diagnostics = [SELECT Value__c FROM Log__c];
    System.assertEquals(
      1,
      diagnostics.size(),
      'The diagnostic must be written even with Verbose Logging off.'
    );
    System.assert(
      diagnostics[0].Value__c.contains('Mapping_EntityType__c'),
      'The diagnostic must name the setting that blocked the transfer.'
    );
  }

  private static IManage_Mapping_Configuration__c mappingRecord(
    String entityType
  ) {
    return new IManage_Mapping_Configuration__c(
      Entity_Type__c = entityType,
      Entity_Client_Id_Object_Field__c = entityType,
      Client_Id_Field__c = 'Id',
      Entity_Matter_Id_Object_Field__c = entityType,
      Matter_Id_Field__c = 'Id'
    );
  }
}

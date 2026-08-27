@isTest
private class ColeEServiceApiTests {
  @isTest
  static void returnsConfiguredClientAndMatterIds() {
    TestUtils.setupMockActiveLicense();
    Opportunity opportunity = new Opportunity(
      Name = 'Cole eService test',
      CloseDate = System.today(),
      StageName = 'Prospecting'
    );
    insert opportunity;
    insert new iManageSettings__c(
      Client_Id__c = 'test-client',
      Customer_Id__c = '337',
      Url__c = 'https://cloudimanage.com',
      Mapping_EntityType__c = 'Opportunity',
      Mapping_EntityMatterIdObjectField__c = 'Opportunity',
      Mapping_MatterIdField__c = 'Id',
      Mapping_MatterNameField__c = 'Name',
      Mapping_EntityClientIdObjectField__c = 'Opportunity',
      Mapping_ClientIdField__c = 'StageName',
      Mapping_ClientNameField__c = 'Name'
    );
    IManageMappingMigration.migrateLegacyMapping();

    Test.startTest();
    Map<String, String> result = ColeEServiceApi.getClientMatterIds(
      opportunity.Id
    );
    Test.stopTest();

    System.assertEquals('Prospecting', result.get('clientId'));
    System.assertEquals(String.valueOf(opportunity.Id), result.get('matterId'));
  }

  @isTest
  static void writesAndFlushesLogs() {
    insert new iManageSettings__c(
      Client_Id__c = 'test-client',
      Customer_Id__c = '337',
      Url__c = 'https://cloudimanage.com',
      Verbose_Logging__c = true
    );

    Test.startTest();
    ColeEServiceApi.logInfo('Cole eService info');
    ColeEServiceApi.logError('Cole eService error');
    ColeEServiceApi.flushLogs();
    Test.stopTest();

    List<Log__c> logs = [SELECT Value__c FROM Log__c];
    System.assertEquals(1, logs.size());
    System.assert(logs[0].Value__c.contains('Cole eService info'));
    System.assert(logs[0].Value__c.contains('Cole eService error'));
  }
}

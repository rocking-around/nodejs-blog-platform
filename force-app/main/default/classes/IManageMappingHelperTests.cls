@isTest
private class IManageMappingHelperTests {
  @isTest
  static void getMappingTest_positive() {
    IManageMapping__c testData = new IManageMapping__c(
      EntityType__c = 'Opportunity',
      EntityMatterIdObjectField__c = 'Opportunity',
      MatterIdField__c = 'Id',
      EntityClientIdObjectField__c = 'CreatedById',
      ClientIdField__c = 'Id'
    );

    insert testData;

    Test.startTest();
    IManageMapping__c mapping = IManageMappingHelper.getMapping('Opportunity');
    Test.stopTest();

    System.assert(
      mapping.EntityType__c == testData.EntityType__c,
      'An EntityType__c has wrong value'
    );
    System.assertEquals(
      mapping.EntityMatterIdObjectField__c,
      testData.EntityMatterIdObjectField__c,
      'An EntityMatterIdObjectField__c has wrong value'
    );
  }

  @isTest
  static void getMappingTestWithException() {
    IManageMapping__c testData1 = new IManageMapping__c(
      EntityType__c = 'Opportunity',
      EntityMatterIdObjectField__c = 'Opportunity',
      MatterIdField__c = 'Id',
      EntityClientIdObjectField__c = 'CreatedById',
      ClientIdField__c = 'Id'
    );

    IManageMapping__c testData2 = new IManageMapping__c(
      EntityType__c = 'Account',
      EntityMatterIdObjectField__c = 'Account',
      MatterIdField__c = 'Id',
      EntityClientIdObjectField__c = 'Account',
      ClientIdField__c = 'Id'
    );

    insert testData1;
    insert testData2;

    Test.startTest();
    try {
      IManageMapping__c mapping = IManageMappingHelper.getMapping('Opportunity');
    } catch (Exception ex) {
      System.assert(
        ex instanceof IManageExceptions.ManageMappingException,
        'Exception is not a ManageMappingException'
      );
      System.assertEquals(
        ex.getMessage(),
        'An IManageMapping__c must not contain more than 1 record',
        'Wrong exception message'
      );
    }
    Test.stopTest();
  }

  @isTest
  static void getMappingDataTest() {
      
    // Create Opportunity
    Opportunity opp = new Opportunity();
    opp.Name = 'Test Opportunity';
    opp.Closedate = System.today();
    opp.StageName = 'Prospecting';
    insert opp;

    // Create mapping
    IManageMapping__c mapping = new IManageMapping__c(
      EntityType__c = 'Opportunity',
      EntityMatterIdObjectField__c = 'Opportunity',
      MatterIdField__c = 'Id',
      EntityClientIdObjectField__c = 'Opportunity',
      ClientIdField__c = 'StageName'
    );
    insert mapping;

    Test.startTest();
    IManageMappingHelper.IManageIFrameData result = IManageMappingHelper.getMappingData(
      opp.Id
    );
    Test.stopTest();

    // validations
    System.assert(
      result.MatterId == String.valueOf(opp.Id),
      'A MatterId has wrong value'
    );
    System.assertEquals(
      result.ClientId,
      String.valueOf(opp.StageName),
      'A ClientId has wrong value'
    );
  }

  @isTest
  static void getMappingDataTest2() {
    // Create Opportunity
    Opportunity opp = new Opportunity();
    opp.Name = 'Test Opportunity';
    opp.Closedate = System.today();
    opp.StageName = 'Prospecting';
    insert opp;

    // Create mapping
    IManageMapping__c mapping = new IManageMapping__c(
      EntityType__c = 'Opportunity',
      EntityMatterIdObjectField__c = 'Opportunity',
      MatterIdField__c = 'StageName',
      EntityClientIdObjectField__c = 'Opportunity',
      ClientIdField__c = 'Id'
    );
    insert mapping;

    Test.startTest();
    IManageMappingHelper.IManageIFrameData result = IManageMappingHelper.getMappingData(
      opp.Id
    );
    Test.stopTest();

    // validations
    System.assert(
      result.MatterId == String.valueOf(opp.StageName),
      'A MatterId has wrong value'
    );
    System.assertEquals(
      result.ClientId,
      String.valueOf(opp.Id),
      'A ClientId has wrong value'
    );
  }

  @isTest
  static void insertTwoMappingsWithTheSameEntityTypeTest() {
    // Create mappings
    IManageMapping__c mapping1 = new IManageMapping__c(
      EntityType__c = 'Opportunity',
      EntityMatterIdObjectField__c = 'Opportunity',
      MatterIdField__c = 'Id',
      EntityClientIdObjectField__c = 'AccountId',
      ClientIdField__c = 'Id'
    );
    insert mapping1;

    Test.startTest();
    try {
      IManageMapping__c mapping2 = new IManageMapping__c(
        EntityType__c = 'Opportunity',
        EntityMatterIdObjectField__c = 'AccountId',
        MatterIdField__c = 'Id',
        EntityClientIdObjectField__c = 'Opportunity',
        ClientIdField__c = 'Id'
      );
      insert mapping2;
    } catch (Exception ex) {
      System.assert(
        ex instanceof System.DmlException,
        'Exception is not a System.DmlException'
      );
      System.assert(
        ex.getMessage().contains('DUPLICATE_VALUE'),
        'Wrong exception message'
      );
    }
    Test.stopTest();
  }

  @isTest
  static void getFieldsTest() {
    Test.startTest();
    List<IManageMappingHelper.GetFieldResult> resultSrting = IManageMappingHelper.getFields(
      'Opportunity',
      new List<String>{ 'STRING' }
    );
    List<IManageMappingHelper.GetFieldResult> resultReference = IManageMappingHelper.getFields(
      'Opportunity',
      new List<String>{ 'REFERENCE' }
    );
    Test.stopTest();

    // validations
    System.assert(resultSrting.size() > 0, 'The result is empty');
    System.assert(resultReference.size() > 0, 'The result is empty');

    for (IManageMappingHelper.GetFieldResult field : resultSrting) {
      System.assertEquals(
        field.getFieldType(),
        'STRING',
        'An item\'s has wrong type (not STRING)'
      );
      System.assert(field.getFieldLabel() != null, 'An item\'s label is null');
      System.assert(field.getFieldName() != null, 'An item\'s name is null');
      System.assert(
        field.getReferenceTo() == null ||
        field.getReferenceTo().size() == 0,
        'An item is a REFERENCE type'
      );
    }

    for (IManageMappingHelper.GetFieldResult field : resultReference) {
      System.assertEquals(
        field.getFieldType(),
        'REFERENCE',
        'An item\'s has wrong type (not REFERENCE)'
      );
      System.assert(
        field.getReferenceTo() != null &&
        field.getReferenceTo().size() > 0,
        'An item is not a REFERENCE type'
      );
    }
  }

  @isTest
  static void getFieldsTestException() {
    Test.startTest();
    try {
      List<IManageMappingHelper.GetFieldResult> resultSrting = IManageMappingHelper.getFields(
        'OpportunityTTTTTTTTTTTTTT',
        new List<String>{ 'STRING' }
      );
    } catch (Exception ex) {
      System.assert(
        ex instanceof AuraHandledException,
        'Exception is not a AuraHandledException'
      );
    }
    Test.stopTest();
  }

  @isTest
  static void saveMappingTest() {
    IManageMapping__c mapping = new IManageMapping__c(
      EntityType__c = 'Opportunity',
      EntityMatterIdObjectField__c = 'Opportunity',
      MatterIdField__c = 'Id',
      EntityClientIdObjectField__c = 'CreatedById',
      ClientIdField__c = 'Id'
    );
    Test.startTest();
    IManageMappingHelper.saveMapping(mapping);
    Test.stopTest();
    System.assert(mapping.Id != null, 'Id is null');
  }

  @isTest
  static void saveMappingTestException() {
    IManageMapping__c mapping = null;
    Test.startTest();
    try {
      IManageMappingHelper.saveMapping(mapping);
    } catch (Exception ex) {
      System.assert(
        ex instanceof AuraHandledException,
        'Exception is not a AuraHandledException'
      );
    }
    Test.stopTest();
  }
}
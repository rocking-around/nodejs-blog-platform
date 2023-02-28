@isTest
private class IManageMappingHelperTests {
  @isTest
  static void getMappingTest_positive() {
    TestUtils.setupMockActiveLicense();
    iManageSettings__c testData = new iManageSettings__c(
      Client_Id__c = 'val1',
      ClientField__c = 'val2',
      MatterField__c = 'val3',
      Url__c = 'val4',
      iManage_Default_Folder_Id__c = 'val5',
      Enable_CSV_Export__c = true,
      Mapping_EntityType__c = 'Opportunity',
      Mapping_EntityMatterIdObjectField__c = 'Opportunity',
      Mapping_MatterIdField__c = 'Id',
      Mapping_EntityClientIdObjectField__c = 'CreatedById',
      Mapping_ClientIdField__c = 'Id'
    );

    insert testData;

    Test.startTest();
    IManageMapping mapping = IManageMappingHelper.getMapping();
    Test.stopTest();

    System.assert(
      mapping.EntityType == testData.Mapping_EntityType__c,
      'An EntityType__c has wrong value'
    );
    System.assertEquals(
      mapping.EntityMatterIdObjectField,
      testData.Mapping_EntityMatterIdObjectField__c,
      'An EntityMatterIdObjectField__c has wrong value'
    );
  }

  @isTest
  static void getMappingDataTest() {
    TestUtils.setupMockActiveLicense();
    // Create Opportunity
    Opportunity opp = new Opportunity();
    opp.Name = 'Test Opportunity';
    opp.Closedate = System.today();
    opp.StageName = 'Prospecting';
    insert opp;

    // Create mapping
    iManageSettings__c mapping = new iManageSettings__c(
      Client_Id__c = 'val1',
      ClientField__c = 'val2',
      MatterField__c = 'val3',
      Url__c = 'val4',
      iManage_Default_Folder_Id__c = 'val5',
      Enable_CSV_Export__c = true,
      Mapping_EntityType__c = 'Opportunity',
      Mapping_EntityMatterIdObjectField__c = 'Opportunity',
      Mapping_MatterIdField__c = 'Id',
      Mapping_EntityClientIdObjectField__c = 'Opportunity',
      Mapping_ClientIdField__c = 'StageName'
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
    TestUtils.setupMockActiveLicense();
    // Create Opportunity
    Opportunity opp = new Opportunity();
    opp.Name = 'Test Opportunity';
    opp.Closedate = System.today();
    opp.StageName = 'Prospecting';
    insert opp;

    // Create mapping
    iManageSettings__c mapping = new iManageSettings__c(
      Client_Id__c = 'val1',
      ClientField__c = 'val2',
      MatterField__c = 'val3',
      Url__c = 'val4',
      iManage_Default_Folder_Id__c = 'val5',
      Enable_CSV_Export__c = true,
      Mapping_EntityType__c = 'Opportunity',
      Mapping_EntityMatterIdObjectField__c = 'Opportunity',
      Mapping_MatterIdField__c = 'StageName',
      Mapping_EntityClientIdObjectField__c = 'Opportunity',
      Mapping_ClientIdField__c = 'Id'
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
  static void getFieldsTest() {
    TestUtils.setupMockActiveLicense();
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
    TestUtils.setupMockActiveLicense();
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
    TestUtils.setupMockActiveLicense();
    iManageSettings__c settings = new iManageSettings__c(
      Client_Id__c = 'val1',
      ClientField__c = 'val2',
      MatterField__c = 'val3',
      Url__c = 'val4',
      iManage_Default_Folder_Id__c = 'val5',
      Enable_CSV_Export__c = true,
      Mapping_EntityType__c = 'Opportunity',
      Mapping_EntityMatterIdObjectField__c = 'Opportunity',
      Mapping_MatterIdField__c = 'Id',
      Mapping_MatterNameField__c = 'Name',
      Mapping_EntityClientIdObjectField__c = 'AccountId',
      Mapping_ClientIdField__c = 'Id',
      Mapping_ClientNameField__c = 'Name'
    );
    insert settings;

    Map<String, Object> mapping = new Map<String, Object>{
      'EntityType' => 'Opportunity',
      'EntityMatterIdObjectField' => 'Opportunity',
      'MatterIdField' => 'Id',
      'EntityClientIdObjectField' => 'CreatedById',
      'ClientIdField' => 'Id'
    };

    Test.startTest();
    IManageMappingHelper.saveMapping(mapping);
    IManageMapping mapping2 = IManageMappingHelper.getMapping();
    Test.stopTest();
    System.assertEquals(
      mapping2.EntityType,
      (String) mapping.get('EntityType'),
      'EntityType__c has wrong value'
    );
  }

  //getSObjectMetadata
  static testMethod void getSObjectMetadataTest() {
    TestUtils.setupMockActiveLicense();
    Test.startTest();
    Map<String, Object> result = IManageMappingHelper.getSObjectMetadata(
      'Opportunity'
    );
    Test.stopTest();

    System.assert(result.containsKey('name'), 'Field "name" not exists');
    System.assert(result.containsKey('label'), 'Field "label" not exists');
    //System.assert(result.containsKey('sobjectType'), 'Field "sobjectType" not exists');
    System.assert(
      result.containsKey('associateEntityType'),
      'Field "associateEntityType" not exists'
    );
    System.assert(
      (String) result.get('name') == 'Opportunity',
      'The field "sobjectType" has wrong value'
    );
  }

  /*@isTest
  static void saveMappingTestException() {
    IManageMapping mapping = null;
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
  }*/
}

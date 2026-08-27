@isTest
public class IManageCsvEndpointTests {
  @isTest
  static void testGetPositive() {
    TestUtils.setupMockActiveLicense();
    // Create mappoing
    iManageSettings__c mapping = new iManageSettings__c(
      Client_Id__c = 'val1',
      ClientField__c = 'val2',
      MatterField__c = 'val3',
      Url__c = 'val4',
      Customer_Id__c = 'val5',
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
    IManageMappingMigration.migrateLegacyMapping();

    // Create oppporunity
    Opportunity opp = new Opportunity(
      Name = 'Test Opportunity Name',
      StageName = '100',
      CloseDate = system.now().addDays(30).date()
    );
    insert opp;

    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();
    String dateFormat = 'yyyy-MM-dd HH:mm:ss';

    req.requestURI = '/services/apexrest/gdsi_imanage/IManageCsv';
    req.httpMethod = 'GET';
    req.addParameter('objectName', 'Opportunity');
    req.addParameter('separator', ',');
    req.addParameter('startDate', '2021-12-31 00:00:00.000+0000');
    req.addParameter('endDate', system.now().addDays(1).format(dateFormat));

    RestContext.request = req;
    RestContext.response = res;

    Test.startTest();
    String result = IManageCsvEndpoint.doGet();
    Test.stopTest();

    System.assertNotEquals('', result);
    System.assertEquals(null, res.statusCode);
  }

  @isTest
  static void testGetWithoutRequiredParameter() {
    insert settings(true);
    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();

    req.requestURI = '/services/apexrest/gdsi_imanage/IManageCsv';
    req.httpMethod = 'GET';
    req.addParameter('separator', ',');
    req.addParameter('startDate', '2021-12-31 00:00:00.000+0000');
    RestContext.request = req;
    RestContext.response = res;

    Test.startTest();
    String result = IManageCsvEndpoint.doGet();
    Test.stopTest();

    System.assertEquals('', result);
    System.assertEquals(400, res.statusCode);
  }

  @isTest
  static void unmappedObjectReturnsEmptyResponse() {
    TestUtils.setupMockActiveLicense();
    insert settings(true);

    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();
    req.requestURI = '/services/apexrest/gdsi_imanage/IManageCsv';
    req.httpMethod = 'GET';
    req.addParameter('objectName', 'Account');
    req.addParameter('separator', ',');
    req.addParameter('startDate', '2021-12-31 00:00:00.000+0000');
    RestContext.request = req;
    RestContext.response = res;

    Test.startTest();
    String result = IManageCsvEndpoint.doGet();
    Test.stopTest();

    System.assertEquals('', result);
    System.assertEquals(null, res.statusCode);
  }

  @isTest
  static void disabledExportReturnsEmptyResponse() {
    insert settings(false);
    RestContext.request = new RestRequest();
    RestContext.response = new RestResponse();

    Test.startTest();
    String result = IManageCsvEndpoint.doGet();
    Test.stopTest();

    System.assertEquals('', result);
    System.assertEquals(400, RestContext.response.statusCode);
  }

  private static iManageSettings__c settings(Boolean exportEnabled) {
    return new iManageSettings__c(
      Client_Id__c = 'test-client',
      Url__c = 'https://example.invalid',
      Customer_Id__c = 'test-customer',
      Enable_CSV_Export__c = exportEnabled
    );
  }
}
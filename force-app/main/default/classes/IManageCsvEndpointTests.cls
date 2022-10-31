@isTest
public class IManageCsvEndpointTests {
  @isTest
  static void testGetPositive() {
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
}

@isTest
public with sharing class LicenseServiceTests {
  static testMethod void getLicenseInfoTest() {
    Organization org = [SELECT Id FROM Organization];
    String orgId = String.valueOf(org.Id);
    //Setup Mock responses
    String licenseUrl = LicenseService.baseUrl + '/api/License/organization';
    Map<String, HttpResponse> responses = new Map<String, HttpResponse>{
      licenseUrl => getMockLicenseResponse(200, orgId)
    };
    EchoHttpMock.setTestMockResponse(responses);

    Test.startTest();
    String result = LicenseService.getLicenseInfo(orgId);
    Test.stopTest();
    String respDec = LicenseService.decrypt(result);
    LicenseService.LicenseResponse licInfo = (LicenseService.LicenseResponse) JSON.deserialize(
      respDec,
      LicenseService.LicenseResponse.class
    );

    System.assert(licInfo.status == 'Active', 'The status has wrong value');
    System.assert(licInfo.orgId == org.Id, 'The orgId has wrong value');
    System.assert(
      licInfo.expirationDate > datetime.now(),
      'The expirationDate is less than now'
    );
    System.assert(licInfo.ts < datetime.now(), 'The ts is greater than now');
  }

  static testMethod void checkOrganizationLicenseNotFoundTest() {
    Organization org = [SELECT Id FROM Organization];
    String orgId = String.valueOf(org.Id);
    //Setup Mock responses
    String licenseUrl = LicenseService.baseUrl + '/api/License/organization';
    Map<String, HttpResponse> responses = new Map<String, HttpResponse>{
      licenseUrl => getMockLicenseNotFoundResponse(200, orgId)
    };
    EchoHttpMock.setTestMockResponse(responses);

    Test.startTest();
    try {
      LicenseService.CheckOrganizationLicense();
    } catch (AuraHandledException ex) {
      System.assert(
        ex.getMessage() == System.Label.imanage_message_codes_license_not_found,
        'Wrong error message'
      );
    }
    Test.stopTest();
  }

  static testMethod void checkOrganizationLicenseExpiredTest() {
    Organization org = [SELECT Id FROM Organization];
    String orgId = String.valueOf(org.Id);
    //Setup Mock responses
    String licenseUrl = LicenseService.baseUrl + '/api/License/organization';
    Map<String, HttpResponse> responses = new Map<String, HttpResponse>{
      licenseUrl => getMockLicenseExpiredResponse(200, orgId)
    };
    EchoHttpMock.setTestMockResponse(responses);

    Test.startTest();
    try {
      LicenseService.CheckOrganizationLicense();
    } catch (AuraHandledException ex) {
      System.assert(
        ex.getMessage() == System.Label.imanage_message_codes_license_expired,
        'Wrong error message'
      );
    }
    Test.stopTest();
  }

  static testMethod void checkOrganizationLicenseBrokenResponseTest() {
    Organization org = [SELECT Id FROM Organization];
    String orgId = String.valueOf(org.Id);
    //Setup Mock responses
    String licenseUrl = LicenseService.baseUrl + '/api/License/organization';

    Map<String, List<HttpResponse>> responses = new Map<String, List<HttpResponse>>{
      licenseUrl => new List<HttpResponse>{
        getMockLicenseBrokenResponse(200),
        getMockLicenseResponse(200, orgId)
      }
    };
    HttpCalloutQueueMock.setTestMockResponse(responses);

    Test.startTest();
    try {
      LicenseService.CheckOrganizationLicense();
    } catch (AuraHandledException ex) {
      System.assert(
        ex.getMessage() == System.Label.imanage_message_codes_license_not_found,
        'Wrong error message'
      );
    }
    Test.stopTest();
  }

  private static HttpResponse getMockLicenseResponse(
    Integer statusCode,
    String orgId
  ) {
    Datetime nowDate = datetime.now();
    LicenseService.LicenseResponse licResp = new LicenseService.LicenseResponse();
    licResp.status = 'Active';
    licResp.expirationDate = nowDate.addDays(30);
    licResp.ts = nowDate;
    licResp.orgId = orgId;

    String respJson = JSON.serialize(licResp);

    Blob respEnc = LicenseService.encrypt(respJson);
    String respEncBase64 = EncodingUtil.base64Encode(respEnc);

    HttpResponse resp = new HttpResponse();
    resp.setStatusCode(statusCode);
    resp.setBody(respEncBase64);
    return resp;
  }

  private static HttpResponse getMockLicenseNotFoundResponse(
    Integer statusCode,
    String orgId
  ) {
    Datetime nowDate = datetime.now();
    LicenseService.LicenseResponse licResp = new LicenseService.LicenseResponse();
    licResp.status = null;
    licResp.expirationDate = null;
    licResp.ts = nowDate;
    licResp.orgId = orgId;

    String respJson = JSON.serialize(licResp);

    Blob respEnc = LicenseService.encrypt(respJson);
    String respEncBase64 = EncodingUtil.base64Encode(respEnc);

    HttpResponse resp = new HttpResponse();
    resp.setStatusCode(statusCode);
    resp.setBody(respEncBase64);
    return resp;
  }

  private static HttpResponse getMockLicenseExpiredResponse(
    Integer statusCode,
    String orgId
  ) {
    Datetime nowDate = system.now();
    LicenseService.LicenseResponse licResp = new LicenseService.LicenseResponse();
    licResp.status = 'Expired';
    licResp.expirationDate = system.now().addDays(1); // yes, add 1 day, not -1
    licResp.ts = nowDate;
    licResp.orgId = orgId;

    String respJson = JSON.serialize(licResp);

    Blob respEnc = LicenseService.encrypt(respJson);
    String respEncBase64 = EncodingUtil.base64Encode(respEnc);

    HttpResponse resp = new HttpResponse();
    resp.setStatusCode(statusCode);
    resp.setBody(respEncBase64);
    return resp;
  }

  private static HttpResponse getMockLicenseBrokenResponse(Integer statusCode) {
    String someString = 'someString';
    Blob respEnc = LicenseService.encrypt(someString);
    String respEncBase64 = EncodingUtil.base64Encode(respEnc);

    HttpResponse resp = new HttpResponse();
    resp.setStatusCode(statusCode);
    resp.setBody(respEncBase64);
    return resp;
  }
}

@isTest
public class TestUtils {
  public static void setupMockActiveLicense() {
    Organization org = [SELECT Id FROM Organization];
    String orgId = String.valueOf(org.Id);
    //Setup Mock responses
    String licenseUrl = LicenseService.baseUrl + '/api/License/organization';
    Map<String, HttpResponse> responses = new Map<String, HttpResponse>{
      licenseUrl => getMockLicenseResponse(200, orgId)
    };
    EchoHttpMock.setTestMockResponse(responses);
  }

  public static void setupMockInvalidLicense() {
    Organization org = [SELECT Id FROM Organization];
    String orgId = String.valueOf(org.Id);
    //Setup Mock responses
    String licenseUrl = LicenseService.baseUrl + '/api/License/organization';
    Map<String, HttpResponse> responses = new Map<String, HttpResponse>{
      licenseUrl => getMockInvalidLicenseResponse(200, orgId)
    };
    EchoHttpMock.setTestMockResponse(responses);
  }

  public static boolean isFieldExist(String objName, string fieldName) {
    try {
      SObject so = Schema.getGlobalDescribe().get(objName).newSObject();
      return so.getSobjectType()
        .getDescribe()
        .fields.getMap()
        .containsKey(fieldName);
    } catch (Exception ex) {
    }

    return false;
  }

  public static HttpResponse getMockLicenseResponse(
    Integer statusCode,
    String orgId
  ) {
    Datetime nowDate = system.now();
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

  public static HttpResponse getMockInvalidLicenseResponse(
    Integer statusCode,
    String orgId
  ) {
    //{"status":null,"orgId":"sd","expirationDate":null,"ts":"202303151243396682"}
    Datetime nowDate = system.now();
    LicenseService.LicenseResponse licResp = new LicenseService.LicenseResponse();
    licResp.status = 'Expired';
    licResp.expirationDate = nowDate;
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
}

@isTest
public class TestUtils {
  static Integer s_num = 1;

  public static String getFakeId(Schema.SObjectType sot)
  {
      String result = String.valueOf(s_num++);
      //return sot.getDescribe().getKeyPrefix() + '0'.repeat(15-result.length()) + result;
      return sot.getDescribe().getKeyPrefix() + result.leftPad(15, '0');
  }

  public static String getLicenseUrl() {
    return LicenseService.baseUrl + '/api/License/organization';
  }

  public static Map<String, HttpResponse> getMockActiveLicenseResponse() {
    Map<String, List<HttpResponse>> responses = getMockActiveLicenseResponses(1);

    //Setup Mock responses
    String licenseUrl = getLicenseUrl();
    Map<String, HttpResponse> result = new Map<String, HttpResponse>{
      licenseUrl => responses.get(licenseUrl).get(0)
    };
    return result;
  }

  public static Map<String, List<HttpResponse>> getMockActiveLicenseResponses(Integer count) {
    Organization org = [SELECT Id FROM Organization];
    String orgId = String.valueOf(org.Id);
    //Setup Mock responses
    String licenseUrl = getLicenseUrl();

    List<HttpResponse> responses = new List<HttpResponse>();

    for (Integer i = 0; i < count; i++) {
      responses.add(getMockLicenseResponse(200, orgId));
    }

    Map<String, List<HttpResponse>> result = new Map<String, List<HttpResponse>>{
      licenseUrl => responses
    };
    return result;
  }

  public static void setupMockActiveLicense() {
    Map<String, HttpResponse> responses = getMockActiveLicenseResponse();
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

  public static HttpResponse getMockAuthResponse(
    Integer statusCode,
    String auth_status,
    Integer customerId,
    String library
  ) {
    HttpResponse resp = new HttpResponse();
    if (String.isEmpty(auth_status)) {
      auth_status = 'authenticated';
    }

    Map<String,Object> body = new Map<String,Object> {
      'data' => new Map<String,Object> {
        'app' => new Map<String,Object> {
          'id' => '894a95b7-e904-429a-a37f-467823927648'
        },
        'auth_status' => auth_status,
        'capabilities' => new List<String> {'app_store', 'global_users', 'oauth'},
        'dms_version' => '10.2.2838',
        'user' => new Map<String,Object> {
          'customer_id' => customerId,
          'email' => 'test@gdsi.com',
          'id' => 'TEST',
          'name' => 'test',
          'ssid' => '386600337554908195',
          'user_type' => 'enterprise'
        },
        'versions' => new List<Map<String,Object>>{
          new Map<String,Object>{
            'name'=> 'v2',
            'url'=> 'https://cloudimanage.com/work/api/v2',
            'version'=> '2.1.766'
          }
        },
        'work' => new Map<String,Object>{
          'libraries' => new List<Map<String,Object>>{
            new Map<String,Object>{
              'alias'=> library,
              'is_classic_client_compatible'=> false,
              'type'=> 'worksite'
            }
          },
          'preferred_library' => library
        }
      }
    };
    resp.setStatusCode(statusCode);

    String jsonBody = JSON.serialize(body);
    System.debug('TestUtils::getMockAuthResponse. body = ' + jsonBody);
    resp.setBody(jsonBody);
    return resp;
  }

  public static String getLicenseApiUrl() {
    return LicenseService.baseUrl + '/api/License/organization';
  }

  public static Organization getOrganization() {
    Organization org = [SELECT Id FROM Organization];
    return org;
  }

  public static String buildCalloutUrl(String path, List<Object> formattingArgs) {
    return 'callout:iManageCreds' + String.format(path, formattingArgs);
  }
}
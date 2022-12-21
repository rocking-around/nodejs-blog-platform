public with sharing class LicenseService {
  static final String AES_KEY_BASE64 = 'WTFkDEC3Jx5VT1cURN8pdNjxh7Zf/jeD9BnLeyQPxC4=';
  static final String AES_VECTOR_STR = '#5d`f\\8E7qdm2j0`'; // 16 bytes
  static final String SANDBOX_LICENSING_BASE_URL = 'https://sandbox-imanage-litify-licensing.gdsi.com'; // Sandbox licensing URL
  static final String PRODUCTION_LICENSING_BASE_URL = 'https://imanage-litify-licensing.gdsi.com'; // Production licensing URL
  static final Integer SANDBOX_LICENSING_INTERVAL = 2; // 2 minutes
  static final Integer PRODUCTION_LICENSING_INTERVAL = 2 * 60 * 24 * 14; // Two weeks cache

  @TestVisible
  private static string decrypt(Blob enc) {
    Blob key = EncodingUtil.base64Decode(AES_KEY_BASE64);
    Blob vector = Blob.valueOf(AES_VECTOR_STR);
    Blob decryptedBlob = Crypto.decrypt('AES256', key, vector, enc);
    return decryptedBlob.toString();
  }

  @TestVisible
  private static string decrypt(String encBase64) {
    Blob enc = EncodingUtil.base64Decode(encBase64.replace('"', ''));
    return decrypt(enc);
  }

  @TestVisible
  private static Blob encrypt(String str) {
    Blob key = EncodingUtil.base64Decode(AES_KEY_BASE64);
    Blob vector = Blob.valueOf(AES_VECTOR_STR);
    Blob data = Blob.valueOf(str);
    Blob encrypted = Crypto.encrypt('AES256', key, vector, data);
    return encrypted;
  }

  private static Boolean runningInASandbox {
    get {
      if (runningInASandbox == null) {
        runningInASandbox = [SELECT IsSandbox FROM Organization LIMIT 1]
        .IsSandbox;
      }
      return runningInASandbox;
    }
    set;
  }

  @TestVisible
  private static String baseUrl {
    get {
      if (runningInASandbox)
        return SANDBOX_LICENSING_BASE_URL;
      else
        return PRODUCTION_LICENSING_BASE_URL;
    }
  }

  @TestVisible
  private static Integer licensingInterval {
    get {
      if (runningInASandbox)
        return SANDBOX_LICENSING_INTERVAL;
      else
        return PRODUCTION_LICENSING_INTERVAL;
    }
  }

  @TestVisible
  private static String getLicenseInfo(String orgId) {
    //TODO: call Api
    // curl -X 'POST' \
    // '/api/License/organization' \
    // -H 'accept: */*' \
    // -H 'Content-Type: multipart/form-data' \
    // -F 'organizationId=00D4H000000wk3YUAQ'

    if (Cache.Org.contains('license'))
      return (String) Cache.Org.get('license');

    HttpRequest req = new HttpRequest();
    req.setEndpoint(LicenseService.baseUrl + '/api/License/organization');
    req.setHeader('content-type', 'application/x-www-form-urlencoded');
    req.setMethod('POST');
    req.setBody('organizationId=' + EncodingUtil.urlEncode(orgId, 'UTF-8'));

    Http http = new Http();
    HTTPResponse res = http.send(req);
    String result = res.getBody();
    system.debug(result);
    Cache.Org.put('license', result, Cache.Visibility.NAMESPACE);
    return result;
    //return 'ALP7Yw390uuIlHsHhNZsbIxDtHDKZYDvN9IP5cxUyngJo2ayfw7s+NXIMs0aHcTlnQRZGNH9da0zVcMvapAhnjdwm+fS9SKR3pm3sWWoAboO/s5wYOa/FFj6kCWgtiFsMH90GWZaIUQPvluNbPVvazHcEbqLSz+KuI/kZyqm2xM=';
  }

  @AuraEnabled
  public static void CheckOrganizationLicense() {
    Organization org = [SELECT Id FROM Organization];
    String licenseResponseEnc = getLicenseInfo(org.Id);
    System.debug(licenseResponseEnc);
    String licenseResponseDec = decrypt(licenseResponseEnc);
    System.debug(licenseResponseDec);
    LicenseService.LicenseResponse licenseResponse = null;
    try {
      licenseResponse = (LicenseService.LicenseResponse) JSON.deserialize(
        licenseResponseDec,
        LicenseService.LicenseResponse.class
      );
    } catch (Exception ex) {
      if (Cache.Org.contains('license')) {
        Cache.Org.remove('license');
        CheckOrganizationLicense();
      }

      throw IManageBaseHelper.BuildException(
        IManageBaseHelper.IManageErrors.LICENSE_NOT_FOUND
      );
    }

    System.debug(licenseResponse);

    // If licensing cache expired or invalid - remove cache and try again
    if (
      Cache.Org.contains('license') &&
      (licenseResponse == null ||
      LicenseService.licensingInterval <
      ((DateTime.now().getTime() - licenseResponse.ts.getTime()) /
      1000 /
      60))
    ) {
      Cache.Org.remove('license');
      CheckOrganizationLicense();
    }

    if (
      licenseResponse == null ||
      licenseResponse.status == 'Inactive' ||
      licenseResponse.status == null
    ) {
      Cache.Org.remove('license');
      throw IManageBaseHelper.BuildException(
        IManageBaseHelper.IManageErrors.LICENSE_NOT_FOUND
      );
    }

    if (
      licenseResponse.expirationDate <= system.now() ||
      licenseResponse.status == 'Expired'
    ) {
      Cache.Org.remove('license');
      throw IManageBaseHelper.BuildException(
        IManageBaseHelper.IManageErrors.LICENSE_EXPIRED
      );
    }
  }

  public class LicenseResponse {
    @AuraEnabled
    public String status;

    @AuraEnabled
    public Id orgId;

    @AuraEnabled
    public Datetime ts;

    @AuraEnabled
    public Datetime expirationDate;
  }
}

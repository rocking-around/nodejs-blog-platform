global with sharing class LicenseService {
  static final String AES_KEY_BASE64 = 'WTFkDEC3Jx5VT1cURN8pdNjxh7Zf/jeD9BnLeyQPxC4=';
  static final String AES_VECTOR_STR = '#5d`f\\8E7qdm2j0`'; // 16 bytes
  static final String SANDBOX_LICENSING_BASE_URL = 'https://sandbox-imanage-litify-licensing.gdsi.com'; // Sandbox licensing URL
  static final String PRODUCTION_LICENSING_BASE_URL = 'https://imanage-litify-licensing.gdsi.com'; // Production licensing URL
  static final Integer SANDBOX_LICENSING_INTERVAL = 2; // 2 minutes
  static final Integer PRODUCTION_LICENSING_INTERVAL = 2 * 60 * 24 * 14; // Two weeks cache
  static final String CACHE_NAME = 'gdsi_imanage.iManage.license';

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
    Map<String, Object> params = new Map<String, Object>{ 'orgId' => orgId };
    Logger.getInstance()
      .info(
        'LicenseService::getLicenseInfo, start method. Params: ' +
        JSON.serialize(params)
      );
    //TODO: call Api
    // curl -X 'POST' \
    // '/api/License/organization' \
    // -H 'accept: */*' \
    // -H 'Content-Type: multipart/form-data' \
    // -F 'organizationId=00D4H000000wk3YUAQ'

    if (Cache.Org.contains(CACHE_NAME)) {
      Logger.getInstance()
        .info('LicenseService::getLicenseInfo. Exists in the Cache');
      return (String) Cache.Org.get(CACHE_NAME);
    }

    HttpRequest req = new HttpRequest();
    req.setEndpoint(LicenseService.baseUrl + '/api/License/organization');
    req.setHeader('content-type', 'application/x-www-form-urlencoded');
    req.setMethod('POST');
    req.setBody('organizationId=' + EncodingUtil.urlEncode(orgId, 'UTF-8'));

    Http http = new Http();
    HTTPResponse res = http.send(req);
    String result = res.getBody();
    Logger.getInstance()
      .info('LicenseService::getLicenseInfo. Response body: ' + result);
    Cache.Org.put(CACHE_NAME, result, Cache.Visibility.NAMESPACE);
    Logger.getInstance()
      .info(
        'LicenseService::getLicenseInfo. The result has placed to the cache.'
      );
    return result;
    //return 'ALP7Yw390uuIlHsHhNZsbIxDtHDKZYDvN9IP5cxUyngJo2ayfw7s+NXIMs0aHcTlnQRZGNH9da0zVcMvapAhnjdwm+fS9SKR3pm3sWWoAboO/s5wYOa/FFj6kCWgtiFsMH90GWZaIUQPvluNbPVvazHcEbqLSz+KuI/kZyqm2xM=';
  }

  @future(callout=true)
  public static Void SendOrganizationInfo(Boolean isNew) {
    Map<String, Object> params = new Map<String, Object>{ 'isNew' => isNew };
    Logger.getInstance()
      .info(
        'LicenseService::SendOrganizationInfo, start method. Params: ' +
        JSON.serialize(params)
      );

    try {
      Integer countUsersSalesforce = [
        SELECT COUNT()
        FROM User
        WHERE Profile.UserLicense.Name = 'Salesforce' AND IsActive = true
      ];

      Integer countUsersSalesforcePlatform = [
        SELECT COUNT()
        FROM User
        WHERE Profile.UserLicense.Name = 'Salesforce Platform' AND IsActive = true
      ];

      Integer countUsers = countUsersSalesforce + countUsersSalesforcePlatform;

      Organization org = [
        SELECT
          Id,
          Name,
          Phone,
          IsSandbox,
          ComplianceBccEmail,
          Country,
          City,
          PostalCode
        FROM Organization
        LIMIT 1
      ];
      LicenseService.LicenseOrgRequest requestObject = new LicenseService.LicenseOrgRequest();
      requestObject.Id = org.Id;
      requestObject.Name = org.Name;
      requestObject.CountUsers = countUsers;
      requestObject.Phone = org.Phone;
      requestObject.IsSandbox = org.IsSandbox;
      requestObject.ComplianceBccEmail = org.ComplianceBccEmail;
      requestObject.Country = org.Country;
      requestObject.City = org.City;
      requestObject.PostalCode = org.PostalCode;
      String requestObjectString = JSON.serialize(requestObject);
      Blob encryptedRequest = encrypt(requestObjectString);

      HttpRequest req = new HttpRequest();
      if (isNew)
        req.setEndpoint(
          LicenseService.baseUrl + '/api/License/new-organization'
        );
      else
        req.setEndpoint(
          LicenseService.baseUrl + '/api/License/update-organization'
        );

      req.setHeader('content-type', 'application/x-www-form-urlencoded');
      req.setMethod('POST');
      req.setBody(
        'info=' +
        EncodingUtil.urlEncode(
          EncodingUtil.base64Encode(encryptedRequest),
          'UTF-8'
        )
      );
      system.debug(EncodingUtil.base64Encode(encryptedRequest));

      Http http = new Http();
      HTTPResponse res = http.send(req);
      String result = res.getBody();
      system.debug(res);
    } catch (Exception ex) {
      Logger.getInstance().error(ex, 'LicenseService::SendOrganizationInfo');
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
  }

  @AuraEnabled
  global static void CheckOrganizationLicense() {
    Logger.getInstance()
      .info('LicenseService::CheckOrganizationLicense, start method');

    try {
      Organization org = [SELECT Id FROM Organization];
      String licenseResponseEnc = getLicenseInfo(org.Id);
      String licenseResponseDec = decrypt(licenseResponseEnc);
      LicenseService.LicenseResponse licenseResponse = null;
      try {
        licenseResponse = (LicenseService.LicenseResponse) JSON.deserialize(
          licenseResponseDec,
          LicenseService.LicenseResponse.class
        );
      } catch (Exception ex) {
        if (Cache.Org.contains(CACHE_NAME)) {
          Cache.Org.remove(CACHE_NAME);
          CheckOrganizationLicense();
        }

        IManageBaseHelper.throwException(
          IManageBaseHelper.IManageErrors.LICENSE_NOT_FOUND,
          Request.getCurrent().getQuiddity()
        );
      }

      Logger.getInstance()
        .info(
          'LicenseService::CheckOrganizationLicense, licenseResponse = ' +
          licenseResponse
        );

      // If licensing cache expired or invalid - remove cache and try again
      if (
        Cache.Org.contains(CACHE_NAME) &&
        (licenseResponse == null ||
        LicenseService.licensingInterval <
        ((DateTime.now().getTime() - licenseResponse.ts.getTime()) /
        1000 /
        60))
      ) {
        Cache.Org.remove(CACHE_NAME);
        CheckOrganizationLicense();
      }

      if (
        licenseResponse == null ||
        licenseResponse.status == 'Inactive' ||
        licenseResponse.status == null
      ) {
        Cache.Org.remove(CACHE_NAME);
        IManageBaseHelper.throwException(
          IManageBaseHelper.IManageErrors.LICENSE_NOT_FOUND,
          Request.getCurrent().getQuiddity()
        );
      }

      if (
        licenseResponse.expirationDate <= system.now() ||
        licenseResponse.status == 'Expired'
      ) {
        Cache.Org.remove(CACHE_NAME);
        IManageBaseHelper.throwException(
          IManageBaseHelper.IManageErrors.LICENSE_EXPIRED,
          Request.getCurrent().getQuiddity()
        );
      }
    } catch (IManageExceptions.IManageLicenseException ex) {
      throw ex;
    } catch (AuraHandledException ex) {
      Logger.getInstance()
        .error(ex, 'LicenseService::CheckOrganizationLicense');
      throw ex;
    } catch (Exception ex) {
      Logger.getInstance()
        .error(ex, 'LicenseService::CheckOrganizationLicense');
      throw ex;
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

  public class LicenseOrgRequest {
    public String Id;
    public String Name;
    public Integer CountUsers;
    public String Phone;
    public Boolean IsSandbox;
    public String ComplianceBccEmail;
    public String Country;
    public String City;
    public String PostalCode;
  }
}
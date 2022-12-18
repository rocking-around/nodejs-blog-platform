public with sharing class LicenseService {
  static final String AES_KEY_BASE64 = 'WTFkDEC3Jx5VT1cURN8pdNjxh7Zf/jeD9BnLeyQPxC4=';
  static final String AES_VECTOR_STR = '#5d`f\\8E7qdm2j0`'; // 16 bytes

  @TestVisible
  private static string decrypt(Blob enc) {
    Blob key = EncodingUtil.base64Decode(AES_KEY_BASE64);
    Blob vector = Blob.valueOf(AES_VECTOR_STR);
    Blob decryptedBlob = Crypto.decrypt('AES256', key, vector, enc);
    return decryptedBlob.toString();
  }

  @TestVisible
  private static string decrypt(String encBase64) {
    Blob enc = EncodingUtil.base64Decode(encBase64);
    return decrypt(enc);
  }

  @TestVisible
  private static string getLicenseInfo(String orgId) {
    //TODO: call Api
    // curl -X 'POST' \
    // '/api/License/organization' \
    // -H 'accept: */*' \
    // -H 'Content-Type: multipart/form-data' \
    // -F 'organizationId=00D4H000000wk3YUAQ'
    return 'ALP7Yw390uuIlHsHhNZsbIxDtHDKZYDvN9IP5cxUyngJo2ayfw7s+NXIMs0aHcTlnQRZGNH9da0zVcMvapAhnjdwm+fS9SKR3pm3sWWoAboO/s5wYOa/FFj6kCWgtiFsMH90GWZaIUQPvluNbPVvazHcEbqLSz+KuI/kZyqm2xM=';
  }

  @AuraEnabled
  public static Boolean isOrgHasValidLicense() {
    //Id orgId = UserInfo.getOrganizationId();
    Organization org = [
      SELECT o.Id
      /*o.WebToCaseDefaultOrigin,
        o.UsesStartDateAsFiscalYearName,
        o.UiSkin,
        o.TrialExpirationDate,
        o.SystemModstamp,
        o.Street,
        o.State,
        o.ReceivesInfoEmails,
        o.ReceivesAdminInfoEmails,
        o.PrimaryContact,
        o.PreferencesRequireOpportunityProducts,
        o.PostalCode,
        o.Phone,
        o.OrganizationType,
        o.Name,
        o.MonthlyPageViewsUsed,
        o.MonthlyPageViewsEntitlement,
        o.LastModifiedDate,
        o.LastModifiedById,
        o.LanguageLocaleKey,
        o.FiscalYearStartMonth,
        o.Fax,
        o.Division,
        o.DefaultPricebookAccess,
        o.DefaultOpportunityAccess,
        o.DefaultLocaleSidKey,
        o.DefaultLeadAccess,
        o.DefaultContactAccess,
        o.DefaultCaseAccess,
        o.DefaultCampaignAccess,
        o.DefaultCalendarAccess,
        o.DefaultAccountAccess,
        o.CreatedDate,
        o.CreatedById,
        o.Country,
        o.ComplianceBccEmail,
        o.City*/
      FROM Organization o
    ];
    String licenseResponseEnc = getLicenseInfo(org.Id);
    String licenseResponseDec = decrypt(licenseResponseEnc);
    LicenseService.LicenseResponse licenseResponse = (LicenseService.LicenseResponse) JSON.deserialize(
      licenseResponseDec,
      LicenseService.LicenseResponse.class
    );
    System.debug(licenseResponse);
    return licenseResponse.status == 'Active'; // Expired | Inactive
  }

  public class LicenseResponse {
    @AuraEnabled
    public String status;

    @AuraEnabled
    public Id orgId;

    @AuraEnabled
    public String ts;

    @AuraEnabled
    public Datetime expirationDate;
    //public String expirationDate;
  }
}

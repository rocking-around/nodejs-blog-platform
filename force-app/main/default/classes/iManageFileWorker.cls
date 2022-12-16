public class iManageFileWorker {
  private static void FakeCallForRefreshToken() {
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:iManageCreds/api/v2/customers/0/dialog-tokens');
    req.setHeader('content-type', 'application/json');
    req.setHeader('X-Auth-Token', '{!$Credential.AuthorizationHeaderValue}');
    req.setMethod('POST');

    Http http = new Http();
    HTTPResponse res = http.send(req);
  }

  @TestVisible
  private static iManageProvider.IManageApiDataResponse GetApiData() {
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:iManageCreds/api');
    req.setHeader('content-type', 'application/json');
    req.setHeader('X-Auth-Token', '{!$Credential.AuthorizationHeaderValue}');
    req.setMethod('GET');

    Http http = new Http();
    HTTPResponse res = http.send(req);
    if (res.getStatusCode() == 401)
      throw new IManageExceptions.IManageUnauthorizedException();
    String responseBody = res.getBody();

    iManageProvider.IManageApiDataResponse response = (iManageProvider.IManageApiDataResponse) JSON.deserialize(
      responseBody,
      iManageProvider.IManageApiDataResponse.class
    );
    if (response.data.auth_status == 'not-authenticated') {
      FakeCallForRefreshToken();
      return GetApiData();
    }

    return response;
  }

  /**
   * @description Download document from iManage and save it to the ContentVersion
   * @param recordId Salesforce Object Id
   * @param docId iManage Document Id
   * @param docName iManage Document Name
   * @param docExtension iManage Document Extension
   * @return ContentDocument Id
   */
  @AuraEnabled
  public static Id SaveFileFromIManage(
    String recordId,
    String docId,
    String docName,
    String docExtension
  ) {
    iManageProvider.IManageApiDataResponse apiData = GetApiData();
    String customer_id = apiData?.data?.user?.customer_id == null
      ? '0'
      : apiData.data.user.customer_id;
    String library = apiData?.data?.work?.preferred_library == null
      ? 'ACTIVE'
      : apiData.data.work.preferred_library;

    Id contentDocId = SaveFileFromIManageDetails(
      recordId,
      customer_id,
      library,
      docId,
      docName,
      docExtension
    );
    return contentDocId;
  }

  private static ContentVersion createContentVersion(
    String name,
    Blob body,
    String fileExtension
  ) {
    ContentVersion contentVersion = new ContentVersion(
      ContentLocation = 'S', // S = Stored in Salesforce
      PathOnClient = name + '.' + fileExtension,
      Title = name,
      VersionData = body
    );

    insert contentVersion;
    return contentVersion;
  }

  private static Void createContentDocumentLink(
    Id contentDocumentId,
    Id parentId
  ) {
    ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
      ContentDocumentId = contentDocumentId,
      LinkedEntityId = parentId,
      ShareType = 'I', // Inferred permission
      Visibility = 'AllUsers'
    );

    insert contentDocumentLink;
  }

  /**
   * @description Create Link to the document in iManage and save it to the IManage_File_Link__c object
   * @param recordId Salesforce Object Id
   * @param docId iManage Document Id
   * @param docName iManage Document Name
   * @return IManage_File_Link__c Id
   */
  @AuraEnabled
  public static Id SaveLinkFromIManage(
    String recordId,
    String docId,
    String version
  ) {
    iManageSettings__c mc = iManageSettings__c.getOrgDefaults();
    IManage_File_Link__c att = new IManage_File_Link__c(
      ParentId__c = recordId,
      Version__c = version,
      File_Link__c = mc.Url__c + '/work/web/dialogs/link/d/' + docId
    );
    insert att;
    return att.Id;
  }

  /**
   * @description Download document from iManage and save it to the ContentVersion
   * @param linkId IManage_File_Link__c Id
   * @return ContentDocument Id
   */
  @AuraEnabled
  public static Id SaveLinkToSalesforce(String linkId) {
    iManageSettings__c mc = iManageSettings__c.getOrgDefaults();
    IManage_File_Link__c link = [
      SELECT ParentId__c, Version__c, File_Link__c
      FROM IManage_File_Link__c
      WHERE Id = :linkId
    ];
    List<String> parsedUrl = link.File_Link__c.split('/');
    String docId = parsedUrl[parsedUrl.size() - 1];

    iManageProvider.IManageApiDataResponse apiData = GetApiData();
    String customer_id = apiData?.data?.user?.customer_id == null
      ? '0'
      : apiData.data.user.customer_id;
    String library = apiData?.data?.work?.preferred_library == null
      ? 'ACTIVE'
      : apiData.data.work.preferred_library;

    HttpRequest req = new HttpRequest();
    req.setEndpoint(
      'callout:iManageCreds/api/v2/customers/' +
      customer_id +
      '/libraries/' +
      library +
      '/documents/' +
      docId
    );
    req.setHeader('content-type', 'application/json');
    req.setHeader('X-Auth-Token', '{!$Credential.AuthorizationHeaderValue}');
    req.setMethod('GET');

    Http http = new Http();
    HTTPResponse res = http.send(req);
    String responseBody = res.getBody();
    iManageDocument docInfo = (iManageDocument) JSON.deserialize(
      responseBody,
      iManageDocument.class
    );

    Id contentDocId = SaveFileFromIManageDetails(
      link.ParentId__c,
      customer_id,
      library,
      docId,
      docInfo.data.name,
      docInfo.data.extension
    );

    delete link;

    return contentDocId;
  }

  /**
   * @description Download document from iManage and save it to the ContentVersion
   * @param recordId Salesforce Object Id
   * @param docId iManage Document Id
   * @param customer_id iManage Customer Id
   * @param library iManage Library
   * @param docName iManage Document Name
   * @param docExtension iManage Document Extension
   * @return ContentDocument Id
   */
  @TestVisible
  private static Id SaveFileFromIManageDetails(
    String recordId,
    String customer_id,
    String library,
    String docId,
    String docName,
    String docExtension
  ) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint(
      'callout:iManageCreds/api/v2/customers/' +
      customer_id +
      '/libraries/' +
      library +
      '/documents/' +
      docId +
      '/download'
    );
    req.setHeader('content-type', 'application/json');
    req.setHeader('X-Auth-Token', '{!$Credential.AuthorizationHeaderValue}');
    req.setMethod('GET');

    Http http = new Http();
    HTTPResponse res = http.send(req);
    Blob body = res.getBodyAsBlob();

    ContentVersion version = createContentVersion(docName, body, docExtension);
    ContentVersion contentVersion = [
      SELECT Id, ContentDocumentId
      FROM ContentVersion
      WHERE Id = :version.Id
      LIMIT 1
    ];
    createContentDocumentLink(contentVersion.ContentDocumentId, recordId);
    return contentVersion.ContentDocumentId;
  }

  public class iManageDocument {
    public iManageDocumentInfo data;
  }

  public class iManageDocumentInfo {
    public String name;
    public String extension;
  }
}

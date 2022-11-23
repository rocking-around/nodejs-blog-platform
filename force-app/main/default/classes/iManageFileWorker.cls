public class iManageFileWorker {
  @AuraEnabled
  public static Void SaveFileFromIManage(
    String recordId,
    String docId,
    String docName,
    String docExtension
  ) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint(
      'callout:iManageCreds/api/v1/documents/' +
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

  @AuraEnabled
  public static Void SaveLinkFromIManage(
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
  }
}

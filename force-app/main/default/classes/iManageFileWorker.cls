global class iManageFileWorker {
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
    Logger.getInstance()
      .info(
        'iManageFileWorker::SaveFileFromIManage, start method, params["recordId"] = ' +
        recordId +
        ', params["docId"] = ' +
        docId +
        'params["docName"] = ' +
        docName +
        'params["docExtension"] = ' +
        docExtension
      );

    try {
      LicenseService.CheckOrganizationLicense();
      iManageWrapper.ApiInfo apiInfo = iManageWrapper.GetApiInfo();
      Id contentDocId = SaveFileFromIManageDetails(
        recordId,
        apiInfo,
        docId,
        docName,
        docExtension
      );
      return contentDocId;
    } catch (Exception ex) {
      Logger.getInstance().error(ex, 'iManageFileWorker::SaveFileFromIManage');
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
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
    Map<String, Object> params = new Map<String, Object>{
      'recordId' => recordId,
      'docId' => docId,
      'version' => version
    };

    Logger.getInstance()
      .info(
        'iManageFileWorker::SaveLinkFromIManage, start method. Params: ' +
        JSON.serialize(params)
      );

    LicenseService.CheckOrganizationLicense();

    try {
      iManageSettings__c mc = iManageSettings__c.getOrgDefaults();
      IManage_File_Link__c att = new IManage_File_Link__c(
        ParentId__c = recordId,
        Version__c = version,
        File_Link__c = mc.Url__c + '/work/web/dialogs/link/d/' + docId
      );
      insert att;
      return att.Id;
    } catch (Exception ex) {
      Logger.getInstance().error(ex, 'iManageFileWorker::SaveLinkFromIManage');
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
  }

  /**
   * @description Download document from iManage and save it to the ContentVersion
   * @param linkId IManage_File_Link__c Id
   * @return ContentDocument Id
   */
  @AuraEnabled
  public static Id SaveLinkToSalesforce(String linkId) {
    Map<String, Object> params = new Map<String, Object>{ 'linkId' => linkId };

    Logger.getInstance()
      .info(
        'iManageFileWorker::SaveLinkToSalesforce, start method. Params: ' +
        JSON.serialize(params)
      );

    LicenseService.CheckOrganizationLicense();

    try {
      iManageSettings__c mc = iManageSettings__c.getOrgDefaults();
      IManage_File_Link__c link = [
        SELECT ParentId__c, Version__c, File_Link__c
        FROM IManage_File_Link__c
        WHERE Id = :linkId
      ];
      List<String> parsedUrl = link.File_Link__c.split('/');
      String documentId = parsedUrl[parsedUrl.size() - 1];

      iManageWrapper.ApiInfo apiInfo = iManageWrapper.GetApiInfo();
      iManageWrapper.iManageDocument documentInfo = iManageWrapper.GetDocument(
        apiInfo.customerId,
        apiInfo.library,
        documentId
      );
      Id contentDocId = SaveFileFromIManageDetails(
        link.ParentId__c,
        apiInfo,
        documentId,
        documentInfo.data.name,
        documentInfo.data.extension
      );

      delete link;

      return contentDocId;
    } catch (Exception ex) {
      Logger.getInstance().error(ex, 'iManageFileWorker::SaveLinkToSalesforce');
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
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
    iManageWrapper.ApiInfo apiInfo,
    String documentId,
    String documentName,
    String documentExtension
  ) {
    Map<String, Object> params = new Map<String, Object>{
      'recordId' => recordId,
      'apiInfo' => '***',
      'documentId' => documentId,
      'documentId' => documentName,
      'documentId' => documentExtension
    };

    Logger.getInstance()
      .info(
        'iManageFileWorker::SaveFileFromIManageDetails, start method. Params: ' +
        JSON.serialize(params)
      );

    Blob body = iManageWrapper.DownloadFile(
      apiInfo.customerId,
      apiInfo.library,
      documentId
    );

    ContentVersion version = createContentVersion(
      documentName,
      body,
      documentExtension
    );
    ContentVersion contentVersion = [
      SELECT Id, ContentDocumentId
      FROM ContentVersion
      WHERE Id = :version.Id
      LIMIT 1
    ];
    createContentDocumentLink(contentVersion.ContentDocumentId, recordId);
    return contentVersion.ContentDocumentId;
  }

  private static ContentVersion createContentVersion(
    String name,
    Blob body,
    String fileExtension
  ) {
    Map<String, Object> params = new Map<String, Object>{
      'name' => name,
      'body' => '***',
      'fileExtension' => fileExtension
    };

    Logger.getInstance()
      .info(
        'iManageFileWorker::createContentVersion, start method. Params: ' +
        JSON.serialize(params)
      );

    ContentVersion contentVersion = new ContentVersion(
      ContentLocation = 'S', // S = Stored in Salesforce
      PathOnClient = name + '.' + fileExtension,
      Title = name,
      VersionData = body
    );

    insert contentVersion;
    Logger.getInstance()
      .info(
        'iManageFileWorker::createContentVersion: Created ContentVersion. Id = ' +
        contentVersion.Id
      );
    return contentVersion;
  }

  private static Void createContentDocumentLink(
    Id contentDocumentId,
    Id parentId
  ) {
    Map<String, Object> params = new Map<String, Object>{
      'contentDocumentId' => contentDocumentId,
      'parentId' => parentId
    };

    Logger.getInstance()
      .info(
        'iManageFileWorker::createContentDocumentLink, start method. Params: ' +
        JSON.serialize(params)
      );

    ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
      ContentDocumentId = contentDocumentId,
      LinkedEntityId = parentId,
      ShareType = 'I', // Inferred permission
      Visibility = 'AllUsers'
    );

    insert contentDocumentLink;
    Logger.getInstance()
      .info(
        'iManageFileWorker::createContentDocumentLink: Created ContentDocumentLink. Id = ' +
        contentDocumentLink.Id
      );
  }
}
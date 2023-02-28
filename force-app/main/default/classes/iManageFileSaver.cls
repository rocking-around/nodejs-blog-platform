global class iManageFileSaver {
  global static void SaveFile(
    Blob data,
    string name,
    string extension,
    String entityId
  ) {
    LicenseService.CheckOrganizationLicense();

    iManageSettings__c mc = iManageSettings__c.getOrgDefaults();
    SaveFileToIManage(data, name, extension, mc.iManage_Default_Folder_Id__c);
  }

  private static blob GetFormBase64(Blob jsonBlob, Blob data) {
    //  Compose the form
    string form64 = '';

    form64 += vNHttpFormBuilder.WriteBoundary();
    vNHttpFormBuilder.WriteFileResult resultJson = vNHttpFormBuilder.WriteFile(
      'profile',
      'test',
      'application/json',
      jsonBlob
    );

    form64 += resultJson.Content;
    form64 += vNHttpFormBuilder.WriteBoundary(resultJson.EndingType, false);

    vNHttpFormBuilder.WriteFileResult result = vNHttpFormBuilder.WriteFile(
      'file',
      'f1.txt',
      'application/octet-stream',
      data
    );
    form64 += result.Content;
    form64 += vNHttpFormBuilder.WriteBoundary(result.EndingType, true);
    return EncodingUtil.base64Decode(form64);
  }

  private static String SaveFileToIManage(
    Blob data,
    string name,
    string extension,
    String folderId
  ) {
    iManageProvider.IManageApiDataResponse apiData = IManageFileHelper.GetApiData();

    string contentType = vNHttpFormBuilder.GetContentType();

    JSONGenerator gen = JSON.createGenerator(true);
    gen.writeStartObject();
    gen.writeFieldName('doc_profile');
    gen.writeStartObject();
    gen.writeStringField('name', name);
    gen.writeStringField('extension', extension);
    gen.writeEndObject();
    gen.writeBooleanField('warnings_for_required_and_disabled_fields', true);
    gen.writeEndObject();
    string json = gen.getAsString();

    blob jsonBlob = blob.valueOf(json);

    blob formBlob = GetFormBase64(jsonBlob, data);
    string contentLength = string.valueOf(formBlob.size());

    //  Compose the http request
    HttpRequest httpRequest = new HttpRequest();

    httpRequest.setEndpoint(
      'callout:iManageCreds/work/api/v2/customers/' +
      apiData.data.user.customer_id +
      '/libraries/' +
      apiData.data.work.preferred_library +
      '/folders/' +
      folderId +
      '/documents'
    );
    httpRequest.setBodyAsBlob(formBlob);
    httpRequest.setHeader('Connection', 'keep-alive');
    httpRequest.setHeader('Content-Length', contentLength);
    httpRequest.setHeader('Content-Type', contentType);
    httpRequest.setHeader(
      'X-Auth-Token',
      '{!$Credential.AuthorizationHeaderValue}'
    );
    httpRequest.setMethod('POST');
    httpRequest.setTimeout(120000);

    Http http = new Http();
    HTTPResponse res = http.send(httpRequest);
    String responseBody = res.getBody();

    NewFileResult newFile = (NewFileResult) System.JSON.deserialize(
      responseBody,
      NewFileResult.class
    );

    return newFile.data.id;
  }

  public class NewFileResult {
    public NewFileData data;
  }

  public class NewFileData {
    public String id;
  }
}

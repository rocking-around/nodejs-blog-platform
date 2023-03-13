public class IManageRequestHelper {
  public static String Get(String query) {
    return MakeRequest('GET', query, '').getBody();
  }

  public static Blob GetFile(String query) {
    return MakeRequest('GET', query, '').getBodyAsBlob();
  }

  public static String Post(String query, String body) {
    return MakeRequest('POST', query, body).getBody();
  }

  public static String PostFile(
    String query,
    Blob formBlob,
    String contentLength,
    String contentType
  ) {
    return MakeFileRequest('POST', query, formBlob, contentLength, contentType);
  }

  private static HttpRequest PrepareRequest(String type, String query) {
    HttpRequest httpRequest = new HttpRequest();
    httpRequest.setEndpoint('callout:iManageCreds' + query);
    httpRequest.setHeader('content-type', 'application/json');
    httpRequest.setHeader(
      'X-Auth-Token',
      '{!$Credential.AuthorizationHeaderValue}'
    );
    httpRequest.setMethod(type);

    return httpRequest;
  }

  private static HttpRequest PrepareFileRequest(
    String type,
    String query,
    Blob formBlob,
    String contentLength,
    String contentType
  ) {
    HttpRequest httpRequest = new HttpRequest();
    httpRequest.setEndpoint('callout:iManageCreds' + query);
    httpRequest.setHeader(
      'X-Auth-Token',
      '{!$Credential.AuthorizationHeaderValue}'
    );
    httpRequest.setMethod(type);

    httpRequest.setBodyAsBlob(formBlob);
    httpRequest.setHeader('Connection', 'keep-alive');
    httpRequest.setHeader('Content-Length', contentLength);
    httpRequest.setHeader('Content-Type', contentType);
    httpRequest.setTimeout(120000);

    return httpRequest;
  }

  private static HTTPResponse MakeRequest(
    String type,
    String query,
    String body
  ) {
    // System.debug('MakeRequest Pre: type = ' + type);
    // System.debug('MakeRequest Pre: query = ' + query);
    // System.debug('MakeRequest Pre: body = ' + body);
    HttpRequest httpRequest = PrepareRequest(type, query);
    if (body != '')
      httpRequest.setBody(body);
    Http http = new Http();
    HTTPResponse res = http.send(httpRequest);
    if (res.getStatusCode() == 401)
      throw new IManageExceptions.IManageUnauthorizedException();

    return res;
  }

  private static String MakeFileRequest(
    String type,
    String query,
    Blob formBlob,
    String contentLength,
    String contentType
  ) {
    HttpRequest httpRequest = PrepareFileRequest(
      type,
      query,
      formBlob,
      contentLength,
      contentType
    );

    Http http = new Http();
    HTTPResponse res = http.send(httpRequest);
    if (res.getStatusCode() == 401)
      throw new IManageExceptions.IManageUnauthorizedException();

    return res.getBody();
  }
}

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

  public static String Patch(String query, String body) {
    return MakeRequest('PATCH', query, body).getBody();
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
    Map<String, Object> params = new Map<String, Object>{
      'type' => type,
      'query' => query
    };

    Logger.getInstance()
      .info(
        'IManageRequestHelper::PrepareRequest, start method. Params: ' +
        JSON.serialize(params)
      );

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
    Map<String, Object> params = new Map<String, Object>{
      'type' => type,
      'query' => query,
      'formBlob' => '*** blob ***',
      'contentLength' => contentLength,
      'contentType' => contentType
    };

    Logger.getInstance()
      .info(
        'IManageRequestHelper::PrepareFileRequest, start method. Params: ' +
        JSON.serialize(params)
      );

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
    Map<String, Object> params = new Map<String, Object>{
      'type' => type,
      'query' => query,
      'body' => body
    };

    Logger.getInstance()
      .info(
        'IManageRequestHelper::MakeRequest, start method. Params: ' +
        JSON.serialize(params)
      );

    // System.debug('MakeRequest Pre: type = ' + type);
    // System.debug('MakeRequest Pre: query = ' + query);
    // System.debug('MakeRequest Pre: body = ' + body);
    HttpRequest httpRequest = PrepareRequest(type, query);
    if (body != '')
      httpRequest.setBody(body);
    Http http = new Http();
    HTTPResponse res = http.send(httpRequest);

    tryLogAsJson(httpRequest, res);

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
    Map<String, Object> params = new Map<String, Object>{
      'type' => type,
      'query' => query,
      'formBlob' => '*** blob ***',
      'contentLength' => contentLength,
      'contentType' => contentType
    };

    Logger.getInstance()
      .info(
        'IManageRequestHelper::MakeFileRequest, start method. Params: ' +
        JSON.serialize(params)
      );

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

  private static void tryLogAsJson(HttpRequest req, HTTPResponse resp) {
    try {
      Map<String, Object> result = new Map<String, Object>();
      // request info
      if (req != null) {
        String contentType = req.getHeader('content-type');
        Map<String, Object> reqInfo = new Map<String, Object> {
          'endpoint' => req.getEndpoint(),
          'method' => req.getMethod(),
          'contentType' => contentType
        };
        Object reqBody = null;
        String rawBody = req.getBody();
        if (contentType == 'application/json' && isJson(rawBody)) {
          reqBody = JSON.deserializeUntyped(rawBody);
        } else {
          reqBody = rawBody;
        }
        reqInfo.put('body', reqBody);
        result.put('request', reqInfo);
      }

      // response info
      if (resp != null) {
        String contentType = resp.getHeader('content-type');
        Map<String, Object> respInfo = new Map<String, Object> {
          'statusCode' => resp.getStatusCode(),
          'status' => resp.getStatus(),
          'contentType' => contentType
        };
        Object respBody = null;
        String rawBody = resp.getBody();
        if (contentType == 'application/json' && isJson(rawBody)) {
          respBody = JSON.deserializeUntyped(rawBody);
        } else {
          respBody = rawBody;
        }
        respInfo.put('body', respBody);
        result.put('response', respInfo);
      }

      Logger.getInstance()
        .info('iManageWrapper::tryLogAsJson: ' + JSON.serialize(result));
    } catch (Exception ex) {
      Logger.getInstance()
        .warn('IManageRequestHelper::tryLogAsJson, error:' + ex.getMessage());
    }
  }

  private static Boolean isJson(String s) {
    try {
      if (String.isBlank(s)) {
        return false;
      }
      JSON.deserializeUntyped(s);
      return true;
    } catch(Exception e) {
      return false;
    }
  }
}

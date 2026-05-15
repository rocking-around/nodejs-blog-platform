@isTest
public with sharing class EchoHttpMock implements HttpCalloutMock {
  Map<String, HttpResponse> responseByEndpoint;

  public EchoHttpMock(Map<String, HttpResponse> responseByEndpointOrContent) {
    this.responseByEndpoint = responseByEndpointOrContent;
  }

  public HTTPResponse respond(HTTPRequest req) {
    if (responseByEndpoint.containsKey(req.getEndpoint())) {
      return responseByEndpoint.get(req.getEndpoint());
    }
    for (String key : responseByEndpoint.keySet()) {
      if (req.getEndpoint().containsIgnoreCase(key)) {
        return responseByEndpoint.get(key);
      }
    }
    return null;
  }

  public static void setTestMockResponse(
    Map<String, HttpResponse> responseByEndpoint
  ) {
    Test.setMock(HttpCalloutMock.class, new EchoHttpMock(responseByEndpoint));
  }
}
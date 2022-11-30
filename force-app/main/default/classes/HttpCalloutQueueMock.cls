@isTest
public with sharing class HttpCalloutQueueMock implements HttpCalloutMock {
  Map<String, List<HttpResponse>> responseByEndpoint;

  public HttpCalloutQueueMock(
    Map<String, List<HttpResponse>> responseByEndpointOrContent
  ) {
    this.responseByEndpoint = responseByEndpointOrContent;
  }

  public HTTPResponse respond(HTTPRequest req) {
    if (responseByEndpoint.containsKey(req.getEndpoint())) {
      List<HttpResponse> responses = responseByEndpoint.get(req.getEndpoint());
      if (responses.size() > 0) {
        HttpResponse result = responses.get(0);
        responses.remove(0);
        return result;
      }
    }
    return null;
  }

  public static void setTestMockResponse(
    Map<String, List<HttpResponse>> responseByEndpoint
  ) {
    Test.setMock(
      HttpCalloutMock.class,
      new HttpCalloutQueueMock(responseByEndpoint)
    );
  }
}

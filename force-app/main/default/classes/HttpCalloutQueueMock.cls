@isTest
public with sharing class HttpCalloutQueueMock implements HttpCalloutMock {
  Map<String, List<HttpResponse>> responseByEndpoint;
  Boolean leaveLastItemInQueue = false;

  public HttpCalloutQueueMock(
    Map<String, List<HttpResponse>> responseByEndpointOrContent
  ) {
    this(responseByEndpointOrContent, false);
  }

  public HttpCalloutQueueMock(
    Map<String, List<HttpResponse>> responseByEndpointOrContent,
    Boolean leaveLastItemInQueue
  ) {
    this.responseByEndpoint = responseByEndpointOrContent;
    this.leaveLastItemInQueue = leaveLastItemInQueue;

    this.printInfo();
  }

  public HTTPResponse respond(HTTPRequest req) {
    System.debug('HttpCalloutQueueMock::respond(). Start. Endpont = ' + req.getEndpoint());
    if (responseByEndpoint.containsKey(req.getEndpoint())) {
      List<HttpResponse> responses = responseByEndpoint.get(req.getEndpoint());
      if (responses.size() > 0) {
        HttpResponse result = responses.get(0);
        if (!(responses.size() == 1 && leaveLastItemInQueue)) {
          responses.remove(0);
        }
        System.debug('HttpCalloutQueueMock::respond(). Endpont result = ' + result);
        System.debug('HttpCalloutQueueMock::respond(). Endpont = "' + req.getEndpoint() + '" . There are ' + responses.size() + ' responses left.');
        return result;
      }
    }
    System.debug('HttpCalloutQueueMock::respond(). Endpont = "' + req.getEndpoint() + '" not found');
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

  public static void setTestMockResponse(
    Map<String, List<HttpResponse>> responseByEndpoint, Boolean leaveLastItemInQueue
  ) {
    Test.setMock(
      HttpCalloutMock.class,
      new HttpCalloutQueueMock(responseByEndpoint, leaveLastItemInQueue)
    );
  }

  private void printInfo() {
    List<Object> result = new List<Object>();
    for (String key : this.responseByEndpoint.keySet()) {
      Map<String, Object> item = new Map<String, Object> {
        'endpoint' => key,
        'responses' => this.responseByEndpoint.get(key).size()
      };
      result.add(item);
    }
    System.debug('HttpCalloutQueueMock::constructor() callouts = ' + JSON.serialize(result));
  }
}

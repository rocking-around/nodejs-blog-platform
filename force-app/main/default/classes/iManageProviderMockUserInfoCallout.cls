@isTest global class iManageProviderMockUserInfoCallout implements HttpCalloutMock {
	global HTTPResponse respond(HTTPRequest req) {
		HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"data": { "user": { "id":"12345","name":"test test","email":"test@test.test","customer_id":"1" }, "work": { "preferred_library": "LOCAL" }}}');
        res.setStatusCode(200);
        return res;
    }
}
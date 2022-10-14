@isTest global class iManageProviderMockRefreshCallout implements HttpCalloutMock {
	global HTTPResponse respond(HTTPRequest req) {
		HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"access_token":"12345","token_type":"test","scope": "global","expires_in":"50","refresh_token":"123456"}');
        res.setStatusCode(200);
        return res;
    }
}
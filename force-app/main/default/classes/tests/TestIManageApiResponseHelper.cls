public with sharing class TestIManageApiResponseHelper {
    public HttpResponse buildGetWorkspaceResponse(Integer statusCode, IManageWWorkspace ws){
        iManageWrapper.iManageWorkspaceResponse body = new iManageWrapper.iManageWorkspaceResponse();
        body.data = ws;
        return buildResponse(statusCode, body, 'buildGetWorkspaceResponse');
    }

    public HttpResponse buildSearchWorkspaceResponse(Integer statusCode, List<IManageWWorkspace> wss){
        iManageWrapper.iManageWorkspaceOnPremiseSearchResults searchResults = new iManageWrapper.iManageWorkspaceOnPremiseSearchResults();
        searchResults.results = wss;
        iManageWrapper.iManageWorkspaceOnPremiseSearch body = new iManageWrapper.iManageWorkspaceOnPremiseSearch();
        body.data = searchResults;
        return buildResponse(statusCode, body, 'buildSearchWorkspaceResponse');
    }

    public HttpResponse buildSearchTemplateWorkspaceResponse(Integer statusCode, List<IManageWWorkspace> wss){
        iManageWrapper.iManageTemplates searchResults = new iManageWrapper.iManageTemplates();
        searchResults.results = wss;
        iManageWrapper.iManageTemplatesResponse body = new iManageWrapper.iManageTemplatesResponse();
        body.data = searchResults;
        body.total_count = wss.size();

        return buildResponse(statusCode, body, 'buildSearchTemplateWorkspaceResponse');
    }

    public HttpResponse buildWorkspaceResponse(Integer statusCode, IManageWWorkspace ws){
        iManageWrapper.iManageWorkspaceResponse body = new iManageWrapper.iManageWorkspaceResponse();
        body.data = ws;
        return buildResponse(statusCode, body, 'buildWorkspaceResponse');
    }

    public HttpResponse buildWFolderResponse(Integer statusCode, IManageWFolder folder){
        iManageWrapper.iManageWFolderResponse body = new iManageWrapper.iManageWFolderResponse();
        body.data = folder;
        return buildResponse(statusCode, body, 'buildWFolderResponse');
    }

    public HttpResponse buildTabResponse(Integer statusCode, IManageWFolder folder){
        iManageWrapper.IManageTabResponse body = new iManageWrapper.IManageTabResponse();
        body.data = folder;
        return buildResponse(statusCode, body, 'buildTabResponse');
    }

    public HttpResponse buildFoldersResponse(Integer statusCode, List<IManageWFolder> folders){
        iManageWrapper.iManageFoldersResponse body = new iManageWrapper.iManageFoldersResponse();
        body.data = folders;
        body.total_count = body.data.size();
        return buildResponse(statusCode, body, 'buildFoldersResponse');
    }

    public HttpResponse buildFolderSecurityResponse(Integer statusCode, List<IManageWSecurity> data, String default_security){
        iManageWrapper.iManageSecurityResponse body = new iManageWrapper.iManageSecurityResponse();
        body.data = data;
        body.default_security = default_security;
        return buildResponse(statusCode, body, 'buildFolderSecurityResponse');
    }

    public HttpResponse buildNameValuePairResponse(Integer statusCode, Map<String, String> data){
        iManageWrapper.iManageNameValuePairResponse body = new iManageWrapper.iManageNameValuePairResponse();
        body.data = data;
        return buildResponse(statusCode, body, 'buildNameValuePairResponse');
    }

    public HttpResponse buildPatchNameValuePairResponse(Integer statusCode, Object data){
        return buildResponse(statusCode, data, 'buildPatchNameValuePairResponse');
    }

    public HttpResponse build404Response(){
        IManageResponseError err = new IManageResponseError();
        err.code = 'NRC_NO_RECORD';
        err.code_message = 'No record found';
        return buildResponse(404, err, 'build404Response');
    }

    public HttpResponse buildEmptyResponse(Integer statusCode){
        return buildResponse(statusCode, null, 'buildEmptyResponse');
    }

    public HttpResponse buildUntypedResponse(Integer statusCode, Object data){
        return buildResponse(statusCode, data, 'buildUntypedResponse');
    }

    private HttpResponse buildResponse(Integer statusCode, Object body, String methodName){
        HttpResponse resp = new HttpResponse();
        resp.setStatusCode(statusCode);
        if (body != null) {
            String jsonBody = JSON.serialize(body);
            System.debug('TestIManageApiResponseHelper.buildResponse::' + methodName + '. body = ' + jsonBody);
            resp.setBody(jsonBody);
        }
        return resp;
    }
}
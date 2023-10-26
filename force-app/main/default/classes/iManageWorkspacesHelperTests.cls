@isTest
private class iManageWorkspacesHelperTests {
    @IsTest
    static void isEntityWorkspaceAlreadyCreatedTest() {
        // prepare data
        String entityId = TestUtils.getFakeId(Opportunity.SObjectType);
        String wsId = 'ws-01';
        String wsName= 'ws-name';
        String source= 'SF';
        String libraryId= 'ACTIVE';
        Boolean autoCreated = false;

        System.debug('iManageWorkspacesHelperTests::isEntityWorkspaceAlreadyCreatedTest entityId = ' + entityId);
        IManage_WS_to_Entity_Mapping__c mapping = new IManage_WS_to_Entity_Mapping__c(
            Auto_created__c = false,
            EntityId__c = entityId,
            iManage_Workspace_Created_On__c = '2023-10-25T22:21:47.494Z',
            iManage_WS_Id__c = wsId,
            iManage_WS_Name__c = wsName,
            Source__c = source
        );
        insert mapping;

        Test.startTest();
        Boolean result = iManageWorkspacesHelper.isEntityWorkspaceAlreadyCreated(entityId);
        System.debug('iManageWorkspacesHelperTests::isEntityWorkspaceAlreadyCreatedTest result = ' + result);
        Test.stopTest();

        System.assert(result == true, 'Wrong value =' + result);
    }

    @IsTest
    static void isEntityWorkspaceAlreadyCreatedExceptionTest() {
        // prepare data
        String entityId = 'wrongId';

        Test.startTest();
        try{
            Boolean result = iManageWorkspacesHelper.isEntityWorkspaceAlreadyCreated(entityId);
        } catch (StringException ex) {
            System.assertEquals('Invalid id: ' + entityId, ex.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void updateEntityToWsMappingTest() {
        // prepare data
        String entityId = TestUtils.getFakeId(Opportunity.SObjectType);
        String wsId = 'ws-01';
        String wsName = 'ws-name';
        String source = 'SF';
        String library = 'TEST_LIB';
        Integer customerId = 1;
        Boolean autoCreated = false;

        IManageWWorkspace ws = new IManageWWorkspace();
        ws.id = wsId;
        ws.name = wsName;
        // mock callouts
        String getWorkspaceEndpoint = 'callout:iManageCreds' + String.format('/work/api/v2/customers/{0}/libraries/{1}/workspaces/{2}',
            new List<Object>{
                customerId,
                library,
                wsId
            }
        );
        IManageApiResponseHelper respHelper = new IManageApiResponseHelper();
        Map<String, List<HttpResponse>> responses = new Map<String, List<HttpResponse>>{
            getWorkspaceEndpoint => new List<HttpResponse>{
                respHelper.buildGetWorkspaceResponse(200, ws)
            }
        };
        setupMockCallouts(customerId, library, responses);
        //--

        Test.startTest();
        Id id = iManageWorkspacesHelper.updateEntityToWsMapping(
            wsId,
            library,
            entityId,
            autoCreated,
            source
        );
        Boolean result = iManageWorkspacesHelper.isEntityWorkspaceAlreadyCreated(entityId);
        Test.stopTest();

        System.assert(result == true, 'Wrong value =' + result);
    }

    @isTest
    static void searchWorkspaceTest() {
        // prepare data
        String matterId = TestUtils.getFakeId(Opportunity.SObjectType);
        String clientId = TestUtils.getFakeId(Account.SObjectType);

        Integer customerId = 1;
        String library = 'TEST_LIB';
        String folderTemplateId = library + '!2615';
        String folderTemplate = library + '::' + folderTemplateId;
        String wsNamePattern = '{CLIENTCODE}-{MATTERCODE}_{MATTERNAME}';
        String settingsLibs = '';
        String workspaceId = library + '!3333';

        iManageSettings__c mc = getIManageSettings(
            folderTemplate,
            wsNamePattern,
            settingsLibs
        );
        iManageWrapper.ApiInfo apiData = getApiInfo(1, library);
        IManageMappingHelper.IManageIFrameData ifData = new IManageMappingHelper.IManageIFrameData();
        ifData.ClientId = clientId;
        ifData.MatterId = matterId;

        // mock callouts
        String searchWorkspaceEndpoint = 'callout:iManageCreds' + String.format('/work/api/v2/customers/{0}/libraries/{1}/workspaces?{2}={3}&{4}={5}',
            new List<Object>{
                customerId,
                library,
                mc.ClientField__c,
                clientId,
                mc.MatterField__c,
                matterId
            }
        );

        iManageWrapper.iManageWorkspace ws = new iManageWrapper.iManageWorkspace();
        ws.id = workspaceId;
        ws.database = library;

        List<iManageWrapper.iManageWorkspace> workspaces = new List<iManageWrapper.iManageWorkspace> {
            ws
        };
        IManageApiResponseHelper respHelper = new IManageApiResponseHelper();
        Map<String, List<HttpResponse>> responses = new Map<String, List<HttpResponse>>{
            searchWorkspaceEndpoint => new List<HttpResponse>{
                respHelper.buildSearchWorkspaceResponse(200, workspaces)
            }
        };
        setupMockCallouts(customerId, library, responses);
        //--

        Test.startTest();
		String result = iManageWorkspacesHelper.SearchWorkspace(
            mc,
            apiData,
            ifData
        );
        Test.stopTest();

        System.assert(String.isNotBlank(result), 'result is blank');
        System.assert(result == workspaceId, 'Wrong value = ' + result + ', expected = ' + workspaceId);
    }

    @isTest
    static void findTemplateWorkspaceByNameTest() {
        // prepare data
        Integer customerId = 1;
        String library = 'TEST_LIB';
        String templateName = 'TEST_Template';
        String workspaceId = library + '!3333';

        // mock callouts
        String findTemplateEndpoint = 'callout:iManageCreds' + String.format(
            '/work/api/v2/customers/{0}/libraries/{1}/templates?offset={2}&limit={3}&total=true&name_or_description={4}',
            new List<Object>{ customerId, library, 0, 2000, templateName }
        );
        IManageWWorkspace ws = new IManageWWorkspace();
        ws.id = workspaceId;
        ws.name = templateName;

        List<IManageWWorkspace> workspaces = new List<IManageWWorkspace> {
            ws
        };
        IManageApiResponseHelper respHelper = new IManageApiResponseHelper();
        Map<String, List<HttpResponse>> responses = new Map<String, List<HttpResponse>>{
            findTemplateEndpoint => new List<HttpResponse>{
                respHelper.buildSearchTemplateWorkspaceResponse(200, workspaces)
            }
        };
        setupMockCallouts(customerId, library, responses);
        //--

        Test.startTest();
        IManageWWorkspace result = iManageWorkspacesHelper.findTemplateWorkspaceByName(
            templateName,
            library
        );
        Test.stopTest();

        System.assert(result != null, 'result is null');
        System.assert(result.id == workspaceId, 'Wrong value = ' + result + ', expected = ' + workspaceId);
        System.assert(result.name == templateName, 'Wrong value = ' + result + ', expected = ' + workspaceId);
    }

    private static iManageSettings__c getIManageSettings(
        String folderTemplate,
        String wsNamePattern,
        String libraries
    ) {
        iManageSettings__c settings = new iManageSettings__c(
            Client_Id__c = 'val1',
            ClientField__c = 'custom1',
            MatterField__c = 'custom2',
            Url__c = 'val4',
            iManage_Default_Folder_Id__c = 'val5',
            Enable_CSV_Export__c = true,
            Mapping_EntityType__c = 'Opportunity',
            Mapping_EntityMatterIdObjectField__c = 'Opportunity',
            Mapping_MatterIdField__c = 'Id',
            Mapping_MatterNameField__c = 'Name',
            Mapping_EntityClientIdObjectField__c = 'AccountId',
            Mapping_ClientIdField__c = 'Id',
            Mapping_ClientNameField__c = 'Name',
            iManage_Create_Ws_Enabled__c = true,
            iManage_Ws_Auto_Create__c = false,
            iManage_Ws_Folder_Template_Id__c = folderTemplate,
            iManage_Ws_Name_Pattern__c = wsNamePattern,
            iManage_Libraries__c = libraries
        );
        return settings;
    }

    private static iManageWrapper.ApiInfo getApiInfo(Integer customerId, String library) {
        iManageWrapper.ApiInfo result = new iManageWrapper.ApiInfo();
        result.customerId = String.valueOf(customerId);
        result.library = library;
        return result;
    }

    private static void setupMockCallouts(Integer customerId, String library, Map<String, List<HttpResponse>> mockCallouts) {
        String licenseUrl = TestUtils.getLicenseApiUrl();
        Organization org = TestUtils.getOrganization();
        String orgId = String.valueOf(org.Id);

        Map<String, List<HttpResponse>> responses = new Map<String, List<HttpResponse>>{
            'callout:iManageCreds/api' => new List<HttpResponse> {
                TestUtils.getMockAuthResponse(200, 'authenticated', customerId, library)
            },
            licenseUrl => new List<HttpResponse>{
                TestUtils.getMockLicenseResponse(200, orgId)
            }
        };
        if (mockCallouts != null) {
            responses.putAll(mockCallouts);
        }
        HttpCalloutQueueMock.setTestMockResponse(responses, true);
        System.debug('iManageWorkspacesHelperTests::setupMockCallouts: mocked callouts = ' + String.join(responses.keySet(), ', '));
    }

    class IManageApiResponseHelper {
        public HttpResponse buildGetWorkspaceResponse(Integer statusCode, IManageWWorkspace ws){
            HttpResponse resp = new HttpResponse();
            iManageWrapper.iManageWorkspaceResponse body = new iManageWrapper.iManageWorkspaceResponse();
            body.data = ws;

            resp.setStatusCode(statusCode);
            String jsonBody = JSON.serialize(body);
            System.debug('iManageWorkspacesHelperTests.IManageApiResponseHelper::buildGetWorkspaceResponse. body = ' + jsonBody);
            resp.setBody(jsonBody);
            return resp;
        }
        public HttpResponse buildSearchWorkspaceResponse(Integer statusCode, List<iManageWrapper.iManageWorkspace> wss){
            HttpResponse resp = new HttpResponse();
            iManageWrapper.iManageWorkspaceOnPremiseSearchResults searchResults = new iManageWrapper.iManageWorkspaceOnPremiseSearchResults();
            searchResults.results = wss;
            iManageWrapper.iManageWorkspaceOnPremiseSearch body = new iManageWrapper.iManageWorkspaceOnPremiseSearch();
            body.data = searchResults;

            resp.setStatusCode(statusCode);
            String jsonBody = JSON.serialize(body);
            System.debug('iManageWorkspacesHelperTests.IManageApiResponseHelper::buildSearchWorkspaceResponse. body = ' + jsonBody);
            resp.setBody(jsonBody);
            return resp;
        }
        public HttpResponse buildSearchTemplateWorkspaceResponse(Integer statusCode, List<IManageWWorkspace> wss){
            HttpResponse resp = new HttpResponse();
            iManageWrapper.iManageTemplates searchResults = new iManageWrapper.iManageTemplates();
            searchResults.results = wss;
            iManageWrapper.iManageTemplatesResponse body = new iManageWrapper.iManageTemplatesResponse();
            body.data = searchResults;
            body.total_count = wss.size();

            resp.setStatusCode(statusCode);
            String jsonBody = JSON.serialize(body);
            System.debug('iManageWorkspacesHelperTests.IManageApiResponseHelper::buildSearchTemplateWorkspaceResponse. body = ' + jsonBody);
            resp.setBody(jsonBody);
            return resp;
        }
    }
}
@SuppressWarnings('PMD.LocalVariableNamingConventions')
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
        String getWorkspaceEndpoint = TestUtils.buildCalloutUrl('/work/api/v2/customers/{0}/libraries/{1}/workspaces/{2}',
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
        upsert mc;

        iManageWrapper.ApiInfo apiData = getApiInfo(1, library);
        IManageMappingHelper.IManageIFrameData ifData = new IManageMappingHelper.IManageIFrameData();
        ifData.ClientId = clientId;
        ifData.MatterId = matterId;

        // mock callouts
        String searchWorkspaceEndpoint = TestUtils.buildCalloutUrl('/work/api/v2/customers/{0}/libraries/{1}/workspaces?{2}={3}&{4}={5}',
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
        String findTemplateEndpoint = TestUtils.buildCalloutUrl(
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

    @isTest
    static void createWorkspaceTest() {
        // prepare data
        String library = 'Active';

        //-- Folder template
        String folderTemplate_id = library + '!2615';
        String folderTemplate_child_1_1_id = library + '!2616';
        String folderTemplate_child_1_2_id = library + '!2617';
        String folderTemplate_tab_1_3_id = library + '!2633';
        String folderTemplate_search_1_3_1_id = library + '!2634';
        String folderTemplate_child_1_1_1_id = library + '!2635';

        // -- Created ws
        String ws_id = library + '!2711';
        String ws_tab_1_3_id = library + '!2712';
        String ws_child_1_1_id = library + '!2713';
        String ws_child_1_2_id = library + '!2714';
        String ws_search_1_3_1_id = library + '!2715';
        String ws_child_1_1_1_id = library + '!2716';

        Integer customerId = 1;
        String workspaceTemplate = library + '::' + folderTemplate_id;
        //String wsNamePattern = '{CLIENTCODE}-{MATTERCODE}_{MATTERNAME}';
        String settingsLibs = '';
        String matterId = '1B71446';
        String workspaceName = '1-1B71446_Test 1';


        // mock callouts
        // folder template !2615
        String getFolderTemplateEndpoint = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/workspaces/{2}',
            new List<Object>{ customerId, library, folderTemplate_id }
        );

        String folderTemplateJson = '{"create_date":"2023-10-24T21:13:10.78Z","database":"ACTIVE","default_security":"public","description":"test template","edit_date":"2023-10-24T21:13:11.102Z","effective_security":"full_access","has_subfolders":true,"id":"Active!2615","is_declared":false,"is_external":false,"is_external_as_normal":false,"last_user":"TESTUSER","last_user_description":"testuser","name":"sf_test","owner_description":"testuser","owner":"TESTUSER","create_profile_date":"2023-10-24T21:13:10.78Z","document_number":252502,"is_hipaa":false,"iwl":"iwl:dms=cloudimanage.com&&lib=Active&&num=252502&&ver=1","retain_days":365,"system_edit_date":"2023-10-24T21:13:11.102Z","version":1,"wstype":"workspace"}';
        IManageWWorkspace folderTemplate = (IManageWWorkspace) JSON.deserialize(
            folderTemplateJson,
            IManageWWorkspace.class
        );

        // workspace !2711
        String getWorkspaceEndpoint = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/workspaces/{2}',
            new List<Object>{ customerId, library, ws_id }
        );
        String wsJson_get = '{"create_date":"2023-10-26T23:05:23.373Z","database":"ACTIVE","default_security":"public","description":"test template","edit_date":"2023-10-26T23:05:23.373Z","effective_security":"full_access","has_subfolders":false,"id":"Active!2711","is_declared":false,"is_external":false,"is_external_as_normal":false,"last_user":"TESTUSER","last_user_description":"testuser","name":"' + workspaceName + '","owner":"TESTUSER","owner_description":"testuser","create_profile_date":"2023-10-26T23:05:23.373Z","custom1":"1","custom1_description":"Salesforce test","custom1_ssid":"100490070984242850","custom2":"1B71446","custom2_description":"Salesforce test","custom2_ssid":"100490070984242874","document_number":254922,"is_hipaa":false,"iwl":"iwl:dms=cloudimanage.com&&lib=Active&&num=254922&&ver=1","retain_days":365,"system_edit_date":"2023-10-26T23:05:23.373Z","version":1,"wstype":"workspace"}';
        IManageWWorkspace workspace_get = (IManageWWorkspace) JSON.deserialize(
            wsJson_get,
            IManageWWorkspace.class
        );

        // workspace folders
        String getWorkspaceFoldersEndpoint = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders?total=true&offset=0&limit=200&container_id={2}',
            new List<Object>{ customerId, library, ws_id }
        );
        List<IManageWFolder> wsFolders = new List<IManageWFolder>();

        // folder template folders
        String getFolderTemplateFoldersEndpoint = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders?total=true&offset=0&limit=200&container_id={2}',
            new List<Object>{ customerId, library, folderTemplate_id }
        );
        String ftFoldersJson = '[{"database":"ACTIVE","default_security":"inherit","edit_date":"2023-10-25T13:27:37.765Z","folder_type":"regular","has_documents":false,"has_subfolders":false,"id":"Active!2635","inherited_default_security":"public","is_container_saved_search":false,"is_content_saved_search":false,"is_external":false,"is_external_as_normal":false,"name":"sf_test_child_1_1_1","owner":"TESTUSER","owner_description":"testuser","parent_id":"Active!2616","view_type":"document","workspace_name":"sf_test","workspace_id":"Active!2615","wstype":"folder"},{"content_saved_search_id":100490070984294934,"database":"ACTIVE","default_security":"inherit","edit_date":"2023-10-25T13:26:16.51Z","folder_type":"search","has_documents":false,"has_subfolders":false,"id":"Active!2634","inherited_default_security":"public","is_container_saved_search":false,"is_content_saved_search":true,"is_external":false,"is_external_as_normal":false,"name":"sf_test_search_1_3_1","owner":"TESTUSER","owner_description":"testuser","parent_id":"Active!2633","view_type":"document","workspace_name":"sf_test","workspace_id":"Active!2615","wstype":"folder"},{"database":"ACTIVE","default_security":"inherit","edit_date":"2023-10-25T13:26:02.093Z","folder_type":"tab","has_documents":false,"has_subfolders":true,"id":"Active!2633","inherited_default_security":"public","is_container_saved_search":false,"is_content_saved_search":false,"is_external":false,"is_external_as_normal":false,"name":"sf_test_tab_1_3","owner":"TESTUSER","owner_description":"testuser","parent_id":"Active!2615","view_type":"document","workspace_name":"sf_test","workspace_id":"Active!2615","wstype":"folder"},{"database":"ACTIVE","default_security":"inherit","edit_date":"2023-10-24T21:14:20.697Z","folder_type":"regular","has_documents":false,"has_subfolders":false,"id":"Active!2617","inherited_default_security":"public","is_container_saved_search":false,"is_content_saved_search":false,"is_external":false,"is_external_as_normal":false,"name":" sf_test_child_1_2","owner":"TESTUSER","owner_description":"testuser","parent_id":"Active!2615","view_type":"document","workspace_name":"sf_test","workspace_id":"Active!2615","wstype":"folder"},{"database":"ACTIVE","default_security":"inherit","edit_date":"2023-10-24T21:14:02.7Z","folder_type":"regular","has_documents":false,"has_subfolders":true,"id":"Active!2616","inherited_default_security":"public","is_container_saved_search":false,"is_content_saved_search":false,"is_external":false,"is_external_as_normal":false,"name":"sf_test_child_1_1","owner":"TESTUSER","owner_description":"testuser","parent_id":"Active!2615","view_type":"document","workspace_name":"sf_test","workspace_id":"Active!2615","wstype":"folder"}]';
        List<IManageWFolder> folderTemplateFolders = (List<IManageWFolder>) JSON.deserialize(
            ftFoldersJson,
            List<IManageWFolder>.class
        );

        // 3 createWorkspaceApiCall
        String createWorkspaceEndpoint = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/workspaces',
            new List<Object>{ customerId, library }
        );
        String wsJson_create = '{"create_date":"2023-10-26T23:05:23.373Z","database":"ACTIVE","default_security":"public","description":"test template","edit_date":"2023-10-26T23:05:23.373Z","effective_security":"full_access","has_subfolders":false,"id":"Active!2711","is_declared":false,"is_external":false,"is_external_as_normal":false,"last_user":"TESTUSER","last_user_description":"testuser","name":"' + workspaceName + '","owner_description":"testuser","owner":"TESTUSER","create_profile_date":"2023-10-26T23:05:23.373Z","custom1_description":"Salesforce test","custom1_ssid":"100490070984242850","custom1":"1","custom2":"1B71446","custom2_description":"Salesforce test","custom2_ssid":"100490070984242874","document_number":254922,"is_hipaa":false,"iwl":"iwl:dms=cloudimanage.com&&lib=Active&&num=254922&&ver=1","retain_days":365,"system_edit_date":"2023-10-26T23:05:23.373Z","version":1,"wstype":"workspace"}';
        IManageWWorkspace createdWs = (IManageWWorkspace) JSON.deserialize(
            wsJson_create,
            IManageWWorkspace.class
        );

        // getNameValuePair folderTemplate_tab_1_3
        String getNameValuePairEndpoint_folderTemplate_tab_1_3 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}/name-value-pairs',
            new List<Object>{ customerId, library, folderTemplate_tab_1_3_id }
        );
        String folderTemplate_tab_1_3_nvp_json = '{"IMCC_IsOptional":"false"}';
        Map<String, String> folderTemplate_tab_1_3_data_nvp = (Map<String, String>) JSON.deserialize(
            folderTemplate_tab_1_3_nvp_json,
            Map<String, String>.class
        );

        // getNameValuePair folderTemplate_child_1_1
        String getNameValuePairEndpoint_folderTemplate_child_1_1 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}/name-value-pairs',
            new List<Object>{ customerId, library, folderTemplate_child_1_1_id }
        );
        String folderTemplate_child_1_1_nvp_json = '{"iMan___28":"%WORKSPACE_VALUE%","iMan___29":"%WORKSPACE_VALUE%","icc_isrename":"0","iMan___25":"%WORKSPACE_VALUE%","iMan___26":"%WORKSPACE_VALUE%","iMan___8":"DOC","iMan___27":"%WORKSPACE_VALUE%","IMCC_IsOptional":"false"}';
        Map<String, String> folderTemplate_child_1_1_data_nvp = (Map<String, String>) JSON.deserialize(
            folderTemplate_child_1_1_nvp_json,
            Map<String, String>.class
        );

        // getNameValuePair folderTemplate_child_1_2
        String getNameValuePairEndpoint_folderTemplate_child_1_2 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}/name-value-pairs',
            new List<Object>{ customerId, library, folderTemplate_child_1_2_id }
        );
        String folderTemplate_child_1_2_nvp_json = '{"icc_isrename":"0","IMCC_IsOptional":"false"}';
        Map<String, String> folderTemplate_child_1_2_data_nvp = (Map<String, String>) JSON.deserialize(
            folderTemplate_child_1_2_nvp_json,
            Map<String, String>.class
        );

        // getNameValuePair folderTemplate_search_1_3_1
        String getNameValuePairEndpoint_folderTemplate_search_1_3_1 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}/name-value-pairs',
            new List<Object>{ customerId, library, folderTemplate_search_1_3_1_id }
        );
        String folderTemplate_search_1_3_1_nvp_json = '{"icc_isrename":"0","IMCC_IsOptional":"false"}';
        Map<String, String> folderTemplate_search_1_3_1_data_nvp = (Map<String, String>) JSON.deserialize(
            folderTemplate_search_1_3_1_nvp_json,
            Map<String, String>.class
        );

        // getNameValuePair folderTemplate_child_1_1_1
        String getNameValuePairEndpoint_folderTemplate_child_1_1_1 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}/name-value-pairs',
            new List<Object>{ customerId, library, folderTemplate_child_1_1_1_id }
        );
        String folderTemplate_child_1_1_1_nvp_json = '{"iMan___28":"%WORKSPACE_VALUE%","iMan___29":"%WORKSPACE_VALUE%","icc_isrename":"0","iMan___25":"1","iMan___26":"1B71446","iMan___27":"ADM","IMCC_IsOptional":"false"}';
        Map<String, String> folderTemplate_child_1_1_1_data_nvp = (Map<String, String>) JSON.deserialize(
            folderTemplate_child_1_1_1_nvp_json,
            Map<String, String>.class
        );

        // getFolderById  folderTemplate_tab_1_3
        String getFolderByIdEndpoint_folderTemplate_tab_1_3 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}',
            new List<Object>{ customerId, library, folderTemplate_tab_1_3_id }
        );
        String  folderTemplate_tab_1_3_json = '{"database":"ACTIVE","default_security":"inherit","edit_date":"2023-10-25T13:26:02.093Z","effective_security":"full_access","folder_type":"tab","has_documents":false,"has_subfolders":true,"id":"Active!2633","inherited_default_security":"public","is_container_saved_search":false,"is_content_saved_search":false,"is_external":false,"is_external_as_normal":false,"name":"sf_test_tab_1_3","owner":"TESTUSER","owner_description":"testuser","owner_info":{"allow_logon":true,"is_external":false},"parent_id":"Active!2615","profile":{},"view_type":"document","workspace_id":"Active!2615","workspace_name":"sf_test","wstype":"folder"}';
        IManageWFolder folderTemplate_tab_1_3_data = (IManageWFolder) JSON.deserialize(
            folderTemplate_tab_1_3_json,
            IManageWFolder.class
        );

        // getFolderById folderTemplate_child_1_1
        String getFolderByIdEndpoint_folderTemplate_child_1_1 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}',
            new List<Object>{ customerId, library, folderTemplate_child_1_1_id }
        );
        String  folderTemplate_child_1_1_json = '{"database":"ACTIVE","default_security":"inherit","edit_date":"2023-10-24T21:14:02.7Z","effective_security":"full_access","folder_type":"regular","has_documents":false,"has_subfolders":true,"id":"Active!2616","inherited_default_security":"public","is_container_saved_search":false,"is_content_saved_search":false,"is_external":false,"is_external_as_normal":false,"name":"sf_test_child_1_1","owner":"TESTUSER","owner_description":"testuser","owner_info":{"allow_logon":true,"is_external":false},"parent_id":"Active!2615","profile":{"class":"DOC","class_description":"Document","custom1_ssid":"","custom1":"%WORKSPACE_VALUE%","custom2":"%WORKSPACE_VALUE%","custom2_ssid":"","custom3_ssid":"","custom3":"%WORKSPACE_VALUE%","custom4_ssid":"","custom4":"%WORKSPACE_VALUE%","custom5":"%WORKSPACE_VALUE%","custom5_ssid":""},"view_type":"document","workspace_name":"sf_test","workspace_id":"Active!2615","wstype":"folder"}';
        IManageWFolder folderTemplate_child_1_1_data = (IManageWFolder) JSON.deserialize(
            folderTemplate_child_1_1_json,
            IManageWFolder.class
        );

        // getFolderById folderTemplate_child_1_2
        String getFolderByIdEndpoint_folderTemplate_child_1_2 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}',
            new List<Object>{ customerId, library, folderTemplate_child_1_2_id }
        );
        String  folderTemplate_child_1_2_json = '{"database":"ACTIVE","default_security":"inherit","edit_date":"2023-10-24T21:14:20.697Z","effective_security":"full_access","folder_type":"regular","has_documents":false,"has_subfolders":false,"id":"Active!2617","inherited_default_security":"public","is_container_saved_search":false,"is_content_saved_search":false,"is_external":false,"is_external_as_normal":false,"name":" sf_test_child_1_2","owner_description":"testuser","owner":"TESTUSER","owner_info":{"allow_logon":true,"is_external":false},"parent_id":"Active!2615","profile":{},"view_type":"document","workspace_name":"sf_test","workspace_id":"Active!2615","wstype":"folder"}';
        IManageWFolder folderTemplate_child_1_2_data = (IManageWFolder) JSON.deserialize(
            folderTemplate_child_1_2_json,
            IManageWFolder.class
        );

        // getFolderById folderTemplate_child_1_1_1
        String getFolderByIdEndpoint_folderTemplate_child_1_1_1 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}',
            new List<Object>{ customerId, library, folderTemplate_child_1_1_1_id }
        );
        String folderTemplate_child_1_1_1_json = '{"database":"ACTIVE","default_security":"inherit","edit_date":"2023-10-25T13:27:37.765Z","effective_security":"full_access","folder_type":"regular","has_documents":false,"has_subfolders":false,"id":"Active!2635","inherited_default_security":"public","is_container_saved_search":false,"is_content_saved_search":false,"is_external":false,"is_external_as_normal":false,"name":"sf_test_child_1_1_1","owner":"TESTUSER","owner_description":"testuser","owner_info":{"allow_logon":true,"is_external":false},"parent_id":"Active!2616","profile":{"custom1_description":"Salesforce test","custom1_ssid":"100490070984242850","custom1":"1","custom2_description":"Salesforce test","custom2":"1B71446","custom2_ssid":"100490070984242874","custom3_ssid":"459913666349112767","custom3":"ADM","custom3_description":"WsType","custom4_ssid":"","custom4":"%WORKSPACE_VALUE%","custom5_ssid":"","custom5":"%WORKSPACE_VALUE%"},"view_type":"document","workspace_name":"sf_test","workspace_id":"Active!2615","wstype":"folder"}';
        IManageWFolder folderTemplate_child_1_1_1_data = (IManageWFolder) JSON.deserialize(
            folderTemplate_child_1_1_1_json,
            IManageWFolder.class
        );

        // createTab ws_tab_1_3
        String createTabEndpoint_folderTemplate_child_1_1_1 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/workspaces/{2}/tabs',
            new List<Object>{ customerId, library, ws_id }
        );
        String ws_tab_1_3_json = '{"database":"Active","default_security":"inherit","edit_date":"2023-10-26T23:05:25.086Z","effective_security":"full_access","folder_type":"tab","has_subfolders":false,"id":"Active!2712","is_container_saved_search":false,"is_content_saved_search":false,"is_external_as_normal":false,"name":"sf_test_tab_1_3","owner":"TESTUSER","owner_description":"testuser","parent_id":"Active!2711","subtype":"Q","view_type":"document","workspace_id":"Active!2711","workspace_name":"' + workspaceName + '","wstype":"folder"}';
        IManageWFolder ws_tab_1_3_data = (IManageWFolder) JSON.deserialize(
            folderTemplate_child_1_1_1_json,
            IManageWFolder.class
        );

        // patchNameValuePair ws_tab_1_3
        String patchNameValuePairEndpoint_ws_tab_1_3 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}',
            new List<Object>{ customerId, library, ws_tab_1_3_id }
        );
        String ws_tab_1_3_pnvp_json = '{"database":"ACTIVE","default_security":"inherit","edit_date":"2023-10-26T23:05:25.326Z","effective_security":"full_access","folder_type":"tab","has_documents":false,"has_subfolders":false,"id":"Active!2712","inherited_default_security":"public","is_container_saved_search":false,"is_content_saved_search":false,"is_external":false,"is_external_as_normal":false,"name":"sf_test_tab_1_3","owner":"TESTUSER","owner_description":"testuser","parent_id":"Active!2711","view_type":"document","workspace_id":"Active!2711","workspace_name":"' + workspaceName + '","wstype":"folder"}';
        Object ws_tab_1_3_pnvp_data = JSON.deserializeUntyped(ws_tab_1_3_pnvp_json);

        // patchNameValuePair ws_child_1_1
        String patchNameValuePairEndpoint_ws_child_1_1 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}',
            new List<Object>{ customerId, library, ws_child_1_1_id }
        );
        String ws_child_1_1_pnvp_json = '{"database":"ACTIVE","default_security":"inherit","edit_date":"2023-10-26T23:05:26.115Z","effective_security":"full_access","folder_type":"regular","has_documents":false,"has_subfolders":false,"id":"Active!2713","inherited_default_security":"public","is_container_saved_search":false,"is_content_saved_search":false,"is_external":false,"is_external_as_normal":false,"name":"sf_test_child_1_1","owner":"TESTUSER","owner_description":"testuser","parent_id":"Active!2711","profile":{"custom1_description":"Salesforce test","custom1_ssid":"100490070984242850","custom1":"1","custom2":"1B71446","custom2_description":"Salesforce test","custom2_ssid":"100490070984242874"},"view_type":"document","workspace_id":"Active!2711","workspace_name":"' + workspaceName + '","wstype":"folder"}';
        Object ws_child_1_1_pnvp_data = JSON.deserializeUntyped(
            ws_child_1_1_pnvp_json
        );

        // patchNameValuePair ws_child_1_2
        String patchNameValuePairEndpoint_ws_child_1_2 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}',
            new List<Object>{ customerId, library, ws_child_1_2_id }
        );
        String ws_child_1_2_pnvp_json = '{"database":"ACTIVE","default_security":"inherit","edit_date":"2023-10-26T23:05:26.852Z","effective_security":"full_access","folder_type":"regular","has_documents":false,"has_subfolders":false,"id":"Active!2714","inherited_default_security":"public","is_container_saved_search":false,"is_content_saved_search":false,"is_external":false,"is_external_as_normal":false,"name":" sf_test_child_1_2","owner":"TESTUSER","owner_description":"testuser","parent_id":"Active!2711","profile":{"custom1":"1","custom1_description":"Salesforce test","custom1_ssid":"100490070984242850","custom2_ssid":"100490070984242874","custom2":"1B71446","custom2_description":"Salesforce test"},"view_type":"document","workspace_id":"Active!2711","workspace_name":"' + workspaceName + '","wstype":"folder"}';
        Object ws_child_1_2_pnvp_data = JSON.deserializeUntyped(
            ws_child_1_2_pnvp_json
        );

        // patchNameValuePair ws_child_1_1_1
        String patchNameValuePairEndpoint_ws_child_1_1_1 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}',
            new List<Object>{ customerId, library, ws_child_1_1_1_id }
        );
        String ws_child_1_1_1_pnvp_json = '{"database":"ACTIVE","default_security":"inherit","edit_date":"2023-10-26T23:05:28.26Z","effective_security":"full_access","folder_type":"regular","has_documents":false,"has_subfolders":false,"id":"Active!2716","inherited_default_security":"public","is_container_saved_search":false,"is_content_saved_search":false,"is_external":false,"is_external_as_normal":false,"name":"sf_test_child_1_1_1","owner_description":"testuser","owner":"TESTUSER","parent_id":"Active!2713","profile":{"custom1_ssid":"100490070984242850","custom1":"1","custom1_description":"Salesforce test","custom2":"1B71446","custom2_ssid":"100490070984242874","custom2_description":"Salesforce test"},"view_type":"document","workspace_id":"Active!2711","workspace_name":"' + workspaceName + '","wstype":"folder"}';
        Object ws_child_1_1_1_pnvp_data = JSON.deserializeUntyped(
            ws_child_1_1_1_pnvp_json
        );

        // createFolder ws_child_1_1 in ws_id
        String createFolderEndpoint_ws_child_1_1 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/workspaces/{2}/folders',
            new List<Object>{ customerId, library, ws_id }
        );
        String ws_child_1_1_json = '{"database":"Active","default_security":"inherit","edit_date":"2023-10-26T23:05:25.904Z","effective_security":"full_access","folder_type":"regular","has_subfolders":false,"id":"Active!2713","is_container_saved_search":false,"is_content_saved_search":false,"is_external_as_normal":false,"name":"sf_test_child_1_1","owner":"TESTUSER","owner_description":"testuser","parent_id":"Active!2711","profile":{"class_property_name":"class_","custom1":"1","custom1_description":"Salesforce test","custom2":"1B71446","custom2_description":"Salesforce test"},"view_type":"document","workspace_id":"Active!2711","workspace_name":"' + workspaceName + '","wstype":"folder"}';
        IManageWFolder ws_child_1_1_data = (IManageWFolder) JSON.deserialize(
            ws_child_1_1_json,
            IManageWFolder.class
        );

        // createFolder ws_child_1_2 in ws_id
        String createFolderEndpoint_ws_child_1_2 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/workspaces/{2}/folders',
            new List<Object>{ customerId, library, ws_id }
        );
        String ws_child_1_2_json = '{"database":"Active","default_security":"inherit","edit_date":"2023-10-26T23:05:26.646Z","effective_security":"full_access","folder_type":"regular","has_subfolders":false,"id":"Active!2714","is_container_saved_search":false,"is_content_saved_search":false,"is_external_as_normal":false,"name":" sf_test_child_1_2","owner":"TESTUSER","owner_description":"testuser","parent_id":"Active!2711","profile":{"class_property_name":"class_","custom1":"1","custom1_description":"Salesforce test","custom2":"1B71446","custom2_description":"Salesforce test"},"view_type":"document","workspace_id":"Active!2711","workspace_name":"' + workspaceName + '","wstype":"folder"}';
        IManageWFolder ws_child_1_2_data = (IManageWFolder) JSON.deserialize(
            ws_child_1_2_json,
            IManageWFolder.class
        );

        // createFolder ws_child_1_1_1 in ws_child_1_1
        String createFolderEndpoint_ws_child_1_1_1 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}/subfolders',
            new List<Object>{ customerId, library, ws_child_1_1_id }
        );
        String ws_child_1_1_1_json = '{"database":"ACTIVE","default_security":"inherit","edit_date":"2023-10-26T23:05:28.069Z","folder_type":"regular","has_documents":false,"has_subfolders":false,"id":"Active!2716","inherited_default_security":"public","is_container_saved_search":false,"is_content_saved_search":false,"is_external":false,"is_external_as_normal":false,"name":"sf_test_child_1_1_1","owner":"TESTUSER","owner_description":"testuser","parent_id":"Active!2713","profile":{"custom1_description":"Salesforce test","custom1_ssid":"100490070984242850","custom1":"1","custom2_ssid":"100490070984242874","custom2":"1B71446","custom2_description":"Salesforce test"},"view_type":"document","workspace_id":"Active!2711","workspace_name":"' + workspaceName + '","wstype":"folder"}';
        IManageWFolder ws_child_1_1_1_data = (IManageWFolder) JSON.deserialize(
            ws_child_1_1_1_json,
            IManageWFolder.class
        );

        //createSearchFolder ws_search_1_3_1 in ws_tab_1_3
        String createSearchFolderEndpoint_ws_search_1_3_1 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}/search-folders',
            new List<Object>{ customerId, library, ws_tab_1_3_id }
        );
        String ws_search_1_3_1_json = '{"content_saved_search_id":"100490070986866651","database":"Active","default_security":"inherit","edit_date":"2023-10-26T23:05:27.446Z","effective_security":"full_access","folder_type":"search","has_subfolders":false,"id":"Active!2715","is_container_saved_search":false,"is_content_saved_search":true,"is_external_as_normal":false,"name":"sf_test_search_1_3_1","owner":"TESTUSER","owner_description":"testuser","parent_id":"Active!2712","searchprofile":{"databases":"Active","docnum":"1-5000","custom2":"1B71446","custom1":"1"},"subtype":"C","view_type":"document_search","workspace_id":"Active!2711","workspace_name":"' + workspaceName + '","wstype":"folder"}';
        IManageWFolder ws_search_1_3_1_data = (IManageWFolder) JSON.deserialize(
            ws_search_1_3_1_json,
            IManageWFolder.class
        );

        // getSearchFolderById folderTemplate_search_1_3_1
        String getSearchFolderByIdEndpoint_folderTemplate_search_1_3_1 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/search-folders/{2}',
            new List<Object>{ customerId, library, folderTemplate_search_1_3_1_id }
        );
        String folderTemplate_search_1_3_1_json = '{"content_saved_search_id":"100490070984294934","database":"Active","default_security":"inherit","edit_date":"2023-10-25T13:26:16.51Z","effective_security":"full_access","folder_type":"search","has_subfolders":false,"id":"Active!2634","inherited_default_security":"public","is_container_saved_search":false,"is_content_saved_search":true,"is_external_as_normal":false,"name":"sf_test_search_1_3_1","owner":"TESTUSER","owner_description":"testuser","parent_id":"Active!2633","profile":{"class_property_name":"class_"},"searchprofile":{"databases":"Active","docnum":"1-5000","custom2":"%WORKSPACE_VALUE%","custom1":"1"},"subtype":"C","view_type":"document_search","workspace_id":"Active!2615","workspace_name":"sf_test","wstype":"folder"}';
        IManageWFolder folderTemplate_search_1_3_1_data = (IManageWFolder) JSON.deserialize(
            folderTemplate_search_1_3_1_json,
            IManageWFolder.class
        );

        IManageApiResponseHelper respHelper = new IManageApiResponseHelper();
        Map<String, List<HttpResponse>> responses = new Map<String, List<HttpResponse>>{
            getFolderTemplateEndpoint => new List<HttpResponse>{
                respHelper.buildWorkspaceResponse(200, folderTemplate)
            },
            getWorkspaceEndpoint => new List<HttpResponse>{
                respHelper.buildWorkspaceResponse(200, workspace_get)
            },
            getWorkspaceFoldersEndpoint => new List<HttpResponse>{
                respHelper.buildFoldersResponse(200, wsFolders)
            },
            getFolderTemplateFoldersEndpoint => new List<HttpResponse>{
                respHelper.buildFoldersResponse(200, folderTemplateFolders)
            },
            createWorkspaceEndpoint => new List<HttpResponse>{
                respHelper.buildWorkspaceResponse(200, createdWs)
            },
            //iManageWrapper::getNameValuePair
            getNameValuePairEndpoint_folderTemplate_tab_1_3 => new List<HttpResponse>{
                respHelper.buildNameValuePairResponse(200, folderTemplate_tab_1_3_data_nvp)
            },
            getNameValuePairEndpoint_folderTemplate_child_1_1 => new List<HttpResponse>{
                respHelper.buildNameValuePairResponse(200, folderTemplate_child_1_1_data_nvp)
            },
            getNameValuePairEndpoint_folderTemplate_child_1_2 => new List<HttpResponse>{
                respHelper.buildNameValuePairResponse(200, folderTemplate_child_1_2_data_nvp)
            },
            getNameValuePairEndpoint_folderTemplate_search_1_3_1 => new List<HttpResponse>{
                respHelper.buildNameValuePairResponse(200, folderTemplate_search_1_3_1_data_nvp)
            },
            getNameValuePairEndpoint_folderTemplate_child_1_1_1 => new List<HttpResponse>{
                respHelper.buildNameValuePairResponse(200, folderTemplate_child_1_1_1_data_nvp)
            },
            // iManageWrapper::getFolderByIdgetFolderById
            getFolderByIdEndpoint_folderTemplate_tab_1_3 => new List<HttpResponse>{
                respHelper.buildWFolderResponse(200, folderTemplate_tab_1_3_data)
            },
            getFolderByIdEndpoint_folderTemplate_child_1_1 => new List<HttpResponse>{
                respHelper.buildWFolderResponse(200, folderTemplate_child_1_1_data)
            },
            getFolderByIdEndpoint_folderTemplate_child_1_2 => new List<HttpResponse>{
                respHelper.buildWFolderResponse(200, folderTemplate_child_1_2_data)
            },
            getFolderByIdEndpoint_folderTemplate_child_1_1_1 => new List<HttpResponse>{
                respHelper.buildWFolderResponse(200, folderTemplate_child_1_1_1_data)
            },
            //ManageWrapper::createTab
            createTabEndpoint_folderTemplate_child_1_1_1 => new List<HttpResponse>{
                respHelper.buildTabResponse(200, ws_tab_1_3_data)
            },
            //ManageWrapper::patchNameValuePair
            patchNameValuePairEndpoint_ws_tab_1_3 => new List<HttpResponse>{
                respHelper.buildPatchNameValuePairResponse(200, ws_tab_1_3_pnvp_data)
            },
            patchNameValuePairEndpoint_ws_child_1_1 => new List<HttpResponse>{
                respHelper.buildPatchNameValuePairResponse(200, ws_child_1_1_pnvp_data)
            },
            patchNameValuePairEndpoint_ws_child_1_2 => new List<HttpResponse>{
                respHelper.buildPatchNameValuePairResponse(200, ws_child_1_2_pnvp_data)
            },
            patchNameValuePairEndpoint_ws_child_1_1_1 => new List<HttpResponse>{
                respHelper.buildPatchNameValuePairResponse(200, ws_child_1_1_1_pnvp_data)
            },
            //ManageWrapper::createFolder
            createFolderEndpoint_ws_child_1_1 => new List<HttpResponse>{
                respHelper.buildWFolderResponse(200, ws_child_1_1_data)
            },
            createFolderEndpoint_ws_child_1_2 => new List<HttpResponse>{
                respHelper.buildWFolderResponse(200, ws_child_1_2_data)
            },
            createFolderEndpoint_ws_child_1_1_1 => new List<HttpResponse>{
                respHelper.buildWFolderResponse(200, ws_child_1_1_1_data)
            },
            //ManageWrapper::createSearchFolder
            createSearchFolderEndpoint_ws_search_1_3_1 => new List<HttpResponse>{
                respHelper.buildWFolderResponse(200, ws_search_1_3_1_data)
            },
            //ManageWrapper::getSearchFolderById
            getSearchFolderByIdEndpoint_folderTemplate_search_1_3_1 => new List<HttpResponse>{
                respHelper.buildWFolderResponse(200, folderTemplate_search_1_3_1_data)
            }
        };
        setupMockCallouts(customerId, library, responses);
        //--

        Test.startTest();
        Map<String, String> result = iManageWorkspacesHelper.createWorkspace(
            String.valueOf(customerId), // client alias
            matterId, // matter alias
            workspaceName,
            workspaceTemplate // "libraryId::templateId"
        );
        Test.stopTest();

        String resultId = result.get('id');
        String resultName = result.get('name');
        String resultDatabase = result.get('database');
        System.assert(resultId == ws_id, String.format('Wrong value = {0}, Expected = {1}', new List<Object> {resultId, ws_id}));
        System.assert(resultName == workspaceName, String.format('Wrong value = {0}, Expected = {1}', new List<Object> {resultName, workspaceName}));
        System.assert(resultDatabase == library, String.format('Wrong value = {0}, Expected = {1}', new List<Object> {resultDatabase, library}));
    }

    @isTest
    static void createWorkspaceOptionalFoldersTest() {
        // prepare data
        Integer customerId = 1;
        String library = 'Active';
        String matterId = '1B71446';
        String workspaceName = '1-1B71446_Test 1';
        //-- Folder template
        String folderTemplate_id = library + '!2840';

        // -- Created ws
        String ws_id = library + '!2872';
        String workspaceTemplate = library + '::' + folderTemplate_id;

        // mock callouts
        IManageApiResponseHelper respHelper = new IManageApiResponseHelper();

        // createWorkspaceApiCall
        String createWorkspaceEndpoint = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/workspaces',
            new List<Object>{ customerId, library }
        );
        String wsJson_create = '{"wstype":"workspace","version":1,"system_edit_date":"2023-10-29T12:10:34.163Z","retain_days":365,"iwl":"iwl:dms=cloudimanage.com&&lib=Active&&num=254941&&ver=1","is_hipaa":false,"document_number":254941,"custom2":"1B71446","custom2_ssid":"100490070984242874","custom2_description":"Salesforce test","custom1_ssid":"100490070984242850","custom1":"1","custom1_description":"Salesforce test","create_profile_date":"2023-10-29T12:10:34.163Z","owner_description":"testuser","owner":"TESTUSER","name":"1-1B71446_Test 1","last_user_description":"testuser","last_user":"TESTUSER","is_external_as_normal":false,"is_external":false,"is_declared":false,"id":"Active!2872","has_subfolders":false,"effective_security":"full_access","edit_date":"2023-10-29T12:10:34.163Z","description":"test template","default_security":"public","database":"ACTIVE","create_date":"2023-10-29T12:10:34.163Z"}';
        IManageWWorkspace createdWs = (IManageWWorkspace) JSON.deserialize(
            wsJson_create,
            IManageWWorkspace.class
        );
        HttpResponse createWorkspaceResponse = respHelper.buildWorkspaceResponse(200, createdWs);

        // folder template !2840
        String getFolderTemplateEndpoint = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/workspaces/{2}',
            new List<Object>{ customerId, library, folderTemplate_id }
        );
        String folderTemplateJson = '{"wstype":"workspace","version":1,"system_edit_date":"2023-10-28T16:40:50.467Z","retain_days":365,"iwl":"iwl:dms=cloudimanage.com&&lib=Active&&num=254932&&ver=1","is_hipaa":false,"document_number":254932,"create_profile_date":"2023-10-28T16:38:36.353Z","name":"sf_test_optional","last_user_description":"testuser","last_user":"TESTUSER","is_external_as_normal":false,"is_external":false,"is_declared":false,"id":"Active!2840","has_subfolders":true,"effective_security":"full_access","edit_date":"2023-10-28T16:40:50.467Z","description":"test template","default_security":"public","database":"ACTIVE","create_date":"2023-10-28T16:38:36.353Z"}';
        IManageWWorkspace folderTemplate = (IManageWWorkspace) JSON.deserialize(
            folderTemplateJson,
            IManageWWorkspace.class
        );
        HttpResponse getFolderTemplateResponse = respHelper.buildWorkspaceResponse(200, folderTemplate);

        // workspace !2872
        String getWorkspaceEndpoint = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/workspaces/{2}',
            new List<Object>{ customerId, library, ws_id }
        );
        String wsJson_get = '{"wstype":"workspace","version":1,"system_edit_date":"2023-10-29T12:10:34.163Z","retain_days":365,"iwl":"iwl:dms=cloudimanage.com&&lib=Active&&num=254941&&ver=1","is_hipaa":false,"document_number":254941,"custom2_description":"Salesforce test","custom2":"1B71446","custom2_ssid":"100490070984242874","custom1_ssid":"100490070984242850","custom1":"1","custom1_description":"Salesforce test","create_profile_date":"2023-10-29T12:10:34.163Z","owner_description":"testuser","owner":"TESTUSER","name":"1-1B71446_Test 1","last_user_description":"testuser","last_user":"TESTUSER","is_external_as_normal":false,"is_external":false,"is_declared":false,"id":"Active!2872","has_subfolders":false,"effective_security":"full_access","edit_date":"2023-10-29T12:10:34.163Z","description":"test template","default_security":"public","database":"ACTIVE","create_date":"2023-10-29T12:10:34.163Z"}';
        IManageWWorkspace workspace_get = (IManageWWorkspace) JSON.deserialize(
            wsJson_get,
            IManageWWorkspace.class
        );
        HttpResponse getWorkspaceResponse = respHelper.buildWorkspaceResponse(200, workspace_get);

        // callout:iManageCreds/work/api/v2/customers/337/libraries/Active/folders/Active!2841
        String getFolderByIdEndpoint_folderTemplate_2841 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}',
            new List<Object>{ customerId, library, 'Active!2841' }
        );
        String  folderTemplate_2841_json = '{"wstype":"folder","workspace_name":"sf_test_optional","workspace_id":"Active!2840","view_type":"document","profile":{},"parent_id":"Active!2840","owner_info":{"is_external":false,"allow_logon":true},"owner":"TESTUSER","owner_description":"testuser","name":"sf_tab_1","is_external_as_normal":false,"is_external":false,"is_content_saved_search":false,"is_container_saved_search":false,"inherited_default_security":"public","id":"Active!2841","has_subfolders":false,"has_documents":false,"folder_type":"tab","effective_security":"full_access","edit_date":"2023-10-28T16:39:22.255Z","default_security":"inherit","database":"ACTIVE"}';
        IManageWFolder folderTemplate_2841_data = (IManageWFolder) JSON.deserialize(
            folderTemplate_2841_json,
            IManageWFolder.class
        );
        HttpResponse getFolderByIdResponse_folderTemplate_2841 = respHelper.buildWFolderResponse(200, folderTemplate_2841_data);

        // callout:iManageCreds/work/api/v2/customers/337/libraries/Active/folders/Active!2842
        String getFolderByIdEndpoint_folderTemplate_2842 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}',
            new List<Object>{ customerId, library, 'Active!2842' }
        );
        String  folderTemplate_2842_json = '{"wstype":"folder","workspace_id":"Active!2840","workspace_name":"sf_test_optional","view_type":"document","profile":{},"parent_id":"Active!2840","owner_info":{"is_external":false,"allow_logon":true},"owner_description":"testuser","owner":"TESTUSER","name":"sf_folder_1","is_external_as_normal":false,"is_external":false,"is_content_saved_search":false,"is_container_saved_search":false,"inherited_default_security":"public","id":"Active!2842","has_subfolders":false,"has_documents":false,"folder_type":"regular","effective_security":"full_access","edit_date":"2023-10-28T16:39:41.678Z","default_security":"inherit","database":"ACTIVE"}';
        IManageWFolder folderTemplate_2842_data = (IManageWFolder) JSON.deserialize(
            folderTemplate_2842_json,
            IManageWFolder.class
        );
        HttpResponse getFolderByIdResponse_folderTemplate_2842 = respHelper.buildWFolderResponse(200, folderTemplate_2842_data);

        // callout:iManageCreds/work/api/v2/customers/337/libraries/Active/folders/Active!2841/name-value-pairs
        String getNvpEndpoint_2841 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}/name-value-pairs',
            new List<Object>{ customerId, library, 'Active!2841' }
        );
        String nvp_json_2841 = '{"IMCC_IsOptional":"true"}';
        Map<String, String> nvp_data_2841 = (Map<String, String>) JSON.deserialize(
            nvp_json_2841,
            Map<String, String>.class
        );
        HttpResponse getNvpResponse_2841 = respHelper.buildNameValuePairResponse(200, nvp_data_2841);

        // callout:iManageCreds/work/api/v2/customers/337/libraries/Active/folders/Active!2842/name-value-pairs
        String getNvpEndpoint_2842 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}/name-value-pairs',
            new List<Object>{ customerId, library, 'Active!2842' }
        );
        String nvp_json_2842 = '{"IMCC_IsOptional":"true"}';
        Map<String, String> nvp_data_2842 = (Map<String, String>) JSON.deserialize(
            nvp_json_2842,
            Map<String, String>.class
        );
        HttpResponse getNvpResponse_2842 = respHelper.buildNameValuePairResponse(200, nvp_data_2842);

        // callout:iManageCreds/work/api/v2/customers/337/libraries/Active/folders/Active!2843/name-value-pairs
        String getNvpEndpoint_2843 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}/name-value-pairs',
            new List<Object>{ customerId, library, 'Active!2843' }
        );
        String nvp_json_2843 = '{"IMCC_IsOptional":"true"}';
        Map<String, String> nvp_data_2843 = (Map<String, String>) JSON.deserialize(
            nvp_json_2843,
            Map<String, String>.class
        );
        HttpResponse getNvpResponse_2843 = respHelper.buildNameValuePairResponse(200, nvp_data_2843);

        // callout:iManageCreds/work/api/v2/customers/337/libraries/Active/folders?total=true&offset=0&limit=200&container_id=Active!2840
        String getFoldersEndpoint_2840 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders?total=true&offset=0&limit=200&container_id={2}',
            new List<Object>{ customerId, library, 'Active!2840' }
        );
        String getFoldersJson_2840 = '[{"wstype":"folder","workspace_name":"sf_test_optional","workspace_id":"Active!2840","view_type":"document","parent_id":"Active!2840","owner":"TESTUSER","owner_description":"testuser","name":"sf_search_folder","is_external_as_normal":false,"is_external":false,"is_content_saved_search":true,"is_container_saved_search":false,"inherited_default_security":"public","id":"Active!2843","has_subfolders":false,"has_documents":false,"folder_type":"search","edit_date":"2023-10-28T16:40:29.877Z","default_security":"inherit","database":"ACTIVE","content_saved_search_id":100490070990171717},{"wstype":"folder","workspace_name":"sf_test_optional","workspace_id":"Active!2840","view_type":"document","parent_id":"Active!2840","owner":"TESTUSER","owner_description":"testuser","name":"sf_folder_1","is_external_as_normal":false,"is_external":false,"is_content_saved_search":false,"is_container_saved_search":false,"inherited_default_security":"public","id":"Active!2842","has_subfolders":false,"has_documents":false,"folder_type":"regular","edit_date":"2023-10-28T16:39:41.678Z","default_security":"inherit","database":"ACTIVE"},{"wstype":"folder","workspace_name":"sf_test_optional","workspace_id":"Active!2840","view_type":"document","parent_id":"Active!2840","owner":"TESTUSER","owner_description":"testuser","name":"sf_tab_1","is_external_as_normal":false,"is_external":false,"is_content_saved_search":false,"is_container_saved_search":false,"inherited_default_security":"public","id":"Active!2841","has_subfolders":false,"has_documents":false,"folder_type":"tab","edit_date":"2023-10-28T16:39:22.255Z","default_security":"inherit","database":"ACTIVE"}]';
        List<IManageWFolder> getFoldersData_2840 = (List<IManageWFolder>) JSON.deserialize(
            getFoldersJson_2840,
            List<IManageWFolder>.class
        );

        HttpResponse getFoldersResponse_2840 = respHelper.buildFoldersResponse(200, getFoldersData_2840);

        // callout:iManageCreds/work/api/v2/customers/337/libraries/Active/folders?total=true&offset=0&limit=200&container_id=Active!2872
        String getFoldersEndpoint_2872 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders?total=true&offset=0&limit=200&container_id={2}',
            new List<Object>{ customerId, library, 'Active!2872' }
        );
        String getFoldersJson_2872 = '[]';
        List<IManageWFolder> getFoldersData_2872 = (List<IManageWFolder>) JSON.deserialize(
            getFoldersJson_2872,
            List<IManageWFolder>.class
        );

        HttpResponse getFoldersResponse_2872 = respHelper.buildFoldersResponse(200, getFoldersData_2872);

        // callout:iManageCreds/work/api/v2/customers/337/libraries/Active/search-folders/Active!2843
        String getSearchFolderByIdEndpoint_2843 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/search-folders/{2}',
            new List<Object>{ customerId, library, 'Active!2843' }
        );
        String folderTemplate_search_json_2843 = '{"wstype":"folder","workspace_name":"sf_test_optional","workspace_id":"Active!2840","view_type":"document_search","subtype":"C","searchprofile":{"docnum":"1-10","databases":"Active"},"profile":{"class_property_name":"klass"},"parent_id":"Active!2840","owner_description":"testuser","owner":"TESTUSER","name":"sf_search_folder","is_external_as_normal":false,"is_content_saved_search":true,"is_container_saved_search":false,"inherited_default_security":"public","id":"Active!2843","has_subfolders":false,"folder_type":"search","effective_security":"full_access","edit_date":"2023-10-28T16:40:29.877Z","default_security":"inherit","database":"Active","content_saved_search_id":"100490070990171717"}';
        IManageWFolder folderTemplate_search_data_2843 = (IManageWFolder) JSON.deserialize(
            folderTemplate_search_json_2843,
            IManageWFolder.class
        );
        HttpResponse getSearchFolderByIdResponse_2843 = respHelper.buildWFolderResponse(200, folderTemplate_search_data_2843);

        Map<String, List<HttpResponse>> responses = new Map<String, List<HttpResponse>>{
            createWorkspaceEndpoint => new List<HttpResponse>{
                createWorkspaceResponse
            },
            getFolderTemplateEndpoint => new List<HttpResponse>{
                getFolderTemplateResponse
            },
            getWorkspaceEndpoint => new List<HttpResponse>{
                getWorkspaceResponse
            },
            getFolderByIdEndpoint_folderTemplate_2841 => new List<HttpResponse>{
                getFolderByIdResponse_folderTemplate_2841
            },
            getFolderByIdEndpoint_folderTemplate_2842 => new List<HttpResponse>{
                getFolderByIdResponse_folderTemplate_2842
            },
            //
            getNvpEndpoint_2841 => new List<HttpResponse>{ getNvpResponse_2841 },
            getNvpEndpoint_2842 => new List<HttpResponse>{ getNvpResponse_2842 },
            getNvpEndpoint_2843 => new List<HttpResponse>{ getNvpResponse_2843 },
            getFoldersEndpoint_2840 => new List<HttpResponse>{ getFoldersResponse_2840 },
            getFoldersEndpoint_2872 => new List<HttpResponse>{ getFoldersResponse_2872 },
            getSearchFolderByIdEndpoint_2843 => new List<HttpResponse>{ getSearchFolderByIdResponse_2843 }
        };
        setupMockCallouts(customerId, library, responses);
        //--

        Test.startTest();
        Map<String, String> result = iManageWorkspacesHelper.createWorkspace(
            String.valueOf(customerId), // client alias
            matterId, // matter alias
            workspaceName,
            workspaceTemplate // "libraryId::templateId"
        );
        Test.stopTest();
        System.assert(true, 'test not passed');
    }

    @isTest
    static void createWorkspaceSecureFoldersTest() {
        // prepare data
        Integer customerId = 1;
        String library = 'Active';
        String matterId = '1B71446';
        String workspaceName = '1-1B71446_Test 1';
        //-- Folder template
        String folderTemplate_id = library + '!2844';

        // -- Created ws
        String workspaceTemplate = library + '::' + folderTemplate_id;

        //-- mock callouts
        IManageApiResponseHelper respHelper = new IManageApiResponseHelper();

        // callout:iManageCreds/work/api/v2/customers/337/libraries/Active/workspaces
        String createWorkspaceEndpoint = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/workspaces',
            new List<Object>{ customerId, library }
        );
        String wsJson_create = '{"wstype":"workspace","version":1,"system_edit_date":"2023-10-29T12:12:36.29Z","retain_days":365,"iwl":"iwl:dms=cloudimanage.com&&lib=Active&&num=254942&&ver=1","is_hipaa":false,"document_number":254942,"custom2_ssid":"100490070984242874","custom2_description":"Salesforce test","custom2":"1B71446","custom1":"1","custom1_ssid":"100490070984242850","custom1_description":"Salesforce test","create_profile_date":"2023-10-29T12:12:36.29Z","owner":"TESTUSER","owner_description":"testuser","name":"1-1B71446_Test 1","last_user_description":"testuser","last_user":"TESTUSER","is_external_as_normal":false,"is_external":false,"is_declared":false,"id":"Active!2873","has_subfolders":false,"effective_security":"full_access","edit_date":"2023-10-29T12:12:36.29Z","description":"test template","default_security":"public","database":"ACTIVE","create_date":"2023-10-29T12:12:36.29Z"}';
        IManageWWorkspace createdWs = (IManageWWorkspace) JSON.deserialize(
            wsJson_create,
            IManageWWorkspace.class
        );
        HttpResponse createWorkspaceResponse = respHelper.buildWorkspaceResponse(200, createdWs);

        // callout:iManageCreds/work/api/v2/customers/337/libraries/Active/workspaces/Active!2844
        String getWorkspaceEndpoint_2844 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/workspaces/{2}',
            new List<Object>{ customerId, library, 'Active!2844' }
        );
        String workspace_json_2844 = '{"wstype":"workspace","version":1,"system_edit_date":"2023-10-28T16:42:00.002Z","retain_days":365,"iwl":"iwl:dms=cloudimanage.com&&lib=Active&&num=254933&&ver=1","is_hipaa":false,"document_number":254933,"create_profile_date":"2023-10-28T16:41:19.33Z","name":"sf_test_security","last_user_description":"testuser","last_user":"TESTUSER","is_external_as_normal":false,"is_external":false,"is_declared":false,"id":"Active!2844","has_subfolders":true,"effective_security":"full_access","edit_date":"2023-10-28T16:42:00.002Z","description":"test template","default_security":"public","database":"ACTIVE","create_date":"2023-10-28T16:41:19.33Z"}';
        IManageWWorkspace workspace_data_2844 = (IManageWWorkspace) JSON.deserialize(
            workspace_json_2844,
            IManageWWorkspace.class
        );
        HttpResponse getWorkspaceResponse_2844 = respHelper.buildWorkspaceResponse(200, workspace_data_2844);

        // callout:iManageCreds/work/api/v2/customers/337/libraries/Active/workspaces/Active!2873
        String getWorkspaceEndpoint_2873 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/workspaces/{2}',
            new List<Object>{ customerId, library, 'Active!2873' }
        );
        String workspace_json_2873 = '{"wstype":"workspace","version":1,"system_edit_date":"2023-10-29T12:12:36.29Z","retain_days":365,"iwl":"iwl:dms=cloudimanage.com&&lib=Active&&num=254942&&ver=1","is_hipaa":false,"document_number":254942,"custom2_description":"Salesforce test","custom2_ssid":"100490070984242874","custom2":"1B71446","custom1_description":"Salesforce test","custom1_ssid":"100490070984242850","custom1":"1","create_profile_date":"2023-10-29T12:12:36.29Z","owner_description":"testuser","owner":"TESTUSER","name":"1-1B71446_Test 1","last_user_description":"testuser","last_user":"TESTUSER","is_external_as_normal":false,"is_external":false,"is_declared":false,"id":"Active!2873","has_subfolders":false,"effective_security":"full_access","edit_date":"2023-10-29T12:12:36.29Z","description":"test template","default_security":"public","database":"ACTIVE","create_date":"2023-10-29T12:12:36.29Z"}';
        IManageWWorkspace workspace_data_2873 = (IManageWWorkspace) JSON.deserialize(
            workspace_json_2873,
            IManageWWorkspace.class
        );
        HttpResponse getWorkspaceResponse_2873 = respHelper.buildWorkspaceResponse(200, workspace_data_2873);

        // callout:iManageCreds/work/api/v2/customers/337/libraries/Active/folders/Active!2845
        String getFolderByIdEndpoint_folderTemplate_2845 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}',
            new List<Object>{ customerId, library, 'Active!2845' }
        );
        String  folderTemplate_2845_json = '{"wstype":"folder","workspace_id":"Active!2844","workspace_name":"sf_test_security","view_type":"document","profile":{},"parent_id":"Active!2844","owner_info":{"is_external":false,"allow_logon":true},"owner_description":"testuser","owner":"TESTUSER","name":"sf_tab","is_external_as_normal":false,"is_external":false,"is_content_saved_search":false,"is_container_saved_search":false,"inherited_default_security":"public","id":"Active!2845","has_subfolders":true,"has_documents":false,"folder_type":"tab","effective_security":"full_access","edit_date":"2023-10-28T16:43:10.751Z","description":"public secirity","default_security":"public","database":"ACTIVE"}';
        IManageWFolder folderTemplate_2845_data = (IManageWFolder) JSON.deserialize(
            folderTemplate_2845_json,
            IManageWFolder.class
        );
        HttpResponse getFolderByIdResponse_folderTemplate_2845 = respHelper.buildWFolderResponse(200, folderTemplate_2845_data);

        // callout:iManageCreds/work/api/v2/customers/337/libraries/Active/folders/Active!2846
        String getFolderByIdEndpoint_folderTemplate_2846 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}',
            new List<Object>{ customerId, library, 'Active!2846' }
        );
        String  folderTemplate_2846_json = '{"wstype":"folder","workspace_name":"sf_test_security","workspace_id":"Active!2844","view_type":"email","profile":{},"parent_id":"Active!2845","owner_info":{"is_external":false,"allow_logon":true},"owner_description":"testuser","owner":"TESTUSER","name":"sf_folder_1_1","is_external_as_normal":false,"is_external":false,"is_content_saved_search":false,"is_container_saved_search":false,"inherited_default_security":"private","id":"Active!2846","has_subfolders":false,"has_documents":false,"folder_type":"regular","email":"a12fb06d-23e7-838d-163d-a52060506468.Active@mail.cloudimanage.com","effective_security":"full_access","edit_date":"2023-10-28T16:45:00.309Z","description":"private security","default_security":"private","database":"ACTIVE","project_custom3":"droth@gdsi.com"}';
        IManageWFolder folderTemplate_2846_data = (IManageWFolder) JSON.deserialize(
            folderTemplate_2846_json,
            IManageWFolder.class
        );
        HttpResponse getFolderByIdResponse_folderTemplate_2846 = respHelper.buildWFolderResponse(200, folderTemplate_2846_data);

        // callout:iManageCreds/work/api/v2/customers/337/libraries/Active/folders/Active!2874
        String getFolderByIdEndpoint_folderTemplate_2874 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}',
            new List<Object>{ customerId, library, 'Active!2874' }
        );
        String  folderTemplate_2874_json = '{"wstype":"folder","workspace_name":"1-1B71446_Test 1","workspace_id":"Active!2873","view_type":"document","parent_id":"Active!2873","owner":"TESTUSER","owner_description":"testuser","name":"sf_tab","is_external_as_normal":false,"is_external":false,"is_content_saved_search":false,"is_container_saved_search":false,"inherited_default_security":"public","id":"Active!2874","has_subfolders":false,"has_documents":false,"folder_type":"tab","effective_security":"full_access","edit_date":"2023-10-29T12:12:37.569Z","description":"public secirity","default_security":"public","database":"ACTIVE"}';
        IManageWFolder folderTemplate_2874_data = (IManageWFolder) JSON.deserialize(
            folderTemplate_2874_json,
            IManageWFolder.class
        );
        HttpResponse getFolderByIdResponse_folderTemplate_2874 = respHelper.buildWFolderResponse(200, folderTemplate_2874_data);

        // callout:iManageCreds/work/api/v2/customers/337/libraries/Active/folders/Active!2875
        String getFolderByIdEndpoint_folderTemplate_2875 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}',
            new List<Object>{ customerId, library, 'Active!2875' }
        );
        // # 1
        String folderTemplate_2875_json_1 = '{"wstype":"folder","workspace_id":"Active!2873","workspace_name":"1-1B71446_Test 1","view_type":"document","parent_id":"Active!2874","owner_description":"testuser","owner":"TESTUSER","name":"sf_folder_1_1","is_external_as_normal":false,"is_external":false,"is_content_saved_search":false,"is_container_saved_search":false,"inherited_default_security":"private","id":"Active!2875","has_subfolders":false,"has_documents":false,"folder_type":"regular","effective_security":"full_access","edit_date":"2023-10-29T12:12:38.457Z","description":"private security","default_security":"private","database":"ACTIVE","project_custom3":"droth@gdsi.com"}';
        IManageWFolder folderTemplate_2875_data_1 = (IManageWFolder) JSON.deserialize(
            folderTemplate_2875_json_1,
            IManageWFolder.class
        );
        HttpResponse getFolderByIdResponse_folderTemplate_2875_1 = respHelper.buildWFolderResponse(200, folderTemplate_2875_data_1);
        // #2
        String folderTemplate_2875_json_2 = '{"wstype":"folder","workspace_name":"1-1B71446_Test 1","workspace_id":"Active!2873","view_type":"email","parent_id":"Active!2874","owner":"TESTUSER","owner_description":"testuser","name":"sf_folder_1_1","is_external_as_normal":false,"is_external":false,"is_content_saved_search":false,"is_container_saved_search":false,"inherited_default_security":"private","id":"Active!2875","has_subfolders":false,"has_documents":false,"folder_type":"regular","email":"sf_folder_1_1.2875.Active@mail.cloudimanage.com","effective_security":"full_access","edit_date":"2023-10-29T12:12:38.622Z","description":"private security","default_security":"private","database":"ACTIVE","project_custom3":"droth@gdsi.com"}';
        IManageWFolder folderTemplate_2875_data_2 = (IManageWFolder) JSON.deserialize(
            folderTemplate_2875_json_2,
            IManageWFolder.class
        );
        HttpResponse getFolderByIdResponse_folderTemplate_2875_2 = respHelper.buildWFolderResponse(200, folderTemplate_2875_data_2);

        // callout:iManageCreds/work/api/v2/customers/337/libraries/Active/folders/Active!2874/search-folders
        String createSearchFolderEndpoint_2874 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}/search-folders',
            new List<Object>{ customerId, library, 'Active!2874' }
        );
        String createSearchFolder_json = '{"wstype":"folder","workspace_name":"1-1B71446_Test 1","workspace_id":"Active!2873","view_type":"document_search","subtype":"C","searchprofile":{"custom25":true,"docnum":">7","databases":"Active"},"parent_id":"Active!2874","owner_description":"testuser","owner":"TESTUSER","name":"sf_search_folder_1_2","is_external_as_normal":false,"is_external":false,"is_content_saved_search":true,"is_container_saved_search":false,"id":"Active!2876","has_subfolders":false,"folder_type":"search","effective_security":"full_access","edit_date":"2023-10-29T12:12:39.772Z","default_security":"view","database":"Active","content_saved_search_id":"100490070990851152"}';
        IManageWFolder createSearchFolder_data = (IManageWFolder) JSON.deserialize(
            createSearchFolder_json,
            IManageWFolder.class
        );
        HttpResponse createSearchFolderResponse_2874 = respHelper.buildWFolderResponse(200, createSearchFolder_data);

        // callout:iManageCreds/work/api/v2/customers/337/libraries/Active/workspaces/Active!2873/tabs
        String createTabEndpoint_2873 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/workspaces/{2}/tabs',
            new List<Object>{ customerId, library, 'Active!2873' }
        );
        String createTab_json_2873 = '{"wstype":"folder","workspace_name":"1-1B71446_Test 1","workspace_id":"Active!2873","view_type":"document","subtype":"Q","parent_id":"Active!2873","owner_description":"testuser","owner":"TESTUSER","name":"sf_tab","is_external_as_normal":false,"is_external":false,"is_content_saved_search":false,"is_container_saved_search":false,"id":"Active!2874","has_subfolders":false,"folder_type":"tab","effective_security":"full_access","edit_date":"2023-10-29T12:12:37.348Z","description":"public secirity","default_security":"public","database":"Active"}';
        IManageWFolder createTab_data_2873 = (IManageWFolder) JSON.deserialize(
            createTab_json_2873,
            IManageWFolder.class
        );
        HttpResponse createTabResponse_2873 = respHelper.buildTabResponse(200, createTab_data_2873);

        // callout:iManageCreds/work/api/v2/customers/337/libraries/Active/folders/Active!2845
        String getNvpEndpoint_2845 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}/name-value-pairs',
            new List<Object>{ customerId, library, 'Active!2845' }
        );
        String nvp_json_2845 = '{"IMCC_IsOptional":"false"}';
        Map<String, String> nvp_data_2845 = (Map<String, String>) JSON.deserialize(
            nvp_json_2845,
            Map<String, String>.class
        );
        HttpResponse getNvpResponse_2845 = respHelper.buildNameValuePairResponse(200, nvp_data_2845);

        // callout:iManageCreds/work/api/v2/customers/337/libraries/Active/folders/Active!2846/name-value-pairs
        String getNvpEndpoint_2846 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}/name-value-pairs',
            new List<Object>{ customerId, library, 'Active!2846' }
        );
        String nvp_json_2846 = '{"IMCC_Email_Format":"droth@gdsi.com","IMCC_IsOptional":"false","icc_isrename":"0"}';
        Map<String, String> nvp_data_2846 = (Map<String, String>) JSON.deserialize(
            nvp_json_2846,
            Map<String, String>.class
        );
        HttpResponse getNvpResponse_2846 = respHelper.buildNameValuePairResponse(200, nvp_data_2846);

        // callout:iManageCreds/work/api/v2/customers/337/libraries/Active/folders/Active!2847/name-value-pairs
        String getNvpEndpoint_2847 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}/name-value-pairs',
            new List<Object>{ customerId, library, 'Active!2847' }
        );
        String nvp_json_2847 = '{"IMCC_IsOptional":"false","icc_isrename":"0"}';
        Map<String, String> nvp_data_2847 = (Map<String, String>) JSON.deserialize(
            nvp_json_2847,
            Map<String, String>.class
        );
        HttpResponse getNvpResponse_2847 = respHelper.buildNameValuePairResponse(200, nvp_data_2847);

        // callout:iManageCreds/work/api/v2/customers/337/libraries/Active/folders/Active!2846/security
        String patchSecurityEndpoint_2846 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}/security',
            new List<Object>{ customerId, library, 'Active!2846' }
        );
        String patchSecurity_json_2846 = '[{"type":"user","sid":"386600337554908195","name":"testuser","is_external":false,"id":"TESTUSER","allow_logon":true,"access_level":"full_access","access":3}]';
        List<IManageWSecurity> patchSecurity_data_2846 = (List<IManageWSecurity>) JSON.deserialize(
            patchSecurity_json_2846,
            List<IManageWSecurity>.class
        );
        HttpResponse patchSecurityResponse_2846 = respHelper.buildFolderSecurityResponseResponse(200, patchSecurity_data_2846, 'private');

        // callout:iManageCreds/work/api/v2/customers/337/libraries/Active/folders/Active!2847/security
        String patchSecurityEndpoint_2847 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}/security',
            new List<Object>{ customerId, library, 'Active!2847' }
        );
        String patchSecurity_json_2847 = '[{"type":"user","sid":"386600337554908195","name":"testuser","is_external":false,"id":"TESTUSER","allow_logon":true,"access_level":"full_access","access":3},{"type":"user","sid":"387999997838802834","name":"Test User2","is_external":false,"id":"TESTUSER2","allow_logon":true,"access_level":"read","access":1}]';
        List<IManageWSecurity> patchSecurity_data_2847 = (List<IManageWSecurity>) JSON.deserialize(
            patchSecurity_json_2847,
            List<IManageWSecurity>.class
        );
        HttpResponse patchSecurityResponse_2847 = respHelper.buildFolderSecurityResponseResponse(200, patchSecurity_data_2847, 'view');

        // callout:iManageCreds/work/api/v2/customers/337/libraries/Active/folders/Active!2875/security
        String patchSecurityEndpoint_2875 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}/security',
            new List<Object>{ customerId, library, 'Active!2875' }
        );
        String patchSecurity_json_2875 = '[{"type":"user","sid":"386600337554908195","name":"testuser","is_external":false,"id":"TESTUSER","allow_logon":true,"access_level":"full_access","access":3}]';
        List<IManageWSecurity> patchSecurity_data_2875 = (List<IManageWSecurity>) JSON.deserialize(
            patchSecurity_json_2875,
            List<IManageWSecurity>.class
        );
        HttpResponse patchSecurityResponse_2875 = respHelper.buildFolderSecurityResponseResponse(200, patchSecurity_data_2875, 'private');

        // callout:iManageCreds/work/api/v2/customers/337/libraries/Active/folders/Active!2876/security
        String patchSecurityEndpoint_2876 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders/{2}/security',
            new List<Object>{ customerId, library, 'Active!2876' }
        );
        String patchSecurity_json_2876 = '[{"type":"user","sid":"386600337554908195","name":"testuser","is_external":false,"id":"TESTUSER","allow_logon":true,"access_level":"full_access","access":3},{"type":"user","sid":"387999997838802834","name":"Test User2","is_external":false,"id":"TESTUSER2","allow_logon":true,"access_level":"read","access":1}]';
        List<IManageWSecurity> patchSecurity_data_2876 = (List<IManageWSecurity>) JSON.deserialize(
            patchSecurity_json_2876,
            List<IManageWSecurity>.class
        );
        HttpResponse patchSecurityResponse_2876 = respHelper.buildFolderSecurityResponseResponse(200, patchSecurity_data_2876, 'view');

        // callout:iManageCreds/work/api/v2/customers/337/libraries/Active/tabs/Active!2845/security
        String patchSecurityTabEndpoint_2845 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/tabs/{2}/security',
            new List<Object>{ customerId, library, 'Active!2845' }
        );
        String patchSecurityTab_json_2845 = '[]';
        List<IManageWSecurity> patchSecurityTab_data_2845 = (List<IManageWSecurity>) JSON.deserialize(
            patchSecurityTab_json_2845,
            List<IManageWSecurity>.class
        );
        HttpResponse patchSecurityTabRequest_2845 = respHelper.buildFolderSecurityResponseResponse(200, patchSecurityTab_data_2845, 'public');

        // callout:iManageCreds/work/api/v2/customers/337/libraries/Active/search-folders/Active!2847
        String getSearchFolderByIdEndpoint_2847 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/search-folders/{2}',
            new List<Object>{ customerId, library, 'Active!2847' }
        );
        String folderTemplate_search_json_2847 = '{"wstype":"folder","workspace_name":"sf_test_security","workspace_id":"Active!2844","view_type":"document_search","subtype":"C","searchprofile":{"custom25":true,"docnum":">7","databases":"Active"},"profile":{"class_property_name":"klass"},"parent_id":"Active!2845","owner_description":"2873","owner":"TESTUSER","name":"sf_search_folder_1_2","is_external_as_normal":false,"is_external":false,"is_content_saved_search":true,"is_container_saved_search":false,"id":"Active!2847","has_subfolders":false,"folder_type":"search","effective_security":"full_access","edit_date":"2023-10-28T16:46:55.21Z","description":"security view","default_security":"view","database":"Active","content_saved_search_id":"100490070990172283"}';
        IManageWFolder folderTemplate_search_data_2847 = (IManageWFolder) JSON.deserialize(
            folderTemplate_search_json_2847,
            IManageWFolder.class
        );
        HttpResponse getSearchFolderByIdResponse_2847 = respHelper.buildWFolderResponse(200, folderTemplate_search_data_2847);

        // callout:iManageCreds/work/api/v2/customers/337/libraries/Active/tabs/Active!2874/folders
        String createFolderEndpoint_2874 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/tabs/{2}/folders',
            new List<Object>{ customerId, library, 'Active!2874' }
        );
        String createFolder_json_2874 = '{"wstype":"folder","workspace_name":"1-1B71446_Test 1","workspace_id":"Active!2873","view_type":"document","parent_id":"Active!2874","owner":"TESTUSER","owner_description":"testuser","name":"sf_folder_1_1","is_external_as_normal":false,"is_external":false,"is_content_saved_search":false,"is_container_saved_search":false,"inherited_default_security":"private","id":"Active!2875","has_subfolders":false,"has_documents":false,"folder_type":"regular","edit_date":"2023-10-29T12:12:38.278Z","description":"private security","default_security":"private","database":"ACTIVE","project_custom3":"droth@gdsi.com"}';
        IManageWFolder createFolder_data_2874 = (IManageWFolder) JSON.deserialize(
            createFolder_json_2874,
            IManageWFolder.class
        );
        HttpResponse createFolderResponse_2874 = respHelper.buildWFolderResponse(200, createFolder_data_2874);

        // callout:iManageCreds/work/api/v2/customers/337/libraries/Active/folders?total=true&offset=0&limit=200&container_id=Active!2844
        String getFoldersEndpoint_2844 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders?total=true&offset=0&limit=200&container_id={2}',
            new List<Object>{ customerId, library, 'Active!2844' }
        );
        String getFoldersJson_2844 = '[{"wstype":"folder","workspace_name":"sf_test_security","workspace_id":"Active!2844","view_type":"document","parent_id":"Active!2845","owner":"TESTUSER","owner_description":"testuser","name":"sf_search_folder_1_2","is_external_as_normal":false,"is_external":false,"is_content_saved_search":true,"is_container_saved_search":false,"inherited_default_security":"view","id":"Active!2847","has_subfolders":false,"has_documents":false,"folder_type":"search","edit_date":"2023-10-28T16:46:55.21Z","description":"security view","default_security":"view","database":"ACTIVE","content_saved_search_id":100490070990172283},{"wstype":"folder","workspace_name":"sf_test_security","workspace_id":"Active!2844","view_type":"email","parent_id":"Active!2845","owner":"TESTUSER","owner_description":"testuser","name":"sf_folder_1_1","is_external_as_normal":false,"is_external":false,"is_content_saved_search":false,"is_container_saved_search":false,"inherited_default_security":"private","id":"Active!2846","has_subfolders":false,"has_documents":false,"folder_type":"regular","email":"a12fb06d-23e7-838d-163d-a52060506468.Active@","edit_date":"2023-10-28T16:45:00.309Z","description":"private security","default_security":"private","database":"ACTIVE","project_custom3":"droth@gdsi.com"},{"wstype":"folder","workspace_name":"sf_test_security","workspace_id":"Active!2844","view_type":"document","parent_id":"Active!2844","owner":"TESTUSER","owner_description":"testuser","name":"sf_tab","is_external_as_normal":false,"is_external":false,"is_content_saved_search":false,"is_container_saved_search":false,"inherited_default_security":"public","id":"Active!2845","has_subfolders":true,"has_documents":false,"folder_type":"tab","edit_date":"2023-10-28T16:43:10.751Z","description":"public secirity","default_security":"public","database":"ACTIVE"}]';
        List<IManageWFolder> getFoldersData_2844 = (List<IManageWFolder>) JSON.deserialize(
            getFoldersJson_2844,
            List<IManageWFolder>.class
        );
        HttpResponse getFoldersResponse_2844 = respHelper.buildFoldersResponse(200, getFoldersData_2844);

        // callout:iManageCreds/work/api/v2/customers/337/libraries/Active/folders?total=true&offset=0&limit=200&container_id=Active!2873
        String getFoldersEndpoint_2873 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/folders?total=true&offset=0&limit=200&container_id={2}',
            new List<Object>{ customerId, library, 'Active!2873' }
        );
        String getFoldersJson_2873 = '[]';
        List<IManageWFolder> getFoldersData_2873 = (List<IManageWFolder>) JSON.deserialize(
            getFoldersJson_2873,
            List<IManageWFolder>.class
        );
        HttpResponse getFoldersResponse_2873 = respHelper.buildFoldersResponse(200, getFoldersData_2873);


        Map<String, List<HttpResponse>> responses = new Map<String, List<HttpResponse>>{
            createWorkspaceEndpoint => new List<HttpResponse>{ createWorkspaceResponse },
            getWorkspaceEndpoint_2844 => new List<HttpResponse>{ getWorkspaceResponse_2844 },
            getWorkspaceEndpoint_2873 => new List<HttpResponse>{ getWorkspaceResponse_2873 },
            getFolderByIdEndpoint_folderTemplate_2845 => new List<HttpResponse>{ getFolderByIdResponse_folderTemplate_2845 },
            getFolderByIdEndpoint_folderTemplate_2846 => new List<HttpResponse>{ getFolderByIdResponse_folderTemplate_2846 },
            getFolderByIdEndpoint_folderTemplate_2874 => new List<HttpResponse>{ getFolderByIdResponse_folderTemplate_2874 },
            getFolderByIdEndpoint_folderTemplate_2875 => new List<HttpResponse>{
                getFolderByIdResponse_folderTemplate_2875_1,
                getFolderByIdResponse_folderTemplate_2875_2
            },
            createSearchFolderEndpoint_2874 => new List<HttpResponse>{ createSearchFolderResponse_2874 },
            createTabEndpoint_2873 => new List<HttpResponse>{ createTabResponse_2873 },
            getNvpEndpoint_2845 => new List<HttpResponse>{ getNvpResponse_2845 },
            getNvpEndpoint_2846 => new List<HttpResponse>{ getNvpResponse_2846 },
            getNvpEndpoint_2847 => new List<HttpResponse>{ getNvpResponse_2847 },
            patchSecurityEndpoint_2846 => new List<HttpResponse>{ patchSecurityResponse_2846 },
            patchSecurityEndpoint_2847 => new List<HttpResponse>{ patchSecurityResponse_2847 },
            patchSecurityEndpoint_2875 => new List<HttpResponse>{ patchSecurityResponse_2875 },
            patchSecurityEndpoint_2876 => new List<HttpResponse>{ patchSecurityResponse_2876 },
            patchSecurityTabEndpoint_2845 => new List<HttpResponse>{ patchSecurityTabRequest_2845 },
            getSearchFolderByIdEndpoint_2847 => new List<HttpResponse>{ getSearchFolderByIdResponse_2847 },
            createFolderEndpoint_2874 => new List<HttpResponse>{ createFolderResponse_2874 },
            getFoldersEndpoint_2844 => new List<HttpResponse>{ getFoldersResponse_2844 },
            getFoldersEndpoint_2873 => new List<HttpResponse>{ getFoldersResponse_2873 }
        };
        setupMockCallouts(customerId, library, responses);
        //--

        Test.startTest();
        Map<String, String> result = iManageWorkspacesHelper.createWorkspace(
            String.valueOf(customerId), // client alias
            matterId, // matter alias
            workspaceName,
            workspaceTemplate // "libraryId::templateId"
        );
        Test.stopTest();
        System.assert(true, 'test not passed');
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
    }

    class IManageApiResponseHelper {
        public HttpResponse buildGetWorkspaceResponse(Integer statusCode, IManageWWorkspace ws){
            iManageWrapper.iManageWorkspaceResponse body = new iManageWrapper.iManageWorkspaceResponse();
            body.data = ws;
            return buildResponse(statusCode, body, 'buildGetWorkspaceResponse');
        }

        public HttpResponse buildSearchWorkspaceResponse(Integer statusCode, List<iManageWrapper.iManageWorkspace> wss){
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

        public HttpResponse buildFolderSecurityResponseResponse(Integer statusCode, List<IManageWSecurity> data, String default_security){
            iManageWrapper.iManageFolderSecurityResponse body = new iManageWrapper.iManageFolderSecurityResponse();
            body.data = data;
            body.default_security = default_security;
            return buildResponse(statusCode, body, 'buildFolderSecurityResponseResponse');
        }

        public HttpResponse buildNameValuePairResponse(Integer statusCode, Map<String, String> data){
            iManageWrapper.iManageNameValuePairResponse body = new iManageWrapper.iManageNameValuePairResponse();
            body.data = data;
            return buildResponse(statusCode, body, 'buildNameValuePairResponse');
        }

        public HttpResponse buildPatchNameValuePairResponse(Integer statusCode, Object data){
            return buildResponse(statusCode, data, 'buildPatchNameValuePairResponse');
        }

        private HttpResponse buildResponse(Integer statusCode, Object body, String methodName){
            HttpResponse resp = new HttpResponse();
            resp.setStatusCode(statusCode);
            if (body != null) {
                String jsonBody = JSON.serialize(body);
                System.debug('iManageWorkspacesHelperTests.IManageApiResponseHelper::' + methodName + '. body = ' + jsonBody);
                resp.setBody(jsonBody);
            }
            return resp;
        }
    }
}
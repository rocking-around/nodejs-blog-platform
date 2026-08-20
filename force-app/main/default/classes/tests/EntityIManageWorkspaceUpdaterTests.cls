@isTest
private class EntityIManageWorkspaceUpdaterTests {

    @isTest
    static void updateIManageWorkspaces404Test() {
        Integer customerId = 1;
        String library = 'ACTIVE';
        String wsNamePattern = '{CLIENTCODE} - {CLIENTNAME} : {MATTERCODE} - {MATTERNAME}';
        String folderTemplate = library + '::ACTIVE!3333';
        String wsId = 'ACTIVE!7777';
        String wsName = 'test';
        String name = 'Test Opportunity';
        // prepare data
        // ins settings
        iManageSettings__c imSettings = new iManageSettings__c(
            Client_Id__c = 'val1',
            ClientField__c = 'custom1',
            MatterField__c = 'custom2',
            Url__c = 'val4',
            Customer_Id__c = 'val5',
            iManage_Default_Folder_Id__c = 'val5',
            Enable_CSV_Export__c = true,
            Mapping_EntityType__c = 'Opportunity',
            Mapping_EntityMatterIdObjectField__c = 'Opportunity',
            Mapping_MatterIdField__c = 'Id',
            Mapping_MatterNameField__c = 'Name',
            Mapping_EntityClientIdObjectField__c = 'Opportunity',
            Mapping_ClientIdField__c = 'Id',
            Mapping_ClientNameField__c = 'Name',
            iManage_Create_Ws_Enabled__c = true,
            iManage_Ws_Auto_Create__c = false,
            iManage_Ws_Folder_Template_Id__c = folderTemplate,
            iManage_Ws_Name_Pattern__c = wsNamePattern,
            iManage_Libraries__c = library
        );
        upsert imSettings;

        // ins Entity
        Opportunity opp = new Opportunity();
        opp.Name = name;
        opp.Closedate = System.today();
        opp.StageName = 'Prospecting';
        insert opp;

        // ins IManage_WS_to_Entity_Mapping__c
        IManage_WS_to_Entity_Mapping__c wsMapping = new IManage_WS_to_Entity_Mapping__c(
            Auto_created__c = false,
            EntityId__c = opp.Id,
            iManage_Workspace_Created_On__c = '2023-10-25T22:21:47.494Z',
            iManage_WS_Id__c = wsId,
            iManage_WS_Name__c = wsName,
            Source__c = 'SF',
            iManage_Library__c = 'ACTIVE'
        );
        insert wsMapping;

        // -- mock callouts
        TestIManageApiResponseHelper respHelper = new TestIManageApiResponseHelper();
        // callout:iManageCreds/work/api/v2/customers/1/libraries/ACTIVE/workspaces/ACTIVE!7777
        String getWsEndpoint_7777 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/workspaces/{2}',
            new List<Object>{ customerId, library, 'ACTIVE!7777' }
        );

        HttpResponse getWs_7777_resp = respHelper.build404Response();

        Map<String, List<HttpResponse>> responses = new Map<String, List<HttpResponse>>{
            getWsEndpoint_7777 => new List<HttpResponse>{ getWs_7777_resp }
        };
        setupMockCallouts(customerId, library, responses);

        Test.startTest();
        Map<String, String> workspaceParameters = EntityIManageWorkspaceUpdater.getWorkspaceParameters(
            wsMapping,
            wsNamePattern
        );
        Test.stopTest();
        System.assertEquals(null, workspaceParameters);
    }

    @isTest
    static void updateIManageWorkspacesTest() {
        Integer customerId = 1;
        String library = 'ACTIVE';
        String wsNamePattern = '{CLIENTCODE} - {CLIENTNAME} : {MATTERCODE} - {MATTERNAME}';
        String folderTemplate = library + '::ACTIVE!3333';
        String wsId = 'ACTIVE!7777';
        String name = 'Test Opportunity';
        // prepare data
        // ins settings
        iManageSettings__c imSettings = new iManageSettings__c(
            Client_Id__c = 'val1',
            ClientField__c = 'custom1',
            MatterField__c = 'custom2',
            Url__c = 'val4',
            Customer_Id__c = 'val5',
            iManage_Default_Folder_Id__c = 'val5',
            Enable_CSV_Export__c = true,
            Mapping_EntityType__c = 'Opportunity',
            Mapping_EntityMatterIdObjectField__c = 'Opportunity',
            Mapping_MatterIdField__c = 'Id',
            Mapping_MatterNameField__c = 'Name',
            Mapping_EntityClientIdObjectField__c = 'Opportunity',
            Mapping_ClientIdField__c = 'Id',
            Mapping_ClientNameField__c = 'Name',
            iManage_Create_Ws_Enabled__c = true,
            iManage_Ws_Auto_Create__c = false,
            iManage_Ws_Folder_Template_Id__c = folderTemplate,
            iManage_Ws_Name_Pattern__c = wsNamePattern,
            iManage_Libraries__c = library
        );
        upsert imSettings;

        // ins Entity
        Opportunity opp = new Opportunity();
        opp.Name = name;
        opp.Closedate = System.today();
        opp.StageName = 'Prospecting';
        insert opp;

        String wsName = String.format(
            '{0} - {1} : {0} - {1}',
            new List<Object>{ opp.Id, opp.Name }
        );
        String currentWsName = 'prefix-' + wsName;

        // ins IManage_WS_to_Entity_Mapping__c
        IManage_WS_to_Entity_Mapping__c wsMapping = new IManage_WS_to_Entity_Mapping__c(
            Auto_created__c = false,
            EntityId__c = opp.Id,
            iManage_Workspace_Created_On__c = '2023-10-25T22:21:47.494Z',
            iManage_WS_Id__c = wsId,
            iManage_WS_Name__c = currentWsName,
            Source__c = 'SF',
            iManage_Library__c = 'ACTIVE'
        );
        insert wsMapping;

        // -- mock callouts
        TestIManageApiResponseHelper respHelper = new TestIManageApiResponseHelper();
        // callout:iManageCreds/work/api/v2/customers/1/libraries/ACTIVE/workspaces/ACTIVE!7777
        String getWsEndpoint_7777 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/workspaces/{2}',
            new List<Object>{ customerId, library, 'ACTIVE!7777' }
        );
        String getWs_7777_json = '{"wstype":"workspace","version":1,"system_edit_date":"2024-01-15T20:26:18.008Z","retain_days":365,"iwl":"iwl:dms=cloudimanage.com&&lib=Active&&num=1001828&&ver=1","is_hipaa":false,"document_number":1001828,"custom2":"' + opp.Id + '","custom2_ssid":"100658363612929491","custom2_description":"Test Mat","custom1_ssid":"100490071102362395","custom1":"' + opp.Id + '","custom1_description":"777","create_profile_date":"2024-01-11T15:12:31.576Z","owner":"TEST","owner_description":"test","name":"' + currentWsName + '","last_user_description":"test","last_user":"TEST","is_external_as_normal":false,"is_external":false,"is_declared":false,"id":"ACTIVE!7777","has_subfolders":true,"effective_security":"full_access","edit_date":"2024-01-15T20:26:18.008Z","description":"Test","default_security":"public","database":"ACTIVE","create_date":"2024-01-11T15:12:31.576Z"}';
        IManageWWorkspace getWs_7777_data = (IManageWWorkspace) JSON.deserialize(
            getWs_7777_json,
            IManageWWorkspace.class
        );
        HttpResponse getWs_7777_resp = respHelper.buildGetWorkspaceResponse(200, getWs_7777_data);

        String getWsNvpEndpoint_7777 = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/workspaces/{2}/name-value-pairs',
            new List<Object>{ customerId, library, wsId }
        );
        String templateId = 'ACTIVE!3333';
        HttpResponse getWsNvp_7777_resp = respHelper.buildNameValuePairResponse(
            200,
            new Map<String, String>{ 'templateId' => templateId }
        );
        String getTemplateNvpEndpoint = TestUtils.buildCalloutUrl(
            '/work/api/v2/customers/{0}/libraries/{1}/workspaces/{2}/name-value-pairs',
            new List<Object>{ customerId, library, templateId }
        );
        HttpResponse getTemplateNvpResponse = respHelper.buildNameValuePairResponse(
            200,
            new Map<String, String>{
                'IMCC_Template_PrefixSufix_Value' => '<pre>prefix-<pre>',
                'IMCC_Template_Allow_Prefix' => '0'
            }
        );

        Map<String, List<HttpResponse>> responses = new Map<String, List<HttpResponse>>{
            getWsEndpoint_7777 => new List<HttpResponse>{ getWs_7777_resp },
            getWsNvpEndpoint_7777 => new List<HttpResponse>{ getWsNvp_7777_resp },
            getTemplateNvpEndpoint => new List<HttpResponse>{ getTemplateNvpResponse }
        };
        setupMockCallouts(customerId, library, responses);

        Test.startTest();
        Map<String, String> workspaceParameters = EntityIManageWorkspaceUpdater.getWorkspaceParameters(
            wsMapping,
            wsNamePattern
        );
        Test.stopTest();
        System.assertEquals(null, workspaceParameters);
    }

    @isTest
    static void buildWorkspaceNameTest() {
        String namePattern = '{CLIENTCODE} - {CLIENTNAME} : {MATTERCODE} - {MATTERNAME}';
        String imClientId = '1';
        String imClientName = 'cn';
        String imMatterId = '2';
        String imMatterName = 'mn';
        String expectedResult = String.format(
            '{0} - {1} : {2} - {3}',
            new List<Object>{ imClientId, imClientName, imMatterId, imMatterName }
        );

        Test.startTest();
        String result = EntityIManageWorkspaceUpdater.buildWorkspaceName(
            namePattern, imClientId, imClientName, imMatterId, imMatterName
        );
        Test.stopTest();
        System.assert(result == expectedResult, 'Wrong value =' + result + ', expected = ' + expectedResult);
    }

    @isTest
    static void buildWorkspaceNameNullTest() {
        Test.startTest();
        String expectedResult = null;
        String result = EntityIManageWorkspaceUpdater.buildWorkspaceName(
            null, null, null, null, null
        );
        Test.stopTest();
        System.assert(result == expectedResult, 'Wrong value =' + result + ', expected = ' + expectedResult);
    }

    @isTest
    static void workspaceSyncUsesOneRecordPerScopeTest() {
        System.assertEquals(1, WorkspaceSyncBatch.SCOPE_SIZE);
    }

    @isTest
    static void workspaceSyncBatchLauncherTest() {
        Test.startTest();
        Id jobId = System.enqueueJob(
            new WorkspaceSyncBatchLauncher(new Set<Id>())
        );
        Test.stopTest();

        AsyncApexJob queueableJob = [
            SELECT Status
            FROM AsyncApexJob
            WHERE Id = :jobId
        ];
        System.assertEquals('Completed', queueableJob.Status);
    }

    @isTest
    static void updateIManageWorkspacesStartsFutureTest() {
        createMappingSettings();
        createOpportunity('Invocable Update');
        setupMockCallouts(1, 'ACTIVE', null);

        Test.startTest();
        EntityIManageWorkspaceUpdater.updateIManageWorkspaces();
        System.assertEquals(1, Limits.getFutureCalls());
        Test.stopTest();
    }

    @isTest
    static void updateByEntityIdsLegacyEntryPointTest() {
        createMappingSettings();
        Opportunity opportunity = createOpportunity('Legacy ID Update');
        setupMockCallouts(1, 'ACTIVE', null);

        Test.startTest();
        EntityIManageWorkspaceUpdater.updateIManageWorkspaceByEntityIds(
            new Set<Id>{ opportunity.Id }
        );
        System.assertEquals(1, Limits.getFutureCalls());
        Test.stopTest();
    }

    @isTest
    static void processChangedEntitiesLegacyEntryPointTest() {
        createMappingSettings();
        createOpportunity('Legacy Changed Entity Update');
        setupMockCallouts(1, 'ACTIVE', null);

        Test.startTest();
        EntityIManageWorkspaceUpdater.processChangedEntities();
        System.assertEquals(1, Limits.getFutureCalls());
        Test.stopTest();
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

    private static AsyncApexJob getWorkspaceSyncBatchJob() {
        return [
            SELECT Status, TotalJobItems, JobItemsProcessed, NumberOfErrors
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'WorkspaceSyncBatch'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
    }

    private static void createMappingSettings() {
        upsert new iManageSettings__c(
            Client_Id__c = 'test-client',
            Customer_Id__c = '1',
            Url__c = 'https://example.test',
            Mapping_EntityType__c = 'Opportunity',
            Mapping_EntityMatterIdObjectField__c = 'Opportunity',
            Mapping_MatterIdField__c = 'Id',
            Mapping_MatterNameField__c = 'Name',
            Mapping_EntityClientIdObjectField__c = 'Opportunity',
            Mapping_ClientIdField__c = 'Id',
            Mapping_ClientNameField__c = 'Name'
        );
    }

    private static Opportunity createOpportunity(String name) {
        Opportunity opportunity = new Opportunity(
            Name = name,
            CloseDate = System.today(),
            StageName = 'Prospecting'
        );
        insert opportunity;
        return opportunity;
    }
}

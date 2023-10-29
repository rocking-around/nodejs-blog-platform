@isTest
private class IManageDataModelTests {

    @IsTest
    static void iManageWFolderProfileToMapTest() {
        Set<String> doubleFields = new Set<String> {'custom17','custom18', 'custom19', 'custom20'};
        Set<String> boolFields = new Set<String> {'custom25', 'custom26', 'custom27', 'custom28'};
        Set<String> dateFields = new Set<String> {'custom21', 'custom22', 'custom23', 'custom24'};
        Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(new IManageWFolderProfile()));
        for (String key : m.keySet()) {
            if (doubleFields.contains(key)) {
                m.put(key, 1);
                continue;
            }
            if (boolFields.contains(key)) {
                m.put(key, false);
                continue;
            }
            if (dateFields.contains(key)) {
                m.put(key, Datetime.now());
                continue;
            }
            m.put(key, key);
        }
        String pfjson = JSON.serialize(m);
        IManageWFolderProfile profile = (IManageWFolderProfile) JSON.deserialize(
            pfjson,
            IManageWFolderProfile.class
        );
        Test.startTest();
        Map<String, Object> result =  profile.toMap(false);
        Map<String, Object> result2 =  profile.toMap(true);
        Test.stopTest();
        
        System.assert(!result.containsKey('klass'), 'Invalid key = klass');
        System.assert(result.containsKey('class'), 'The key "class" does not exist');
        System.assert(!result2.containsKey('klass'), 'Invalid key = klass');
        System.assert(result2.containsKey('class'), 'The key "class" does not exist');
    }

    @IsTest
    static void iManageWSearchFolderProfileToMapTest() {
        Set<String> intFields = new Set<String> {'size'};
        Set<String> boolFields = new Set<String> {'custom25', 'custom26', 'custom27', 'checked_out', 'documents_only', 'emails_only', 'in_use'};

        Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(new IManageWSearchFolderProfile()));
        for (String key : m.keySet()) {
            if (intFields.contains(key)) {
                m.put(key, 1);
                continue;
            }
            if (boolFields.contains(key)) {
                m.put(key, false);
                continue;
            }
            m.put(key, key);
        }
        String pfjson = JSON.serialize(m);
        IManageWSearchFolderProfile profile = (IManageWSearchFolderProfile) JSON.deserialize(
            pfjson,
            IManageWSearchFolderProfile.class
        );
        Test.startTest();
        Map<String, Object> result =  profile.toMap(false);
        Map<String, Object> result2 =  profile.toMap(true);
        Test.stopTest();

        System.assert(!result.containsKey('klass'), 'Invalid key = klass');
        System.assert(result.containsKey('class'), 'The key "class" does not exist');
        System.assert(!result2.containsKey('klass'), 'Invalid key = klass');
        System.assert(result2.containsKey('class'), 'The key "class" does not exist');
    }
}
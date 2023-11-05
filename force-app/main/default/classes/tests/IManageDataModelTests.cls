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
    static void IManageWSearchFolderProfileFieldsTest() {
        IManageWSearchFolderProfile p = new IManageWSearchFolderProfile();
        Datetime d = Datetime.now();
        String s = 'test str';

        Test.startTest();
        try {
            p.author = s;
            p.body = s;
            p.klass = s;
            p.comment = s;
            p.comments_description_fulltext = s;
            p.comments_fulltext = s;
            p.container = s;
            p.content_type = s;
            p.contenttype = s;
            p.create_date_end = s;
            p.create_date_relative = s;
            p.create_date_start = s;
            p.custom1 = s;
            p.custom10 = s;
            p.custom11 = s;
            p.custom12 = s;
            p.custom13 = s;
            p.custom14 = s;
            p.custom15 = s;
            p.custom16 = s;
            p.custom17 = s;
            p.custom18 = s;
            p.custom19 = s;
            p.custom2 = s;
            p.custom20 = s;
            p.custom21_from = s;
            p.custom21_relative = s;
            p.custom21_to = s;
            p.custom22_from = s;
            p.custom22_relative = s;
            p.custom22_to = s;
            p.custom23_from = s;
            p.custom23_relative = s;
            p.custom23_to = s;
            p.custom24_from = s;
            p.custom24_relative = s;
            p.custom24_to = s;
            p.custom28 = s;
            p.custom29 = s;
            p.custom3 = s;
            p.custom30 = s;
            p.custom4 = s;
            p.custom5 = s;
            p.custom6 = s;
            p.custom7 = s;
            p.custom8 = s;
            p.custom9 = s;
            p.databases = s;
            p.description_fulltext = s;
            p.description = s;
            p.docnum = s;
            p.document_detect_value = s;
            p.edit_date_end = s;
            p.edit_date_relative = s;
            p.edit_date_start = s;
            p.edit_profile_end_date = s;
            p.edit_profile_start_date = s;
            p.fulltext = s;
            p.languageid = s;
            p.name = s;
            p.operator = s;
            p.subclass = s;
            p.type = s;
            p.version = s;
            p.custom25 = true;
            p.custom26 = true;
            p.custom27 = true;
            p.checked_out = true;
            p.documents_only = true;
            p.emails_only = true;
            p.in_use = true;
            p.size = 777;
        } catch (Exception ex) {
            System.assert(false, ex.getMessage());
        }
        Test.stopTest();
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

        // set null
        profile.custom7 = null;
        Map<String, Object> result2 =  profile.toMap(true);
        Test.stopTest();

        System.assert(!result.containsKey('klass'), 'Invalid key = klass');
        System.assert(result.containsKey('class'), 'The key "class" does not exist');
        System.assert(result.containsKey('custom7'), 'The key "custom7" does not exist');
        System.assert(!result2.containsKey('klass'), 'Invalid key = klass');
        System.assert(result2.containsKey('class'), 'The key "class" does not exist');
        System.assert(!result2.containsKey('custom7'), 'The key "custom7" does not exist');
    }

    //IManageWFolderProfile
    @IsTest
    static void iManageCustomFieldsTest() {
        IManageWFolderProfile p = new IManageWFolderProfile();
        Datetime d = Datetime.now();
        Test.startTest();
        // string
        p.custom1 = 'custom1';
        p.custom2 = 'custom2';
        p.custom3 = 'custom3';
        p.custom4 = 'custom4';
        p.custom5 = 'custom5';
        p.custom6 = 'custom6';
        p.custom7 = 'custom7';
        p.custom8 = 'custom8';
        p.custom9 = 'custom9';
        p.custom10 = 'custom10';
        p.custom11 = 'custom11';
        p.custom12 = 'custom12';
        p.custom13 = 'custom13';
        p.custom14 = 'custom14';
        p.custom15 = 'custom15';
        p.custom16 = 'custom16';
        p.custom29 = 'custom29';
        p.custom30 = 'custom30';
        p.custom31 = 'custom31';
        p.custom1_description = 'custom1_description';
        p.custom2_description = 'custom2_description';
        p.custom3_description = 'custom3_description';
        p.custom4_description = 'custom4_description';
        p.custom5_description = 'custom5_description';
        p.custom6_description = 'custom6_description';
        p.custom7_description = 'custom7_description';
        p.custom8_description = 'custom8_description';
        p.custom9_description = 'custom9_description';
        p.custom10_description = 'custom10_description';
        p.custom11_description = 'custom11_description';
        p.custom12_description = 'custom12_description';
        p.custom29_description = 'custom29_description';
        p.custom30_description = 'custom30_description';
        p.custom31_description = 'custom31_description';
        //double
        p.custom17 = 777;
        p.custom18 = 777;
        p.custom19 = 777;
        p.custom20 = 777;
        // datetime
        p.custom21 = d;
        p.custom22 = d;
        p.custom23 = d;
        p.custom24 = d;
        // bool
        p.custom25 = true;
        p.custom26 = true;
        p.custom27 = true;
        p.custom28 = true;
        
        Test.stopTest();

        System.assert(p.custom1 == 'custom1', 'wrong walue');
        System.assert(p.custom2 == 'custom2', 'wrong walue');
        System.assert(p.custom3 == 'custom3', 'wrong walue');
        System.assert(p.custom4 == 'custom4', 'wrong walue');
        System.assert(p.custom5 == 'custom5', 'wrong walue');
        System.assert(p.custom6 == 'custom6', 'wrong walue');
        System.assert(p.custom7 == 'custom7', 'wrong walue');
        System.assert(p.custom8 == 'custom8', 'wrong walue');
        System.assert(p.custom9 == 'custom9', 'wrong walue');
        System.assert(p.custom10 == 'custom10', 'wrong walue');
        System.assert(p.custom11 == 'custom11', 'wrong walue');
        System.assert(p.custom12 == 'custom12', 'wrong walue');
        System.assert(p.custom13 == 'custom13', 'wrong walue');
        System.assert(p.custom14 == 'custom14', 'wrong walue');
        System.assert(p.custom15 == 'custom15', 'wrong walue');
        System.assert(p.custom16 == 'custom16', 'wrong walue');
        System.assert(p.custom29 == 'custom29', 'wrong walue');
        System.assert(p.custom30 == 'custom30', 'wrong walue');
        System.assert(p.custom31 == 'custom31', 'wrong walue');
        System.assert(p.custom1_description == 'custom1_description', 'wrong value');
        System.assert(p.custom2_description == 'custom2_description', 'wrong value');
        System.assert(p.custom3_description == 'custom3_description', 'wrong value');
        System.assert(p.custom4_description == 'custom4_description', 'wrong value');
        System.assert(p.custom5_description == 'custom5_description', 'wrong value');
        System.assert(p.custom6_description == 'custom6_description', 'wrong value');
        System.assert(p.custom7_description == 'custom7_description', 'wrong value');
        System.assert(p.custom8_description == 'custom8_description', 'wrong value');
        System.assert(p.custom9_description == 'custom9_description', 'wrong value');
        System.assert(p.custom10_description == 'custom10_description', 'wrong value');
        System.assert(p.custom11_description == 'custom11_description', 'wrong value');
        System.assert(p.custom12_description == 'custom12_description', 'wrong value');
        System.assert(p.custom29_description == 'custom29_description', 'wrong value');
        System.assert(p.custom30_description == 'custom30_description', 'wrong value');
        System.assert(p.custom31_description == 'custom31_description', 'wrong value');
        //double
        System.assert(p.custom17 == 777, 'wrong walue');
        System.assert(p.custom18 == 777, 'wrong walue');
        System.assert(p.custom19 == 777, 'wrong walue');
        System.assert(p.custom20 == 777, 'wrong walue');
        // datetime
        System.assert(p.custom21 == d, 'wrong walue');
        System.assert(p.custom22 == d, 'wrong walue');
        System.assert(p.custom23 == d, 'wrong walue');
        System.assert(p.custom24 == d, 'wrong walue');
        // bool
        System.assert(p.custom25 == true, 'wrong walue');
        System.assert(p.custom26 == true, 'wrong walue');
        System.assert(p.custom27 == true, 'wrong walue');
        System.assert(p.custom28 == true, 'wrong walue');
    }
}
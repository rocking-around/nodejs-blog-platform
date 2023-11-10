public with sharing class IManageWSearchFolderProfile {
        public String author { get; set; }
        public String body { get; set; }
        // can't use reserved word 'class'
        public String klass { get; set; }
        public String comment { get; set; }
        public String comments_description_fulltext { get; set; }
        public String comments_fulltext { get; set; }
        public String container { get; set; }
        public String content_type { get; set; }
        public String contenttype { get; set; }
        public String create_date_end { get; set; }
        public String create_date_relative { get; set; }
        public String create_date_start { get; set; }
        public String custom1 { get; set; }
        public String custom10 { get; set; }
        public String custom11 { get; set; }
        public String custom12 { get; set; }
        public String custom13 { get; set; }
        public String custom14 { get; set; }
        public String custom15 { get; set; }
        public String custom16 { get; set; }
        public String custom17 { get; set; }
        public String custom18 { get; set; }
        public String custom19 { get; set; }
        public String custom2 { get; set; }
        public String custom20 { get; set; }
        public String custom21_from { get; set; }
        public String custom21_relative { get; set; }
        public String custom21_to { get; set; }
        public String custom22_from { get; set; }
        public String custom22_relative { get; set; }
        public String custom22_to { get; set; }
        public String custom23_from { get; set; }
        public String custom23_relative { get; set; }
        public String custom23_to { get; set; }
        public String custom24_from { get; set; }
        public String custom24_relative { get; set; }
        public String custom24_to { get; set; }
        public Boolean custom25 { get; set; }
        public Boolean custom26 { get; set; }
        public Boolean custom27 { get; set; }
        public String custom28 { get; set; }
        public String custom29 { get; set; }
        public String custom3 { get; set; }
        public String custom30 { get; set; }
        public String custom4 { get; set; }
        public String custom5 { get; set; }
        public String custom6 { get; set; }
        public String custom7 { get; set; }
        public String custom8 { get; set; }
        public String custom9 { get; set; }
        public String databases { get; set; }
        public String description_fulltext { get; set; }
        public String description { get; set; }
        public String docnum { get; set; }
        public String document_detect_value { get; set; }
        public String edit_date_end { get; set; }
        public String edit_date_relative { get; set; }
        public String edit_date_start { get; set; }
        public String edit_profile_end_date { get; set; }
        public String edit_profile_start_date { get; set; }
        public String fulltext { get; set; }
        public String languageid { get; set; }
        public String name { get; set; }
        public String operator { get; set; }
        public Integer size { get; set; }
        public String subclass { get; set; }
        public String type { get; set; }
        public String version { get; set; }
        public Boolean checked_out { get; set; }
        public Boolean documents_only { get; set; }
        public Boolean emails_only { get; set; }
        public Boolean in_use { get; set; }

        public Map<String, Object> toMap(Boolean suppressNulls) {
            String jsonThis = JSON.serialize(this);
            Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(jsonThis);
    
            if (suppressNulls == true) {
                for (String key : result.keySet()) {
                    if (result.containsKey(key) && result.get(key) == null) {
                        result.remove(key);
                    }
                }
            }
    
            if (result.containsKey('klass')) {
                result.put('class', result.get('klass'));
                result.remove('klass');
            }
    
            return result.size() > 0 ? result : null;
        }
}
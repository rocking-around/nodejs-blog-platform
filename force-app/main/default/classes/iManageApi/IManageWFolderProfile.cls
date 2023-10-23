public with sharing class IManageWFolderProfile extends IManageWCustomFieldsWithDesc {
    // can't use reserved word 'class'
    public string klass { get; set; }
    public string subClass { get; set; }

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
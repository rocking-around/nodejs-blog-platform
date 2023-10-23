public with sharing class IManageWFolder {
  public Datetime activity_date { get; set; }

  public String container_saved_search_id { get; set; }

  public String content_saved_search_id { get; set; }

  public String database { get; set; }

  public String default_security { get; set; }

  public String description { get; set; }

  public Datetime edit_date { get; set; }

  public String effective_security { get; set; }

  public String email { get; set; }

  public String folder_type { get; set; }

  public Boolean has_documents { get; set; }

  public Boolean has_security { get; set; }

  public Boolean has_subfolders { get; set; }

  public String id { get; set; }

  public String imanage_share_eid { get; set; }

  public String imanage_share_url { get; set; }

  public String inherited_default_security { get; set; }

  public Boolean is_container_saved_search { get; set; }

  public Boolean is_content_saved_search { get; set; }

  public Boolean is_external { get; set; }

  public Boolean is_external_as_normal { get; set; }

  public String location { get; set; }

  public String my_matters_shortcut_id { get; set; }

  public String name { get; set; }

  public String owner { get; set; }

  public String owner_description { get; set; }

  public String parent_id { get; set; }

  public IManageWFolderProfile profile { get; set; }

  //public WSearchFolderProfile searchprofile { get; set; }

  public String project_custom1 { get; set; }

  public String project_custom2 { get; set; }

  public String project_custom3 { get; set; }

  public String security_policy { get; set; }

  public String subtype { get; set; }

  public String view_type { get; set; }

  public String workspace_id { get; set; }

  public String workspace_name { get; set; }

  public String wstype { get; set; }

  // JsonIgnore
  public transient Boolean isOptional { get; set; }

  public Map<String, Object> toMap(Boolean suppressNulls) {
    String jsonThis = JSON.serialize(this);
    Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(jsonThis);
    result.put('profile', profile.toMap(true));

    if (suppressNulls == true) {
      for (String key : result.keySet()) {
        if (result.containsKey(key) && result.get(key) == null) {
          result.remove(key);
        }
      }
    }

    return result;
  }

  public Map<String, Object> toWFolderRequestMap() {
    List<String> fields = new List<String>{'default_security', 'description', 'is_external_as_normal', 'email', 'name', 'owner', 'parent_id', 'profile', 'searchprofile', 'project_custom1', 'project_custom2', 'project_custom3', 'database'};

    Map<String, Object> result = toMap(false);
    for (String key : result.keySet()) {
      if (!fields.contains(key)) {
        result.remove(key);
      }
    }

    if (result.containsKey('is_external_as_normal') && result.get('is_external_as_normal') == null) {
      result.put('is_external_as_normal', false);
    }

    return result;
  }
}

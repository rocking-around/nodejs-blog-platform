public with sharing class IManageWWorkspace {
  public String custom1 { get; set; }
  public String custom2 { get; set; }
  public String custom1_description { get; set; }
  public String custom2_description { get; set; }
  public String database { get; set; }
  public String default_security { get; set; }
  public String description { get; set; }
  public Integer document_number { get; set; }
  public Boolean has_subfolders { get; set; }
  public String id { get; set; }
  public Boolean is_declared { get; set; }
  public Boolean is_external { get; set; }
  public Boolean is_external_as_normal { get; set; }
  public Boolean is_hipaa { get; set; }
  public String iwl { get; set; }
  public String name { get; set; }
  public String owner { get; set; }
  public String owner_description { get; set; }
  public String subclass { get; set; }
  public String wstype { get; set; }
  public Integer retain_days { get; set; }
  public Boolean has_documents { get; set; }
  public Object profile { get; set; }

  public IManageWWorkspace cloneThis() {
    return (IManageWWorkspace) JSON.deserialize(
      JSON.serialize(this),
      IManageWWorkspace.class
    );
  }
}

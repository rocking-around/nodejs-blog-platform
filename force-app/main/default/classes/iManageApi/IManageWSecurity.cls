public with sharing class IManageWSecurity {
  public String id { get; set; }

  public String name { get; set; }

  public Integer access { get; set; }

  public String access_level { get; set; }

  public String type { get; set; }

  public String sid { get; set; }

  public Boolean has_restricted_member { get; set; }

  public Boolean isGroup() {
    return this.type == 'group';
  }
}
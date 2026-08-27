public with sharing class IManageMapping {
  @AuraEnabled
  public Id MappingId { get; set; }
  @AuraEnabled
  public String EntityType { get; set; }
  @AuraEnabled
  public String EntityMatterIdObjectField { get; set; }
  @AuraEnabled
  public String MatterIdField { get; set; }
  @AuraEnabled
  public String MatterNameField { get; set; }
  @AuraEnabled
  public String EntityClientIdObjectField { get; set; }
  @AuraEnabled
  public String ClientIdField { get; set; }
  @AuraEnabled
  public String ClientNameField { get; set; }
  @AuraEnabled
  public String WsTemplateField { get; set; }
  @AuraEnabled
  public String LibraryField { get; set; }
  @AuraEnabled
  public Boolean UseOnlyCustom2 { get; set; }
}
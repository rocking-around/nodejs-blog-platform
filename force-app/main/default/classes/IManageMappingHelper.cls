public with sharing class IManageMappingHelper {
  @AuraEnabled
  public static IManageMapping__c getMapping() {
    List<IManageMapping__c> items = [
      SELECT
        Id,
        EntityType__c,
        MatterIdField__c,
        EntityMatterIdObjectField__c,
        ClientIdField__c,
        EntityClientIdObjectField__c
      FROM IManageMapping__c
    ];
    if (items.size() > 1) {
      throw new IManageMappingHelper.ManageMappingException(
        'An IManageMapping__c must not contain more than 1 record'
      );
    }
    return items.size() == 1 ? items[0] : null;
  }

  private static String GetSObjectType(String entityId) {
    return Id.valueOf(entityId).getSObjectType().getDescribe().getName();
  }

  public static IManageMappingHelper.IManageIFrameData getMappingData(
    String entityId
  ) {
    String entityIdSObjName = GetSObjectType(entityId);
    List<IManageMapping__c> items = [
      SELECT
        Id,
        EntityType__c,
        MatterIdField__c,
        EntityMatterIdObjectField__c,
        ClientIdField__c,
        EntityClientIdObjectField__c
      FROM IManageMapping__c
      WHERE EntityType__c = :entityIdSObjName
    ];
    if (items.size() > 1) {
      throw new IManageMappingHelper.ManageMappingException(
        'An IManageMapping__c must not contain more than 1 record'
      );
    }
    IManageMapping__c item = items[0];

    SObject record = Database.query(
      'SELECT ' +
      item.EntityClientIdObjectField__c +
      ', ' +
      item.EntityMatterIdObjectField__c +
      ' FROM ' +
      entityIdSObjName +
      ' WHERE Id = :entityId'
    );

    IManageMappingHelper.IManageIFrameData result = new IManageMappingHelper.IManageIFrameData();

    result.ClientId = GetDataFromObject(
      (String) record.get(item.EntityClientIdObjectField__c),
      item.ClientIdField__c
    );
    if (item.EntityMatterIdObjectField__c == entityIdSObjName)
      result.MatterId = GetDataFromObject(entityId, item.MatterIdField__c);
    else
      result.MatterId = GetDataFromObject(
        (String) record.get(item.EntityMatterIdObjectField__c),
        item.MatterIdField__c
      );

    return result;
  }

  private static String GetDataFromObject(String entityId, String fieldId) {
    String sObjName = GetSObjectType(entityId);

    SObject record = Database.query(
      'SELECT ' +
      fieldId +
      ' FROM ' +
      sObjName +
      ' WHERE Id = :entityId'
    );

    return (String) record.get(fieldId);
  }

  @AuraEnabled
  public static List<IManageMappingHelper.GetFieldResult> getFields(
    String objectName,
    List<String> fieldTypes
  ) {
    System.debug('IManageMappingHelper.getFields(\'' + objectName + '\')');
    List<IManageMappingHelper.GetFieldResult> result = new List<IManageMappingHelper.GetFieldResult>();
    try {
      Schema.DescribeSObjectResult[] descResult = Schema.describeSObjects(
        new List<String>{ objectName }
      );
      for (Schema.DescribeSobjectResult res : descResult) {
        Map<String, Schema.SObjectField> fieldsMap = res.fields.getMap();
        for (String key : fieldsMap.keySet()) {
          Schema.DescribeFieldResult fieldDesc = fieldsMap.get(key)
            .getDescribe();
          if (
            fieldTypes != null &&
            !fieldTypes.contains(String.ValueOf(fieldDesc.getType()))
          ) {
            continue;
          }
          result.add(new IManageMappingHelper.GetFieldResult(fieldDesc));
        }
      }
      System.debug(
        'IManageMappingHelper.getFields(\'' +
        objectName +
        '\') => ' +
        result
      );
      return result;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static void saveMapping(IManageMapping__c mapping) {
    System.debug('IManageMappingHelper.saveMapping(\'' + mapping + '\')');
    try {
      //TODO: Validate and upsert
      upsert mapping;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  public class ManageMappingException extends Exception {
  }

  public class GetFieldResult {
    private String fieldName;
    private String fieldLabel;
    private List<String> referenceTo;
    private String fieldType;
    public GetFieldResult(Schema.DescribeFieldResult descrFieldResult) {
      this.fieldName = descrFieldResult.getName();
      this.fieldLabel = descrFieldResult.getLabel();

      List<Schema.SObjectType> refsTo = descrFieldResult.getReferenceTo();
      if (refsTo != null) {
        referenceTo = new List<String>();
        for (Schema.SObjectType rt : refsTo) {
          referenceTo.add(rt.getDescribe().getName());
        }
      }

      this.fieldType = descrFieldResult.getType().name();
    }

    @AuraEnabled
    public String getFieldName() {
      return fieldName;
    }
    @AuraEnabled
    public String getFieldLabel() {
      return fieldLabel;
    }
    @AuraEnabled
    public List<String> getReferenceTo() {
      return referenceTo;
    }
    @AuraEnabled
    public String getFieldType() {
      return fieldType;
    }
  }

  public class IManageIFrameData {
    public String ClientId;
    public String MatterId;
  }
}

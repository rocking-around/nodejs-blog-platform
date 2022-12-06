public with sharing class IManageMappingHelper {
  @AuraEnabled
  public static IManageMapping getMapping() {
    iManageSettings__c settings = iManageSettings__c.getOrgDefaults();
    IManageMapping mapping = new IManageMapping();
    mapping.EntityType = settings.Mapping_EntityType__c;
    mapping.EntityMatterIdObjectField = settings.Mapping_EntityMatterIdObjectField__c;
    mapping.MatterIdField = settings.Mapping_MatterIdField__c;
    mapping.MatterNameField = settings.Mapping_MatterNameField__c;
    mapping.EntityClientIdObjectField = settings.Mapping_EntityClientIdObjectField__c;
    mapping.ClientIdField = settings.Mapping_ClientIdField__c;
    mapping.ClientNameField = settings.Mapping_ClientNameField__c;
    return mapping;
  }

  @AuraEnabled
  public static Map<String, Object> getSObjectMetadata(String objApiName) {
    Schema.DescribeSObjectResult[] descResults = Schema.describeSObjects(
      new List<String>{ objApiName }
    );
    DescribeSObjectResult describeSObjectResult = descResults.get(0);
    return new Map<String, Object>{
      'label' => describeSObjectResult.getLabel(),
      'name' => describeSObjectResult.getName(),
      //'sobjectType' => describeSObjectResult.getSobjectType(),
      'associateEntityType' => describeSObjectResult.getAssociateEntityType()
    };
  }

  private static String GetSObjectType(String entityId) {
    return Id.valueOf(entityId).getSObjectType().getDescribe().getName();
  }

  public static IManageMappingHelper.IManageIFrameData getMappingData(
    String entityId
  ) {
    String entityIdSObjName = GetSObjectType(entityId);
    IManageMapping mapping = IManageMappingHelper.getMapping();

    if (!mapping.EntityType.equals(entityIdSObjName)) {
      throw new IManageExceptions.ManageMappingException(
        'There is no mapping for the \'' +
        entityIdSObjName +
        '\''
      );
    }

    Set<String> recordFields = new Set<String>();
    if (entityIdSObjName.equals(mapping.EntityClientIdObjectField)) {
      recordFields.add(mapping.ClientIdField);
    } else {
      recordFields.add(mapping.EntityClientIdObjectField);
    }

    if (entityIdSObjName.equals(mapping.EntityMatterIdObjectField)) {
      recordFields.add(mapping.MatterIdField);
    } else {
      recordFields.add(mapping.EntityMatterIdObjectField);
    }

    SObject record = Database.query(
      'SELECT ' +
      String.join(new List<String>(recordFields), ', ') +
      ' FROM ' +
      entityIdSObjName +
      ' WHERE Id = :entityId'
    );

    IManageMappingHelper.IManageIFrameData result = new IManageMappingHelper.IManageIFrameData();

    if (mapping.EntityClientIdObjectField == entityIdSObjName) {
      result.ClientId = GetDataFromObject(entityId, mapping.ClientIdField);
    } else {
      result.ClientId = GetDataFromObject(
        (String) record.get(mapping.EntityClientIdObjectField),
        mapping.ClientIdField
      );
    }

    if (mapping.EntityMatterIdObjectField == entityIdSObjName) {
      result.MatterId = GetDataFromObject(entityId, mapping.MatterIdField);
    } else {
      result.MatterId = GetDataFromObject(
        (String) record.get(mapping.EntityMatterIdObjectField),
        mapping.MatterIdField
      );
    }

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
  public static void saveMapping(Map<String, Object> mapping) {
    System.debug('IManageMappingHelper.saveMapping(\'' + mapping + '\')');
    iManageSettings__c s = iManageSettings__c.getOrgDefaults();

    s.Mapping_EntityType__c = (String) mapping.get('EntityType');
    s.Mapping_MatterIdField__c = (String) mapping.get('MatterIdField');
    s.Mapping_MatterNameField__c = (String) mapping.get('MatterNameField');
    s.Mapping_EntityMatterIdObjectField__c = (String) mapping.get(
      'EntityMatterIdObjectField'
    );
    s.Mapping_ClientIdField__c = (String) mapping.get('ClientIdField');
    s.Mapping_ClientNameField__c = (String) mapping.get('ClientNameField');
    s.Mapping_EntityClientIdObjectField__c = (String) mapping.get(
      'EntityClientIdObjectField'
    );
    upsert s;
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

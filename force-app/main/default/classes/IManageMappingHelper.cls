public with sharing class IManageMappingHelper {
  @AuraEnabled
  public static IManageMapping getMapping() {
    Logger.getInstance().info('IManageMappingHelper::getMapping, start method');
    LicenseService.CheckOrganizationLicense();

    try {
      IManageMapping mapping = getMappingSettings();
      Logger.getInstance()
        .info(
          'IManageMappingHelper::getMapping, result=' + JSON.serialize(mapping)
        );
      return mapping;
    } catch (Exception ex) {
      Logger.getInstance().error(ex, 'IManageMappingHelper::getMapping');
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
  }

  public static IManageMapping getMappingSettings() {
    Logger.getInstance()
      .info('IManageMappingHelper::getMappingSettings, start method');
    LicenseService.CheckOrganizationLicense();

    try {
      iManageSettings__c settings = iManageSettings__c.getOrgDefaults();
      IManageMapping mapping = new IManageMapping();
      mapping.EntityType = settings.Mapping_EntityType__c;
      mapping.EntityMatterIdObjectField = settings.Mapping_EntityMatterIdObjectField__c;
      mapping.MatterIdField = settings.Mapping_MatterIdField__c;
      mapping.MatterNameField = settings.Mapping_MatterNameField__c;
      mapping.EntityClientIdObjectField = settings.Mapping_EntityClientIdObjectField__c;
      mapping.ClientIdField = settings.Mapping_ClientIdField__c;
      mapping.ClientNameField = settings.Mapping_ClientNameField__c;
      mapping.WsTemplateField = settings.Mapping_WSTemplateField__c;

      Logger.getInstance()
        .info(
          'IManageMappingHelper::getMappingSettings, result=' +
          JSON.serialize(mapping)
        );
      return mapping;
    } catch (Exception ex) {
      Logger.getInstance()
        .error(ex, 'IManageMappingHelper::getMappingSettings');
      throw ex;
    }
  }

  @AuraEnabled
  public static List<Map<String, String>> getAllSObjectsMetadata() {
    try {
      Logger.getInstance()
        .info('IManageMappingHelper::getAllSObjectsMetadata, start method');
      List<Map<String, String>> result = new List<Map<String, String>>();
      Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
      for (String key : schemaMap.keySet()) {
        Schema.DescribeSObjectResult dr = schemaMap.get(key).getDescribe();
        if (
          /*dr.isCustom() && */ dr.isAccessible() &&
          dr.isCreateable() &&
          !dr.isCustomSetting()
        ) {
          result.Add(
            new Map<String, String>{
              'label' => dr.getLabel(),
              'name' => dr.getName(),
              'associateEntityType' => dr.getAssociateEntityType()
            }
          );
        }
      }
      Logger.getInstance()
        .info(
          'IManageMappingHelper::getAllSObjectsMetadata, result=' +
          JSON.serialize(result)
        );
      return result;
    } catch (Exception ex) {
      Logger.getInstance()
        .error(ex, 'IManageMappingHelper::getAllSObjectsMetadata');
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
  }

  @AuraEnabled
  public static Map<String, Object> getSObjectMetadata(String objApiName) {
    Logger.getInstance()
      .info(
        'IManageMappingHelper::getSObjectMetadata, start method, params["objApiName"]:' +
        objApiName
      );
    LicenseService.CheckOrganizationLicense();

    try {
      Schema.DescribeSObjectResult[] descResults = Schema.describeSObjects(
        new List<String>{ objApiName }
      );
      DescribeSObjectResult describeSObjectResult = descResults.get(0);
      Map<String, Object> result = new Map<String, Object>{
        'label' => describeSObjectResult.getLabel(),
        'name' => describeSObjectResult.getName(),
        //'sobjectType' => describeSObjectResult.getSobjectType(),
        'associateEntityType' => describeSObjectResult.getAssociateEntityType()
      };
      Logger.getInstance()
        .info(
          'IManageMappingHelper::getSObjectMetadata, result=' +
          JSON.serialize(result)
        );
      return result;
    } catch (Exception ex) {
      Logger.getInstance()
        .error(ex, 'IManageMappingHelper::getSObjectMetadata');
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
  }

  private static String GetSObjectType(String entityId) {
    if (entityId == null || entityId == '')
      return null;
    Id id = Id.valueOf(entityId);
    if (id == null)
      return null;
    return id.getSObjectType().getDescribe().getName();
  }

  public static IManageMappingHelper.IManageIFrameData getMappingData(
    String entityId
  ) {
    Logger.getInstance()
      .info(
        'IManageMappingHelper::getMappingData, start method, params["entityId"]:' +
        entityId
      );

    Map<String, Object> mappingData = getMappingDataBySObjectId(entityId);
    IManageMappingHelper.IManageIFrameData result = new IManageMappingHelper.IManageIFrameData();
    result.ClientId = String.valueOf(mappingData.get('clientId'));
    result.MatterId = String.valueOf(mappingData.get('matterId'));

    Logger.getInstance()
      .info(
        'IManageMappingHelper::getMappingData, Result:' +
        JSON.serialize(result)
      );

    return result;
  }

  private static String GetDataFromObject(String entityId, String fieldId) {
    String sObjName = GetSObjectType(entityId);
    if (sObjName == '' || sObjName == null)
      return null;

    SObject record = Database.query(
      'SELECT ' +
      fieldId +
      ' FROM ' +
      sObjName +
      ' WHERE Id = :entityId'
    );
    return String.valueOf(record.get(fieldId));
  }

  @AuraEnabled
  public static List<IManageMappingHelper.GetFieldResult> getFields(
    String objectName,
    List<String> fieldTypes
  ) {
    Map<String, Object> params = new Map<String, Object>{
      'objectName' => objectName,
      'fieldTypes' => fieldTypes
    };

    Logger.getInstance()
      .info(
        'IManageMappingHelper::getFields, start method. Params: ' +
        JSON.serialize(params)
      );

    LicenseService.CheckOrganizationLicense();
    try {
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

        Logger.getInstance()
          .info(
            'IManageMappingHelper::getFields, Result: ' + JSON.serialize(result)
          );
        return result;
      } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
      }
    } catch (AuraHandledException ex) {
      Logger.getInstance().error(ex, 'IManageMappingHelper::getFields');
      throw ex;
    } catch (Exception ex) {
      Logger.getInstance().error(ex, 'IManageMappingHelper::getFields');
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
  }

  @TestVisible
  private static Map<String, Object> getMappingDataBySObjectId(
    String entityId
  ) {
    String logPrefix = 'IManageMappingHelper::getMappingDataBySObjectId';
    Map<String, Object> params = new Map<String, Object>{
      'entityId' => entityId
    };

    Logger.getInstance()
      .info(
        logPrefix + ', start method. Params: ' +
        JSON.serialize(params)
      );

    String entityIdSObjName = GetSObjectType(entityId);

    IManageMapping mapping = IManageMappingHelper.getMappingSettings();

    if (!mapping.EntityType.equals(entityIdSObjName)) {
      String errorMessage =
        'There is no mapping for the \'' +
        entityIdSObjName +
        '\'';
      Logger.getInstance()
        .warn(logPrefix + ', ' + errorMessage);
      throw new IManageExceptions.IManageMappingException(errorMessage);
    }

    // Client fields
    Set<String> recordFields = new Set<String>();
    if (entityIdSObjName.equals(mapping.EntityClientIdObjectField)) {
      recordFields.add(mapping.ClientIdField);
      if (String.isNotBlank(mapping.ClientNameField)) {
        recordFields.add(mapping.ClientNameField);
      }
    } else {
      recordFields.add(mapping.EntityClientIdObjectField);
    }


    // Matter fields
    if (entityIdSObjName.equals(mapping.EntityMatterIdObjectField)) {
      recordFields.add(mapping.MatterIdField);
      if (String.isNotBlank(mapping.MatterNameField)) {
        recordFields.add(mapping.MatterNameField);
      }
    } else {
      recordFields.add(mapping.EntityMatterIdObjectField);
    }

    // Workspace Template
    Boolean wsTemplateFieldNotEmpty = String.isNotBlank(mapping.WsTemplateField);
    if (wsTemplateFieldNotEmpty) {
      recordFields.add(mapping.WsTemplateField);
    }

    String soql = 'SELECT ' +
    String.join(new List<String>(recordFields), ', ') +
    ' FROM ' +
    entityIdSObjName +
    ' WHERE Id = :entityId';

    SObject record = Database.query(soql);

    // Result fields
    String clientId = null;
    String matterId = null;
    String clientName = null;
    String matterName = null;
    String wsTemplate = null;

    // Client
    String clientSObjd = mapping.EntityClientIdObjectField == entityIdSObjName
      ? entityId
      : (String) record.get(mapping.EntityClientIdObjectField);

    clientId = GetDataFromObject(clientSObjd, mapping.ClientIdField);
    if (String.isNotBlank(mapping.ClientNameField)) {
      clientName = GetDataFromObject(clientSObjd, mapping.ClientNameField);
    }

    // Matter
    String matterSObjd = mapping.EntityMatterIdObjectField == entityIdSObjName
      ? entityId
      : (String) record.get(mapping.EntityMatterIdObjectField);

    matterId = GetDataFromObject(matterSObjd, mapping.MatterIdField);
    if (String.isNotBlank(mapping.MatterNameField)) {
      matterName = GetDataFromObject(matterSObjd, mapping.MatterNameField);
    }

    // Workspace Template
    if (wsTemplateFieldNotEmpty) {
      wsTemplate = String.valueOf(record.get(mapping.WsTemplateField));
    }

    Map<String, Object> result = new Map<String, Object> {
      'clientId' => clientId,
      'matterId' => matterId,
      'clientName' => clientName,
      'matterName' => matterName,
      'wsTemplate' => wsTemplate
    };

    Logger.getInstance()
      .info(
        logPrefix + ', start method. Result: ' +
        JSON.serialize(result)
      );

    return result;
  }

  @AuraEnabled
  public static void saveMapping(Map<String, Object> mapping) {
    Map<String, Object> params = new Map<String, Object>{
      'mapping' => mapping
    };

    Logger.getInstance()
      .info(
        'IManageMappingHelper::saveMapping, start method. Params: ' +
        JSON.serialize(params)
      );

    LicenseService.CheckOrganizationLicense();

    try {
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
      s.Mapping_WSTemplateField__c = (String) mapping.get('WsTemplateField');
      upsert s;
      Logger.getInstance()
        .info('IManageMappingHelper::saveMapping, Saved: ' + JSON.serialize(s));
    } catch (Exception ex) {
      Logger.getInstance().error(ex, 'IManageMappingHelper::saveMapping');
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
  }

  @AuraEnabled
  public static Map<String, Object> getIManageDataFromSObject(String entityId) {
    String logPrefix = 'IManageMappingHelper::getIManageDataFromSObject';
    try {
      Map<String, Object> params = new Map<String, Object>{
        'entityId' => entityId
      };

      Logger.getInstance()
        .info(
          logPrefix + ', start method. Params: ' +
          JSON.serialize(params)
        );

      Map<String, Object> result = getMappingDataBySObjectId(entityId);

      Logger.getInstance()
          .info(
            logPrefix + ', Result: ' + JSON.serialize(result)
          );

      return result;
    } catch (Exception ex) {
      Logger.getInstance().error(ex, logPrefix);
      throw ex;
    } finally {
      Logger.getInstance().Flush();
    }
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

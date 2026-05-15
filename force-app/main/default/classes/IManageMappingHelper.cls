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
      mapping.LibraryField = settings.Mapping_LibraryField__c;
      mapping.UseOnlyCustom2 = settings.iManage_UseOnlyCustom2__c;

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
    result.Library = String.valueOf(mappingData.get('library'));
    

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
          SObject recordRelated = null;
          String soqlRelated = 'SELECT Id FROM litify_pm__Matter__c WHERE ID IN (SELECT Matter__c FROM ' + entityIdSObjName + ' WHERE Id = :entityId)';
          
          Logger.getInstance()
            .info(
              logPrefix + ' SOQL: ' +  soqlRelated
            );

          try
          {
            recordRelated = Database.query(soqlRelated);
          } 
          catch (Exception ex) 
          {
          } 

          if (recordRelated != null) {
              entityId = recordRelated.Id;
              entityIdSObjName = GetSObjectType(entityId);
          }
     }

    String entityClientIdObjectField = mapping.EntityClientIdObjectField;  
    String entityMatterIdObjectField = mapping.EntityMatterIdObjectField;
    String clientIdField = mapping.ClientIdField;
    String matterIdField = mapping.MatterIdField;
    String clientNameField = mapping.ClientNameField;
    String matterNameField = mapping.MatterNameField;

    if (!mapping.EntityType.equals(entityIdSObjName)) {
      if (entityIdSObjName == 'litify_pm__Intake__c')
      {
        entityClientIdObjectField = entityIdSObjName;
        entityMatterIdObjectField = entityIdSObjName;
        clientIdField = 'DMSClientID__c';
        matterIdField = 'DMSMatterID__c';
        clientNameField = 'DMSClientName__c';
        matterNameField = 'DMSMatterName__c';
      }
      else
      {
        String errorMessage =
          'There is no mapping for the \'' +
          entityIdSObjName +
          '\'';
        Logger.getInstance()
          .warn(logPrefix + ', ' + errorMessage);
        throw new IManageExceptions.IManageMappingException(errorMessage);
      }
    }

    // Client fields
    Set<String> recordFields = new Set<String>();
    if (entityIdSObjName.equals(entityClientIdObjectField)) {
      recordFields.add(clientIdField);
      if (String.isNotBlank(clientNameField)) {
        recordFields.add(clientNameField);
      }
    } else {
      recordFields.add(entityClientIdObjectField);
    }
    

    // Matter fields
    if (entityIdSObjName.equals(entityMatterIdObjectField)) {
      recordFields.add(matterIdField);
      if (String.isNotBlank(matterNameField)) {
        recordFields.add(matterNameField);
      }
    } else {
      recordFields.add(entityMatterIdObjectField);
    }

    // Workspace Template
    Boolean wsTemplateFieldNotEmpty = String.isNotBlank(mapping.WsTemplateField);
    if (wsTemplateFieldNotEmpty) {
      recordFields.add(mapping.WsTemplateField);
    }

    Boolean libraryFieldNotEmpty = String.isNotBlank(mapping.LibraryField);
    if (libraryFieldNotEmpty) {
      recordFields.add(mapping.LibraryField);
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
    String library = null;

    // Client
    String clientSObjd = entityClientIdObjectField == entityIdSObjName
      ? entityId
      : (String) record.get(entityClientIdObjectField);

    clientId = GetDataFromObject(clientSObjd, clientIdField);
    if (String.isNotBlank(clientNameField)) {
      clientName = GetDataFromObject(clientSObjd, clientNameField);
    }

    // Matter
    String matterSObjd = entityMatterIdObjectField == entityIdSObjName
      ? entityId
      : (String) record.get(entityMatterIdObjectField);

    matterId = GetDataFromObject(matterSObjd, matterIdField);
    if (String.isNotBlank(matterNameField)) {
      matterName = GetDataFromObject(matterSObjd, matterNameField);
    }

    // Workspace Template
    if (wsTemplateFieldNotEmpty) {
      wsTemplate = String.valueOf(record.get(mapping.WsTemplateField));
    }

    if (libraryFieldNotEmpty) {
      library =  String.valueOf(record.get(mapping.LibraryField));
    }

    Map<String, Object> result = new Map<String, Object> {
      'clientId' => clientId,
      'matterId' => matterId,
      'clientName' => clientName,
      'matterName' => matterName,
      'wsTemplate' => wsTemplate,
      'library' => library
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
      s.Mapping_LibraryField__c = (String) mapping.get('LibraryField');
      s.iManage_UseOnlyCustom2__c = (Boolean) mapping.get('UseOnlyCustom2');
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

  public static Set<Id> getChangedEntities(
    IManageMapping mapping,
    DateTime dateFrom,
    DateTime dateTo,
    Integer batchSize
  ) {
    Set<Id> entitiesWithChangedMatters = getChangedEntities(
      mapping.EntityType,
      mapping.EntityMatterIdObjectField,
      mapping.MatterIdField,
      dateFrom,
      dateTo,
      batchSize
    );

    Set<Id> entitiesWithChangedClients = getChangedEntities(
      mapping.EntityType,
      mapping.EntityClientIdObjectField,
      mapping.ClientIdField,
      dateFrom,
      dateTo,
      batchSize
    );

    Set<Id> allEntities = new Set<Id>(entitiesWithChangedMatters);
    allEntities.addAll(entitiesWithChangedClients);

    return allEntities;
  }

  public static Set<Id> getEntitiesByMatterOrClientIds(
    IManageMapping mapping,
    Set<Id> ids
  ) {
    Set<Id> entitiesWithChangedMatters = getEntityByMatterOrClientIds(
      mapping.EntityType,
      mapping.EntityMatterIdObjectField,
      mapping.MatterIdField,
      ids
    );

    Set<Id> entitiesWithChangedClients = getEntityByMatterOrClientIds(
      mapping.EntityType,
      mapping.EntityClientIdObjectField,
      mapping.ClientIdField,
      ids
    );

    Set<Id> allEntities = new Set<Id>(entitiesWithChangedMatters);
    allEntities.addAll(entitiesWithChangedClients);

    return allEntities;
  }

  @TestVisible
  private static Set<Id> getChangedEntities(
    String entityType,
    String entityObjectField,
    String entityfieldName,
    DateTime dateFrom,
    DateTime dateTo,
    Integer batchSize
  ) {
    Logger.getInstance()
      .info(
        'IManageMappingHelper::getChangedEntities. params: ' +
        entityType +
        ', ' +
        entityObjectField +
        ', ' +
        entityfieldName +
        ', ' +
        String.valueOf(dateFrom) +
        ', ' +
        String.valueOf(dateTo)
      );

    try {
      String entityObjType = String.escapeSingleQuotes(entityType);
      String entityObjField = String.escapeSingleQuotes(entityObjectField);
      String fieldName = String.escapeSingleQuotes(entityfieldName);
      String query = 'SELECT Id FROM ' + entityObjType;
      String whereConditions = '';
      String orderBy = 'LastModifiedDate DESC';

      if (entityObjType != entityObjField) {
        String ref = getFieldReferenceName(entityObjType, entityObjField);
        whereConditions +=
          entityObjField +
          ' IN ( SELECT Id FROM ' +
          ref +
          ' WHERE LastModifiedDate >= :dateFrom AND LastModifiedDate <= :dateTo ) ';
      } else {
        whereConditions += ' LastModifiedDate >= :dateFrom  AND LastModifiedDate <= :dateTo ';
      }

      if (String.isNotBlank(whereConditions)) {
        query += ' WHERE ' + whereConditions;
      }

      if (String.isNotBlank(orderBy)) {
        query += ' ORDER BY ' + orderBy;
      }

      if (batchSize > 0) {
        query += ' LIMIT ' + batchSize;
      }

      Logger.getInstance()
        .info('IManageMappingHelper::getChangedEntities. SOQL: ' + query);
      List<SObject> results = Database.query(query);
      Set<Id> resultIds = (new Map<Id, SObject>(results)).keySet();
      return resultIds;
    } catch (Exception e) {
      Logger.getInstance().error(e, 'IManageMappingHelper::getChangedEntities');
      throw new AuraHandledException(e.getMessage());
    } finally {
      Logger.getInstance().Flush();
    }
  }

  @TestVisible
  private static Set<Id> getEntityByMatterOrClientIds(
    String entityType,
    String entityObjectField,
    String entityfieldName,
    Set<Id> ids
  ) {
    String logPrefix = 'IManageMappingHelper::getEntityByMatterOrClientId';
    try {
      Map<String, Object> params = new Map<String, Object>{
          'entityType' => entityType,
          'entityObjectField' => entityObjectField,
          'entityfieldName' => entityfieldName,
          'ids' => ids
      };

      Logger.getInstance()
      .info(
          logPrefix + ', start method. Params: ' +
          JSON.serialize(params)
      );

      String entityObjType = String.escapeSingleQuotes(entityType);
      String entityObjField = String.escapeSingleQuotes(entityObjectField);
      String fieldName = String.escapeSingleQuotes(entityfieldName);
      String query = 'SELECT Id FROM ' + entityObjType;
      String whereConditions = '';

      if (entityObjType != entityObjField) {
        String ref = getFieldReferenceName(entityObjType, entityObjField);
        whereConditions +=
          entityObjField +
          ' IN :ids ';
      } else {
        whereConditions += ' Id in :ids ';
      }

      if (String.isNotBlank(whereConditions)) {
        query += ' WHERE ' + whereConditions;
      }

      Logger.getInstance()
        .info(logPrefix + '. SOQL: ' + query);
      List<SObject> results = Database.query(query);
      Set<Id> resultIds = (new Map<Id, SObject>(results)).keySet();
      return resultIds;
    } catch (Exception e) {
      Logger.getInstance().error(e, logPrefix);
      return new Set<Id>();
    } finally {
      Logger.getInstance().Flush();
    }
  }

  @TestVisible
  private static string getFieldReferenceName(String obj, String field) {
    Logger.getInstance()
      .info(
        'IManageMappingHelper::getFieldReferenceName. params: ' +
        obj +
        ', ' +
        field
      );
    String result = null;
    Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
    Schema.SObjectType schema = schemaMap.get(obj);
    Map<String, Schema.SObjectField> fieldMap = schema.getDescribe()
      .fields.getMap();

    Schema.DescribeFieldResult fieldDescr = fieldMap.get(field)
      .getDescribe(FieldDescribeOptions.FULL_DESCRIBE);

    List<Schema.SObjectType> refsTo = fieldDescr.getReferenceTo();
    if (refsTo != null) {
      /*if (refsTo.size() > 1) {
        //TODO: Exception?
      }*/
      result = refsTo.get(0).getDescribe().getName();
    }

    Logger.getInstance()
      .info('IManageMappingHelper::getFieldReferenceName. result: ' + result);
    return result;
  }

  // CLASSES

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
    public String Library; 
  }
}
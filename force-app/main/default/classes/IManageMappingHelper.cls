public with sharing class IManageMappingHelper {
  private static List<IManageMapping> cachedMappings;

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
      List<IManageMapping> mappings = getAllMappingSettings();
      if (mappings.isEmpty()) {
        return null;
      }
      if (mappings.size() > 1) {
        throw new IManageExceptions.IManageMappingException(
          'An entity type is required when multiple iManage mappings are configured.'
        );
      }
      IManageMapping mapping = mappings[0];

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
  public static List<IManageMapping> getMappings() {
    LicenseService.CheckOrganizationLicense();
    return getAllMappingSettings();
  }

  public static List<IManageMapping> getAllMappingSettings() {
    if (cachedMappings == null) {
      cachedMappings = new List<IManageMapping>();
      for (IManage_Mapping_Configuration__c row : [
        SELECT
          Id,
          Entity_Type__c,
          Entity_Client_Id_Object_Field__c,
          Client_Id_Field__c,
          Client_Name_Field__c,
          Entity_Matter_Id_Object_Field__c,
          Matter_Id_Field__c,
          Matter_Name_Field__c,
          Workspace_Template_Field__c,
          Library_Field__c,
          Use_Only_Custom2__c
        FROM IManage_Mapping_Configuration__c
        ORDER BY Entity_Type__c
      ]) {
        cachedMappings.add(toMapping(row));
      }
    }
    return new List<IManageMapping>(cachedMappings);
  }

  public static IManageMapping getMappingSettings(String entityType) {
    if (String.isBlank(entityType)) {
      throw new IManageExceptions.IManageMappingException(
        'Salesforce entity type is required.'
      );
    }
    IManageMapping mapping = findMappingSettings(entityType);
    if (mapping != null) {
      return mapping;
    }
    throw new IManageExceptions.IManageMappingException(
      'There is no mapping for the \'' + entityType + '\'.'
    );
  }

  private static IManageMapping findMappingSettings(String entityType) {
    for (IManageMapping mapping : getAllMappingSettings()) {
      if (mapping.EntityType.equals(entityType)) {
        return mapping;
      }
    }
    return null;
  }

  public static IManageMapping getMappingSettingsForEntityId(Id entityId) {
    if (entityId == null) {
      throw new IManageExceptions.IManageMappingException(
        'Salesforce entity Id is required.'
      );
    }
    return getMappingSettings(
      entityId.getSObjectType().getDescribe().getName()
    );
  }

  private static IManageMapping toMapping(
    IManage_Mapping_Configuration__c row
  ) {
    IManageMapping mapping = new IManageMapping();
    mapping.MappingId = row.Id;
    mapping.EntityType = row.Entity_Type__c;
    mapping.EntityClientIdObjectField = row.Entity_Client_Id_Object_Field__c;
    mapping.ClientIdField = row.Client_Id_Field__c;
    mapping.ClientNameField = row.Client_Name_Field__c;
    mapping.EntityMatterIdObjectField = row.Entity_Matter_Id_Object_Field__c;
    mapping.MatterIdField = row.Matter_Id_Field__c;
    mapping.MatterNameField = row.Matter_Name_Field__c;
    mapping.WsTemplateField = row.Workspace_Template_Field__c;
    mapping.LibraryField = row.Library_Field__c;
    mapping.UseOnlyCustom2 = row.Use_Only_Custom2__c;
    return mapping;
  }

  private static IManage_Mapping_Configuration__c toRecord(
    IManageMapping mapping
  ) {
    return new IManage_Mapping_Configuration__c(
      Id = mapping.MappingId,
      Entity_Type__c = mapping.EntityType,
      Entity_Client_Id_Object_Field__c = mapping.EntityClientIdObjectField,
      Client_Id_Field__c = mapping.ClientIdField,
      Client_Name_Field__c = mapping.ClientNameField,
      Entity_Matter_Id_Object_Field__c = mapping.EntityMatterIdObjectField,
      Matter_Id_Field__c = mapping.MatterIdField,
      Matter_Name_Field__c = mapping.MatterNameField,
      Workspace_Template_Field__c = mapping.WsTemplateField,
      Library_Field__c = mapping.LibraryField,
      Use_Only_Custom2__c = mapping.UseOnlyCustom2 == true
    );
  }

  @AuraEnabled
  public static IManageMapping saveMappingConfiguration(
    IManageMapping mapping
  ) {
    try {
      LicenseService.CheckOrganizationLicense();
      validateMapping(mapping);

      IManageMapping existing = findMappingSettings(mapping.EntityType);
      if (
        existing != null &&
        (mapping.MappingId == null ||
        existing.MappingId != mapping.MappingId)
      ) {
        throw new IManageExceptions.IManageMappingException(
          'A mapping for the selected Salesforce entity type already exists.'
        );
      }

      Schema.DescribeSObjectResult mappingDescribe = IManage_Mapping_Configuration__c.SObjectType.getDescribe();
      if (
        (mapping.MappingId == null && !mappingDescribe.isCreateable()) ||
        (mapping.MappingId != null && !mappingDescribe.isUpdateable())
      ) {
        throw new IManageExceptions.IManageMappingException(
          'You do not have permission to save iManage mappings.'
        );
      }
      IManage_Mapping_Configuration__c record = toRecord(mapping);
      if (mapping.MappingId == null) {
        insert record;
      } else {
        update record;
      }
      invalidateMappingCache();
      return getMappingSettings(mapping.EntityType);
    } catch (AuraHandledException ex) {
      throw ex;
    } catch (DmlException ex) {
      if (
        ex.getNumDml() > 0 &&
        ex.getDmlStatusCode(0) == 'DUPLICATE_VALUE'
      ) {
        throw new AuraHandledException(
          'A mapping for the selected Salesforce entity type already exists.'
        );
      }
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      throw new AuraHandledException(ex.getMessage());
    }
  }

  @AuraEnabled
  public static void deleteMappingConfiguration(Id mappingId) {
    try {
      LicenseService.CheckOrganizationLicense();
      if (mappingId == null) {
        return;
      }
      if (
        !IManage_Mapping_Configuration__c.SObjectType.getDescribe()
          .isDeletable()
      ) {
        throw new IManageExceptions.IManageMappingException(
          'You do not have permission to delete iManage mappings.'
        );
      }
      delete new IManage_Mapping_Configuration__c(Id = mappingId);
      invalidateMappingCache();
    } catch (AuraHandledException ex) {
      throw ex;
    } catch (Exception ex) {
      throw new AuraHandledException(ex.getMessage());
    }
  }

  public static void invalidateMappingCache() {
    cachedMappings = null;
  }

  // Name fields are deliberately absent: they are optional, and the
  // operations that need them report a missing name themselves.
  private static void validateMapping(IManageMapping mapping) {
    if (
      mapping == null ||
      String.isBlank(mapping.EntityType) ||
      String.isBlank(mapping.EntityClientIdObjectField) ||
      String.isBlank(mapping.ClientIdField) ||
      String.isBlank(mapping.EntityMatterIdObjectField) ||
      String.isBlank(mapping.MatterIdField)
    ) {
      throw new IManageExceptions.IManageMappingException(
        'Entity, parent, and child identifier mapping fields are required.'
      );
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
    result.UseOnlyCustom2 = (Boolean) mappingData.get('useOnlyCustom2');
    result.HasLibraryField = (Boolean) mappingData.get('hasLibraryField');

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
    LicenseService.CheckOrganizationLicense();
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
    String requestedEntityType = entityIdSObjName;

    IManageMapping mapping = findMappingSettings(entityIdSObjName);
    if (mapping == null) {
      // Preserve the existing Litify behavior for records related to a Matter.
      SObject relatedMatter;
      String relatedMatterQuery =
        'SELECT Id FROM litify_pm__Matter__c WHERE Id IN ' +
        '(SELECT Matter__c FROM ' +
        entityIdSObjName +
        ' WHERE Id = :entityId)';
      Logger.getInstance().info(logPrefix + ' SOQL: ' + relatedMatterQuery);
      try {
        relatedMatter = Database.query(relatedMatterQuery);
      } catch (Exception ex) {
          Logger.getInstance()
          .warn(
            logPrefix + ', related Matter lookup failed: ' + ex.getMessage()
            );
        relatedMatter = null;
          } 
      if (relatedMatter != null) {
        entityId = relatedMatter.Id;
              entityIdSObjName = GetSObjectType(entityId);
        mapping = findMappingSettings(entityIdSObjName);
      } else if (requestedEntityType == 'litify_pm__Intake__c') {
        List<IManageMapping> mappings = getAllMappingSettings();
        if (mappings.size() == 1) {
          mapping = mappings[0];
        }
      }
      if (mapping == null) {
        throw missingMappingException(requestedEntityType, logPrefix);
          }
     }

    String entityClientIdObjectField = mapping.EntityClientIdObjectField;  
    String entityMatterIdObjectField = mapping.EntityMatterIdObjectField;
    String clientIdField = mapping.ClientIdField;
    String matterIdField = mapping.MatterIdField;
    String clientNameField = mapping.ClientNameField;
    String matterNameField = mapping.MatterNameField;

    if (!mapping.EntityType.equals(entityIdSObjName)) {
      if (entityIdSObjName == 'litify_pm__Intake__c') {
        entityClientIdObjectField = entityIdSObjName;
        entityMatterIdObjectField = entityIdSObjName;
      } else {
        throw missingMappingException(entityIdSObjName, logPrefix);
      }
    }

    // The query below cannot be built without these four. Checked here so a
    // partially configured mapping reports the missing setting by name
    // instead of failing later on malformed SOQL.
    requireMappedField(
      mapping.EntityType,
      'Parent ID Object',
      entityClientIdObjectField
    );
    requireMappedField(mapping.EntityType, 'Parent ID Field', clientIdField);
    requireMappedField(
      mapping.EntityType,
      'Child ID Object',
      entityMatterIdObjectField
    );
    requireMappedField(mapping.EntityType, 'Child ID Field', matterIdField);

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
      'entityType' => mapping.EntityType,
      'clientId' => clientId,
      'matterId' => matterId,
      'clientName' => clientName,
      'matterName' => matterName,
      'wsTemplate' => wsTemplate,
      'library' => library,
      'useOnlyCustom2' => mapping.UseOnlyCustom2,
      'hasLibraryField' => String.isNotBlank(mapping.LibraryField),
      'clientIdFieldName' => mapping.ClientIdField,
      'clientNameFieldName' => mapping.ClientNameField,
      'matterIdFieldName' => mapping.MatterIdField,
      'matterNameFieldName' => mapping.MatterNameField
    };

    Logger.getInstance()
      .info(
        logPrefix + ', start method. Result: ' +
        JSON.serialize(result)
      );

    return result;
  }

  // Separates "the mapping has no field for this" from "the field is mapped
  // but empty on the record". The first is a configuration problem, the
  // second is data entry, and the admin needs to know which one they have.
  public static void requireMappedValue(
    Map<String, Object> mappingData,
    String fieldLabel,
    String fieldNameKey,
    String valueKey
  ) {
    String mappedFieldName = (String) mappingData.get(fieldNameKey);
    if (String.isBlank(mappedFieldName)) {
      throw new IManageExceptions.IManageApplicationException(
        'The iManage mapping for ' +
          (String) mappingData.get('entityType') +
          ' has no ' +
          fieldLabel +
          ' configured.'
      );
    }
    if (String.isBlank((String) mappingData.get(valueKey))) {
      throw new IManageExceptions.IManageApplicationException(
        'The "' + mappedFieldName + '" field is not populated.'
      );
    }
  }

  private static void requireMappedField(
    String entityType,
    String fieldLabel,
    String mappedFieldName
  ) {
    if (String.isNotBlank(mappedFieldName)) {
      return;
    }
    throw new IManageExceptions.IManageMappingException(
      'The iManage mapping for ' +
        entityType +
        ' has no ' +
        fieldLabel +
        ' configured.'
    );
  }

  private static IManageExceptions.IManageMappingException missingMappingException(
    String entityType,
    String logPrefix
  ) {
    String errorMessage = 'There is no mapping for the \'' + entityType + '\'.';
    Logger.getInstance().warn(logPrefix + ', ' + errorMessage);
    return new IManageExceptions.IManageMappingException(errorMessage);
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
      IManageMapping value = new IManageMapping();
      value.MappingId = (Id) mapping.get('MappingId');
      value.EntityType = (String) mapping.get('EntityType');
      value.MatterIdField = (String) mapping.get('MatterIdField');
      value.MatterNameField = (String) mapping.get('MatterNameField');
      value.EntityMatterIdObjectField = (String) mapping.get(
        'EntityMatterIdObjectField'
      );
      value.ClientIdField = (String) mapping.get('ClientIdField');
      value.ClientNameField = (String) mapping.get('ClientNameField');
      value.EntityClientIdObjectField = (String) mapping.get(
        'EntityClientIdObjectField'
      );
      value.WsTemplateField = (String) mapping.get('WsTemplateField');
      value.LibraryField = (String) mapping.get('LibraryField');
      value.UseOnlyCustom2 = (Boolean) mapping.get('UseOnlyCustom2');
      validateMapping(value);
      IManageMapping existing = findMappingSettings(value.EntityType);
      if (value.MappingId == null && existing != null) {
        value.MappingId = existing.MappingId;
      }
      Schema.DescribeSObjectResult mappingDescribe = IManage_Mapping_Configuration__c.SObjectType.getDescribe();
      if (
        (value.MappingId == null && !mappingDescribe.isCreateable()) ||
        (value.MappingId != null && !mappingDescribe.isUpdateable())
      ) {
        throw new IManageExceptions.IManageMappingException(
          'You do not have permission to save iManage mappings.'
        );
      }
      IManage_Mapping_Configuration__c record = toRecord(value);
      if (value.MappingId == null) {
        insert record;
      } else {
        update record;
      }
      invalidateMappingCache();
      Logger.getInstance()
        .info(
          'IManageMappingHelper::saveMapping, Saved: ' + JSON.serialize(record)
        );
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
    public Boolean UseOnlyCustom2;
    public Boolean HasLibraryField;
  }
}

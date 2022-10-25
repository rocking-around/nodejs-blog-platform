public with sharing class IManageCsvHelper {
  private static Integer batchSize = 1000;

  @AuraEnabled
  public static void test() {
    try {
      IManageMapping__c mapping = new IManageMapping__c(
        EntityType__c = 'Opportunity',
        EntityMatterIdObjectField__c = 'CreatedById',
        MatterIdField__c = 'Id',
        MatterNameField__c = 'Username',
        EntityClientIdObjectField__c = 'AccountId',
        ClientIdField__c = 'Id',
        ClientNameField__c = 'Name'
      );
      DateTime dateTo = date.newInstance(2022, 12, 31);
      DateTime dateFrom = dateTo.addYears(-1);
      Set<Id> ids = getChangedEntities(mapping, dateFrom, dateTo);
      for (Id id : ids) {
        System.debug('test: ' + id);
      }

      List<CsvRow> csvRows = getEntitiesByIds(mapping, ids);

      for (CsvRow row : csvRows) {
        System.debug('test entities: ---------------------');
        System.debug('test entities: Id = ' + row.Id);
        System.debug(
          'test entities: LastModifiedDate = ' + row.LastModifiedDate
        );
        System.debug('test entities: MatterId = ' + row.MatterId);
        System.debug('test entities: MatterName = ' + row.MatterName);
        System.debug(
          'test entities: MatterLastModifiedDate = ' +
          row.MatterLastModifiedDate
        );
        System.debug('test entities: ClientId = ' + row.ClientId);
        System.debug('test entities: ClientName = ' + row.ClientName);
        System.debug(
          'test entities: ClientLastModifiedDate = ' +
          row.ClientLastModifiedDate
        );
        System.debug('test entities: ---------------------');
      }
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static List<CsvRow> getData(
    String objectApiName,
    Datetime dateFrom,
    DateTime dateTo
  ) {
    try {
      IManageMapping__c mapping = IManageMappingHelper.getMapping(
        objectApiName
      );

      Set<Id> ids = getChangedEntities(mapping, dateFrom, dateTo);

      List<CsvRow> csvRows = getEntitiesByIds(mapping, ids);

      return csvRows;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  private static Set<Id> getChangedEntities(
    IManageMapping__c mapping,
    DateTime dateFrom,
    DateTime dateTo
  ) {
    Set<Id> entitiesWithChangedMatters = getChangedEntities(
      mapping.EntityType__c,
      mapping.EntityMatterIdObjectField__c,
      mapping.MatterIdField__c,
      dateFrom,
      dateTo
    );

    Set<Id> entitiesWithChangedClients = getChangedEntities(
      mapping.EntityType__c,
      mapping.EntityClientIdObjectField__c,
      mapping.ClientIdField__c,
      dateFrom,
      dateTo
    );

    Set<Id> allEntities = new Set<Id>(entitiesWithChangedMatters);
    allEntities.addAll(entitiesWithChangedClients);

    return allEntities;
  }

  public static List<CsvRow> getEntitiesByIds(
    IManageMapping__c mapping,
    Set<Id> ids
  ) {
    List<CsvRow> result = new List<CsvRow>();
    String entityObjType = String.escapeSingleQuotes(mapping.EntityType__c);
    String matterObjType = String.escapeSingleQuotes(
      mapping.EntityMatterIdObjectField__c
    );
    String clientObjType = String.escapeSingleQuotes(
      mapping.EntityClientIdObjectField__c
    );
    Set<String> fields = new Set<String>{ 'id', 'lastmodifieddate' };

    //Matters
    String matterRelationshipName = getFieldRelationshipName(
      entityObjType,
      matterObjType
    );
    String matterFieldPrefix = matterRelationshipName == null
      ? ''
      : (matterRelationshipName + '.');
    String matterIdField =
      matterFieldPrefix + String.escapeSingleQuotes(mapping.MatterIdField__c);
    String matterNameField =
      matterFieldPrefix + String.escapeSingleQuotes(mapping.MatterNameField__c);
    String matterLastModifiedDateField = matterFieldPrefix + 'LastModifiedDate';
    fields.add(matterIdField.toLowerCase());
    fields.add(matterNameField.toLowerCase());
    fields.add(matterLastModifiedDateField.toLowerCase());

    //Clients
    String clientRelationshipName = getFieldRelationshipName(
      entityObjType,
      clientObjType
    );
    String clientFieldPrefix = clientRelationshipName == null
      ? ''
      : (clientRelationshipName + '.');
    String clientIdField =
      clientFieldPrefix + String.escapeSingleQuotes(mapping.ClientIdField__c);
    String clientNameField =
      clientFieldPrefix +
      +String.escapeSingleQuotes(mapping.ClientNameField__c);
    String clientLastModifiedDateField = clientFieldPrefix + 'LastModifiedDate';
    fields.add(clientIdField.toLowerCase());
    fields.add(clientNameField.toLowerCase());
    fields.add(clientLastModifiedDateField.toLowerCase());

    String query =
      'SELECT ' +
      String.join(new List<String>(fields), ', ') +
      ' FROM ' +
      entityObjType +
      ' WHERE Id IN :ids';

    System.debug('IManageCsvHelper.getEntitiesByIds. SOQL:' + query);
    List<SObject> entities = Database.query(query);
    for (SObject entity : entities) {
      CsvRow row = new CsvRow();
      row.Id = Id.valueOf(String.valueOf(entity.get('Id')));
      row.LastModifiedDate = Datetime.valueOf(entity.get('LastModifiedDate'));

      SObject matterSObj = matterRelationshipName == null
        ? entity
        : entity.getSObject(matterRelationshipName);
      row.MatterId = String.valueOf(matterSObj.get(mapping.MatterIdField__c));
      row.MatterName = String.valueOf(
        matterSObj.get(mapping.MatterNameField__c)
      );
      row.MatterLastModifiedDate = Datetime.valueOf(
        matterSObj.get('LastModifiedDate')
      );

      SObject clientSObj = clientRelationshipName == null
        ? entity
        : entity.getSObject(clientRelationshipName);
      row.ClientId = String.valueOf(clientSObj.get(mapping.ClientIdField__c));
      row.ClientName = String.valueOf(
        clientSObj.get(mapping.ClientNameField__c)
      );
      row.ClientLastModifiedDate = Datetime.valueOf(
        clientSObj.get('LastModifiedDate')
      );
      result.add(row);
    }
    return result;
  }

  private static Set<Id> getChangedEntities(
    String entityType,
    String entityObjectField,
    String entityfieldName,
    DateTime dateFrom,
    DateTime dateTo
  ) {
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
          ' IN ( SELECT ' +
          fieldName +
          ' FROM ' +
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

      query += ' LIMIT ' + batchSize;

      System.debug(
        'IManageCsvHelper.getEntitiesWithChangedMatters. SOQL: ' + query
      );
      List<SObject> results = Database.query(query);
      Set<Id> resultIds = (new Map<Id, SObject>(results)).keySet();
      return resultIds;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static string getFieldRelationshipName(String obj, String field) {
    System.debug(
      'IManageCsvHelper.getFieldRelationshipName(' +
      obj +
      ', ' +
      field +
      ')'
    );
    Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
    Schema.SObjectType schema = schemaMap.get(obj);
    Map<String, Schema.SObjectField> fieldMap = schema.getDescribe()
      .fields.getMap();

    Schema.DescribeFieldResult fieldDescr = fieldMap.get(field)
      .getDescribe(FieldDescribeOptions.FULL_DESCRIBE);

    String result = fieldDescr.getRelationshipName();

    System.debug(
      'IManageCsvHelper.getFieldRelationshipName(' +
      obj +
      ', ' +
      field +
      '): => ' +
      result
    );
    return result;
  }

  @AuraEnabled
  public static string getFieldReferenceName(String obj, String field) {
    System.debug(
      'IManageCsvHelper.getFieldRelationshipName(' +
      obj +
      ', ' +
      field +
      ')'
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

    System.debug(
      'IManageCsvHelper.getFieldRelationshipName(' +
      obj +
      ', ' +
      field +
      '): => ' +
      result
    );
    return result;
  }

  public class CsvRow {
    @AuraEnabled
    public Id Id;
    @AuraEnabled
    public Datetime LastModifiedDate;
    @AuraEnabled
    public String MatterId;
    @AuraEnabled
    public String MatterName;
    @AuraEnabled
    public Datetime MatterLastModifiedDate;
    @AuraEnabled
    public String ClientId;
    @AuraEnabled
    public String ClientName;
    @AuraEnabled
    public Datetime ClientLastModifiedDate;
  }
}

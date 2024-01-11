public with sharing class IManageCsvHelper {
  private static Integer batchSize = 1000;

  @AuraEnabled(cacheable=true)
  public static Boolean isCsvExportEnabled() {
    return iManageSettings__c.getOrgDefaults().Enable_CSV_Export__c;
  }

  public static List<CsvRow> getData(Datetime dateFrom, DateTime dateTo) {
    Map<String, Object> params = new Map<String, Object>{
      'dateFrom' => dateFrom,
      'dateTo' => dateTo
    };

    Logger.getInstance()
      .info(
        'IManageCsvHelper::getData, start method. Params: ' +
        JSON.serialize(params)
      );

    LicenseService.CheckOrganizationLicense();
    try {
      IManageMapping mapping = IManageMappingHelper.getMappingSettings();
      Set<Id> ids = IManageMappingHelper.getChangedEntities(mapping, dateFrom, dateTo, batchSize);
      List<CsvRow> csvRows = getEntitiesByIds(mapping, ids);

      Logger.getInstance()
        .info(
          'IManageCsvHelper::getData, Rows: ' + JSON.serialize(csvRows?.size())
        );
      return csvRows;
    } catch (Exception e) {
      Logger.getInstance().error(e, 'IManageCsvHelper::getData');
      throw e;
    } finally {
      Logger.getInstance().Flush();
    }
  }

  @TestVisible
  private static List<CsvRow> getEntitiesByIds(
    IManageMapping mapping,
    Set<Id> ids
  ) {
    Logger.getInstance()
      .info(
        'IManageCsvHelper::getEntitiesByIds, start method. ids: ' +
        JSON.serialize(ids)
      );

    List<CsvRow> result = new List<CsvRow>();
    String entityObjType = String.escapeSingleQuotes(mapping.EntityType);
    String matterObjType = String.escapeSingleQuotes(
      mapping.EntityMatterIdObjectField
    );
    String clientObjType = String.escapeSingleQuotes(
      mapping.EntityClientIdObjectField
    );
    Set<String> fields = new Set<String>{ 'id', 'lastmodifieddate' };

    //Matters
    String matterRelationshipName = null;
    if (entityObjType != matterObjType) {
      matterRelationshipName = getFieldRelationshipName(
        entityObjType,
        matterObjType
      );
    }
    String matterFieldPrefix = matterRelationshipName == null
      ? ''
      : (matterRelationshipName + '.');
    String matterIdField =
      matterFieldPrefix + String.escapeSingleQuotes(mapping.MatterIdField);
    String matterLastModifiedDateField = matterFieldPrefix + 'LastModifiedDate';
    fields.add(matterIdField.toLowerCase());
    fields.add(matterLastModifiedDateField.toLowerCase());
    if (String.isNotBlank(mapping?.MatterNameField)) {
      String matterNameField =
        matterFieldPrefix + String.escapeSingleQuotes(mapping.MatterNameField);
      fields.add(matterNameField.toLowerCase());
    }

    //Clients
    String clientRelationshipName = null;
    if (entityObjType != clientObjType) {
      clientRelationshipName = getFieldRelationshipName(
        entityObjType,
        clientObjType
      );
    }
    String clientFieldPrefix = clientRelationshipName == null
      ? ''
      : (clientRelationshipName + '.');
    String clientIdField =
      clientFieldPrefix + String.escapeSingleQuotes(mapping.ClientIdField);
    String clientLastModifiedDateField = clientFieldPrefix + 'LastModifiedDate';
    fields.add(clientIdField.toLowerCase());
    fields.add(clientLastModifiedDateField.toLowerCase());
    if (String.isNotBlank(mapping?.ClientNameField)) {
      String clientNameField =
        clientFieldPrefix + +String.escapeSingleQuotes(mapping.ClientNameField);
      fields.add(clientNameField.toLowerCase());
    }

    String query =
      'SELECT ' +
      String.join(new List<String>(fields), ', ') +
      ' FROM ' +
      entityObjType +
      ' WHERE Id IN :ids';

    //System.debug('IManageCsvHelper.getEntitiesByIds. SOQL:' + query);

    Logger.getInstance()
      .info('IManageCsvHelper::getEntitiesByIds. SOQL: ' + query);
    List<SObject> entities = Database.query(query);
    for (SObject entity : entities) {
      CsvRow row = new CsvRow();
      row.Id = Id.valueOf(String.valueOf(entity.get('Id')));
      row.LastModifiedDate = Datetime.valueOf(entity.get('LastModifiedDate'));

      SObject matterSObj = matterRelationshipName == null
        ? entity
        : entity.getSObject(matterRelationshipName);
      row.MatterId = String.valueOf(matterSObj.get(mapping.MatterIdField));
      if (String.isNotBlank(mapping?.MatterNameField)) {
        row.MatterName = String.valueOf(
          matterSObj.get(mapping.MatterNameField)
        );
      }
      row.MatterLastModifiedDate = Datetime.valueOf(
        matterSObj.get('LastModifiedDate')
      );

      SObject clientSObj = clientRelationshipName == null
        ? entity
        : entity.getSObject(clientRelationshipName);
      row.ClientId = String.valueOf(clientSObj.get(mapping.ClientIdField));
      if (String.isNotBlank(mapping?.ClientNameField)) {
        row.ClientName = String.valueOf(
          clientSObj.get(mapping.ClientNameField)
        );
      }
      row.ClientLastModifiedDate = Datetime.valueOf(
        clientSObj.get('LastModifiedDate')
      );
      result.add(row);
    }
    return result;
  }

  @TestVisible
  private static string getFieldRelationshipName(String obj, String field) {
    Logger.getInstance()
      .info(
        'IManageCsvHelper::getFieldRelationshipName. params: ' +
        obj +
        ', ' +
        field
      );
    Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
    Schema.SObjectType schema = schemaMap.get(obj);
    Map<String, Schema.SObjectField> fieldMap = schema.getDescribe()
      .fields.getMap();

    Schema.DescribeFieldResult fieldDescr = fieldMap.get(field)
      .getDescribe(FieldDescribeOptions.FULL_DESCRIBE);

    String result = fieldDescr.getRelationshipName();

    Logger.getInstance()
      .info('IManageCsvHelper::getFieldRelationshipName. result: ' + result);
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

@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class EntityIManageWorkspaceUpdater {
  @InvocableMethod(callout=true)
  global static void updateIManageWorkspaces() {
    String logPrefix = 'EntityIManageWorkspaceUpdater::updateIManageWorkspaces';
    Logger.getInstance().info(logPrefix + '. Start');
    try {
      EntityIManageWorkspaceUpdater.processChangedEntities();
      Logger.getInstance().info(logPrefix + '. Finish');
    } catch (Exception ex) {
      Logger.getInstance().error(ex, logPrefix + '. ERROR');
    } finally {
      Logger.getInstance().Flush();
    }
  }

  @future(callout=true)
  global static void updateIManageWorkspaceByEntityIds(Set<Id> ids) {
    String logPrefix = 'EntityIManageWorkspaceUpdater::updateIManageWorkspaceByEntityId';
    try {
      // 0. read settings
      IManageMapping mapping = IManageMappingHelper.getMappingSettings();
      if (
        String.isBlank(mapping.MatterIdField) ||
        String.isBlank(mapping.ClientIdField)
      ) {
        Logger.getInstance()
          .info(
            logPrefix + '. Settings: MatterIdField or ClientIdField are empty.'
          );
        Logger.getInstance().info(logPrefix + '. Finish');
        return;
      }

      // 1. Get sObjects if they match the configuration
      Set<Id> entityIds = IManageMappingHelper.getEntitiesByMatterOrClientIds(
        mapping,
        ids
      );

      Logger.getInstance()
        .info(logPrefix + '. getChangedEntities: ' + entityIds);

      if (entityIds.size() == 0) {
        return;
      }

      // A future method cannot start Batch Apex, so bridge through Queueable.
      System.enqueueJob(new WorkspaceSyncBatchLauncher(entityIds));

      Logger.getInstance().info(logPrefix + '. Finish');
    } catch (Exception ex) {
      Logger.getInstance().error(ex, logPrefix + '. ERROR');
    } finally {
      Logger.getInstance().Flush();
    }
  }

  @future(callout=true)
  global static void processChangedEntities() {
    String logPrefix = 'EntityIManageWorkspaceUpdater::processChangedEntities';

    try {
      Logger.getInstance().info(logPrefix + '. Start');
      Set<Id> entityIds = getChangedEntityIds();
      if (!entityIds.isEmpty()) {
        // A future method cannot start Batch Apex, so bridge through Queueable.
        System.enqueueJob(new WorkspaceSyncBatchLauncher(entityIds));
      }

      Logger.getInstance().info(logPrefix + '. Finish');
    } catch (Exception ex) {
      Logger.getInstance().error(ex, logPrefix + '. ERROR');
    } finally {
      Logger.getInstance().Flush();
    }
  }

  private static Set<Id> getChangedEntityIds() {
    Integer batchSize = 1000;
    IManageMapping mapping = IManageMappingHelper.getMappingSettings();
    if (
      String.isBlank(mapping.MatterIdField) ||
      String.isBlank(mapping.ClientIdField)
    ) {
      Logger.getInstance()
        .info(
          'EntityIManageWorkspaceUpdater::getChangedEntityIds. Settings: MatterIdField or ClientIdField are empty.'
        );
      return new Set<Id>();
    }

    DateTime dateTo = DateTime.now();
    DateTime dateFrom = dateTo.addDays(-7);
    Set<Id> entityIds = IManageMappingHelper.getChangedEntities(
      mapping,
      dateFrom,
      dateTo,
      batchSize
    );
    Logger.getInstance()
      .info(
        'EntityIManageWorkspaceUpdater::getChangedEntityIds. Changed entities: ' +
        entityIds
      );
    return entityIds;
  }

  @TestVisible
  private static Map<String, String> getWorkspaceParameters(
    IManage_WS_to_Entity_Mapping__c item,
    String wsNamePattern
  ) {
    String logPrefix = 'EntityIManageWorkspaceUpdater::getWorkspaceParameters';
    Map<String, String> result = new Map<String, String>();
    Boolean needUpdate = false;
    Map<String, Object> params = new Map<String, Object>{ 'item' => item };

    Logger.getInstance()
      .info(logPrefix + ', start method. Params: ' + JSON.serialize(params));

    String entityId = item.EntityId__c;
    String workspaceId = item.iManage_WS_Id__c;
    String library = item.iManage_Library__c;
    if (String.isBlank(library)) {
      library = workspaceId.split('!')[0];
    }

    result.put('workspaceId', workspaceId);
    result.put('library', library);

    iManageSettings__c imSettings = iManageSettings__c.getOrgDefaults();
    iManageWrapper.ApiInfo apiInfo = iManageWrapper.GetApiInfo();

    // Extract data from object
    Map<String, Object> mappingData = IManageMappingHelper.getIManageDataFromSObject(
      entityId
    );
    String imClientId = String.valueOf(mappingData.get('clientId'));
    String imClientName = String.valueOf(mappingData.get('clientName'));
    String imMatterId = String.valueOf(mappingData.get('matterId'));
    String imMatterName = String.valueOf(mappingData.get('matterName'));

    if (String.isBlank(imClientId)) {
      throw new IManageExceptions.IManageApplicationException(
        'The "' +
        imSettings.Mapping_ClientIdField__c +
        '" field is not populated.'
      );
    }

    if (String.isBlank(imClientName)) {
      throw new IManageExceptions.IManageApplicationException(
        'The "' +
        imSettings.Mapping_ClientNameField__c +
        '" field is not populated.'
      );
    }

    if (String.isBlank(imMatterId)) {
      throw new IManageExceptions.IManageApplicationException(
        'The "' +
        imSettings.Mapping_MatterIdField__c +
        '" field is not populated.'
      );
    }

    if (String.isBlank(imMatterName)) {
      throw new IManageExceptions.IManageApplicationException(
        'The "' +
        imSettings.Mapping_MatterNameField__c +
        '" field is not populated.'
      );
    }

    String wsName = buildWorkspaceName(
      wsNamePattern,
      imClientId,
      imClientName,
      imMatterId,
      imMatterName
    );
    result.put('wsName', wsName);

    // Has changes?
    IManageWWorkspace ws = iManageWrapper.getWorkspace(workspaceId, library);
    if (ws == null) {
      return null;
    }

    Logger.getInstance().info(logPrefix + '. Found workspace: ' + ws);

    Map<String, Object> wsMap = (Map<String, Object>) JSON.deserializeUntyped(
      JSON.serialize(ws)
    );
    Logger.getInstance().info(logPrefix + '. wsMap: ' + wsMap);
    String currentClient = String.ValueOf(
      wsMap.get(imSettings.ClientField__c)
    );
    String currentMatter = String.ValueOf(
      wsMap.get(imSettings.MatterField__c)
    );
    String currentWsName = String.ValueOf(wsMap.get('name'));
    Logger.getInstance()
      .info(
        String.format(
          '{0}. **** currentClient = {1}, currentMatter = {2}',
          new List<Object>{ logPrefix, currentClient, currentMatter }
        )
      );

    result.put('client', imClientId);
    result.put('matter', imMatterId);

    if (String.isNotBlank(imClientId) && (currentClient != imClientId)) {
      needUpdate = true;
      Logger.getInstance()
        .info(
          String.format(
            ' Need update: SF Client = {1}, iManage Client = {0}',
            new List<Object>{ currentClient, imClientId }
          )
        );
    }

    if (String.isNotBlank(imMatterId) && (currentMatter != imMatterId)) {
      needUpdate = true;
      Logger.getInstance()
        .info(
          String.format(
            ' Need update: SF Matter = {1}, iManage Matter = {0}',
            new List<Object>{ currentMatter, imMatterId }
          )
        );
    }

    if (String.isNotBlank(wsName) && (wsName != currentWsName)) {
      needUpdate = true;
      Logger.getInstance()
        .info(
          String.format(
            ' Need update: iManage Workspace Name = {0}, new Workspace name = {1}',
            new List<Object>{ currentWsName, wsName }
          )
        );
    }

    Logger.getInstance()
      .info(
        String.format(
          '{0}. **** imClientId = {1}, imSettings.ClientField__c = {2}, imMatterId = {3}, imSettings.MatterField__c = {4}',
          new List<Object>{
            logPrefix,
            imClientId,
            imSettings.ClientField__c,
            imMatterId,
            imSettings.MatterField__c
          }
        )
      );

    Logger.getInstance()
      .info(
        logPrefix +
        '. Need update: ' +
        needUpdate +
        ', workspace ID = ' +
        workspaceId
      );

    return needUpdate ? result : null;
  }

  @TestVisible
  private static String buildWorkspaceName(
    String namePattern,
    String imClientId,
    String imClientName,
    String imMatterId,
    String imMatterName
  ) {
    if (string.isBlank(namePattern)) {
      return null;
    }

    return namePattern
      .replace('{CLIENTCODE}', emptyIfNull(imClientId))
      .replace('{MATTERCODE}', emptyIfNull(imMatterId))
      .replace('{CLIENTNAME}', emptyIfNull(imClientName))
      .replace('{MATTERNAME}', emptyIfNull(imMatterName));
  }

  public static Boolean syncWorkspace(
    IManage_WS_to_Entity_Mapping__c wsToEntity
  ) {
    String logPrefix = 'EntityIManageWorkspaceUpdater::syncWorkspace';
    Map<String, Object> wsSettings = ConfigurationHelper.getIManageWorkspaceSettings();
    String wsNamePattern = String.valueOf(
      wsSettings.get('iManageWs:Name_Pattern')
    );
    Map<String, String> wsParams = getWorkspaceParameters(
      wsToEntity,
      wsNamePattern
    );

    Logger.getInstance()
      .info(logPrefix + '. New workspace parameters: ' + wsParams);
    if (wsParams == null) {
      return false;
    }

    Logger.getInstance()
      .info(logPrefix + '. Creating Client and Matter if not exists');
    iManageWorkspacesHelper.createCustomFiledsIfNotExist(
      wsToEntity.EntityId__c,
      wsParams.get('library')
    );
    Logger.getInstance().info(logPrefix + '. Client and Matter created');

    Logger.getInstance().info(logPrefix + '. Updating workspace');
    iManageWorkspacesHelper.updateWorkspace(
      wsParams.get('workspaceId'),
      wsParams.get('library'),
      wsParams.get('wsName'),
      wsParams.get('client'),
      wsParams.get('matter')
    );
    Logger.getInstance().info(logPrefix + '. Workspace updated');
    return true;
  }

  private static String emptyIfNull(String s) {
    return s == null ? '' : s;
  }
}

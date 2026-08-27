public with sharing class IManageMappingMigration {
  // The mapping grid first ships in 2.81; 2.80 still uses the legacy setting.
  private static final Integer FIRST_GRID_MAJOR_VERSION = 2;
  private static final Integer FIRST_GRID_MINOR_VERSION = 81;

  public static void migrateForUpgrade(Version previousVersion) {
    if (!isUpgradeFromLegacyVersion(previousVersion)) {
      return;
    }
    migrateLegacyMapping();
  }

  @TestVisible
  private static Boolean isUpgradeFromLegacyVersion(Version previousVersion) {
    if (previousVersion == null) {
      return false;
    }
    return previousVersion.major() < FIRST_GRID_MAJOR_VERSION ||
      (previousVersion.major() == FIRST_GRID_MAJOR_VERSION &&
      previousVersion.minor() < FIRST_GRID_MINOR_VERSION);
  }

  public static void migrateLegacyMapping() {
    if ([SELECT COUNT() FROM IManage_Mapping_Configuration__c] > 0) {
      return;
    }

    // This is the only supported read of the retained legacy mapping fields.
    // Runtime code must use IManage_Mapping_Configuration__c.
    iManageSettings__c settings = iManageSettings__c.getOrgDefaults();
    if (!hasLegacyMappingValues(settings)) {
      return;
    }
    List<String> missingFields = getMissingRequiredFields(settings);
    if (!missingFields.isEmpty()) {
      throw new IManageExceptions.IManageMappingException(
        'Cannot migrate the legacy iManage mapping. Required fields are missing: ' +
          String.join(missingFields, ', ') +
          '. Before retrying the upgrade, go to Setup > Custom Settings > iManage Settings > Manage > Edit and populate these fields.'
      );
    }

    insert new IManage_Mapping_Configuration__c(
      Entity_Type__c = settings.Mapping_EntityType__c,
      Entity_Client_Id_Object_Field__c = settings.Mapping_EntityClientIdObjectField__c,
      Client_Id_Field__c = settings.Mapping_ClientIdField__c,
      Client_Name_Field__c = settings.Mapping_ClientNameField__c,
      Entity_Matter_Id_Object_Field__c = settings.Mapping_EntityMatterIdObjectField__c,
      Matter_Id_Field__c = settings.Mapping_MatterIdField__c,
      Matter_Name_Field__c = settings.Mapping_MatterNameField__c,
      Workspace_Template_Field__c = settings.Mapping_WSTemplateField__c,
      Library_Field__c = settings.Mapping_LibraryField__c,
      Use_Only_Custom2__c = settings.iManage_UseOnlyCustom2__c
    );
    IManageMappingHelper.invalidateMappingCache();
  }

  private static Boolean hasLegacyMappingValues(iManageSettings__c settings) {
    return settings != null &&
      ((!String.isBlank(settings.Mapping_EntityType__c) &&
      !settings.Mapping_EntityType__c.equals(
        'litify_pm__Matter__c'
      )) ||
      String.isNotBlank(settings.Mapping_EntityClientIdObjectField__c) ||
      String.isNotBlank(settings.Mapping_ClientIdField__c) ||
      String.isNotBlank(settings.Mapping_ClientNameField__c) ||
      String.isNotBlank(settings.Mapping_EntityMatterIdObjectField__c) ||
      String.isNotBlank(settings.Mapping_MatterIdField__c) ||
      String.isNotBlank(settings.Mapping_MatterNameField__c) ||
      String.isNotBlank(settings.Mapping_WSTemplateField__c) ||
      String.isNotBlank(settings.Mapping_LibraryField__c) ||
      settings.iManage_UseOnlyCustom2__c == true);
  }

  private static List<String> getMissingRequiredFields(
    iManageSettings__c settings
  ) {
    List<String> missingFields = new List<String>();
    if (String.isBlank(settings.Mapping_EntityType__c)) {
      missingFields.add('Mapping_EntityType__c');
    }
    if (String.isBlank(settings.Mapping_EntityClientIdObjectField__c)) {
      missingFields.add('Mapping_EntityClientIdObjectField__c');
    }
    if (String.isBlank(settings.Mapping_ClientIdField__c)) {
      missingFields.add('Mapping_ClientIdField__c');
    }
    if (String.isBlank(settings.Mapping_ClientNameField__c)) {
      missingFields.add('Mapping_ClientNameField__c');
    }
    if (String.isBlank(settings.Mapping_EntityMatterIdObjectField__c)) {
      missingFields.add('Mapping_EntityMatterIdObjectField__c');
    }
    if (String.isBlank(settings.Mapping_MatterIdField__c)) {
      missingFields.add('Mapping_MatterIdField__c');
    }
    if (String.isBlank(settings.Mapping_MatterNameField__c)) {
      missingFields.add('Mapping_MatterNameField__c');
    }
    return missingFields;
  }
}

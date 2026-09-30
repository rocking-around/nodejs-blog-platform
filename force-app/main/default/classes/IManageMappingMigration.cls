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

    // Without an entity type there is no row to identify, and
    // Entity_Type__c is required on the object. The legacy values stay
    // untouched so support can inspect and reconfigure them afterwards.
    if (String.isBlank(settings.Mapping_EntityType__c)) {
      writeDiagnostic(
        'iManage mapping migration skipped: Mapping_EntityType__c is blank ' +
        'while other legacy mapping values are set. No mapping row was ' +
        'created and the legacy iManageSettings__c values were left ' +
        'unchanged. Configure the mapping in the iManage Mapping grid ' +
        'after the upgrade completes.'
      );
      return;
    }

    // The legacy configuration is transferred as-is. Completeness is not
    // judged here: an upgrade must not fail over data the previous version
    // accepted. Operations that need a given field validate it themselves.
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

  // Written independently of Verbose Logging: a skipped migration leaves no
  // other trace, and the post install script has no way to reach the admin.
  // Kept to a single DML with no queries, because a governor limit failure
  // cannot be caught and must not be provoked here.
  private static void writeDiagnostic(String message) {
    try {
      insert new Log__c(Value__c = message);
    } catch (Exception diagnosticFailure) {
      System.debug(LoggingLevel.ERROR, message);
      System.debug(LoggingLevel.ERROR, diagnosticFailure);
    }
  }
}

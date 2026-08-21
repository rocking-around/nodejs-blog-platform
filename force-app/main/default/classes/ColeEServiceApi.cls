@NamespaceAccessible
public with sharing class ColeEServiceApi {
  @NamespaceAccessible
  public static Map<String, String> getClientMatterIds(String entityId) {
    IManageMappingHelper.IManageIFrameData mappingData = IManageMappingHelper.getMappingData(
      entityId
    );

    return new Map<String, String>{
      'clientId' => normalizeIdentifier(
        mappingData == null ? null : mappingData.ClientId
      ),
      'matterId' => normalizeIdentifier(
        mappingData == null ? null : mappingData.MatterId
      )
    };
  }

  @NamespaceAccessible
  public static void logInfo(String message) {
    Logger.getInstance().info(message);
  }

  @NamespaceAccessible
  public static void logError(String message) {
    Logger.getInstance().error(message);
  }

  @NamespaceAccessible
  public static void flushLogs() {
    Logger.getInstance().Flush();
  }

  private static String normalizeIdentifier(String value) {
    return String.isBlank(value) || value == 'null' ? null : value;
  }
}


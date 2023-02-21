public class iManageUsersNotification {
  @InvocableMethod(callout=true)
  public static void notificationProcess() {
    // Send only once per month
    if (DateTime.now().day() > 8)
      return;
    LicenseService.SendOrganizationInfo(false);
  }
}

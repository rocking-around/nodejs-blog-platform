global class iManagePostInstallClass implements InstallHandler {
  global void onInstall(InstallContext context) {
    if (context.previousVersion() == null) {
      LicenseService.SendOrganizationInfo(true);
    }
  }
}

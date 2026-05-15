global class Logger extends LoggerBase {
  private static Logger instance = null;

  private Logger() {
    iManageSettings__c mc = iManageSettings__c.getOrgDefaults();
    LogObject = 'gdsi_imanage__Log__c';
    Enabled = mc.gdsi_imanage__Verbose_Logging__c;
  }

  global static Logger getInstance() {
    if (instance == null) {
      instance = new Logger();
    }
    return instance;
  }

  public override Void InsertDBLog(string message) {
    Log__c log = new Log__c();
    log.Value__c = message;
    insert log;
  }
}
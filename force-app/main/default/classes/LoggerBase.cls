global abstract class LoggerBase implements ILogger {
  protected String LogObject;
  protected Boolean Enabled;

  private String Logs = '';
  private List<String> LogsList = new List<String>();

  public Void Enable() {
    Enabled = true;
  }

  public Void Disable() {
    Enabled = false;
  }

  public Void info(String message) {
    logMessage('INFO', message, '');
  }

  public Void warn(String message) {
    logMessage('WARN', message, '');
  }

  public Void error(String message) {
    logMessage('ERROR', message, '');
  }

  public Void error(Exception ex) {
    logMessage('ERROR', ex.getMessage(), ex.getStackTraceString());
  }

  public Void error(Exception ex, String message) {
    logMessage(
      'ERROR',
      message +
      ' --- ' +
      ex.getMessage(),
      ex.getStackTraceString()
    );
  }

  public Void Flush() {
    try {
      if (Enabled)
      {
        for(Integer i = 0; i < LogsList.size(); i++)
          this.InsertDBLog(LogsList.get(i));  

        if (String.isNotEmpty(Logs))
          this.InsertDBLog(Logs);
      }
    } catch (Exception ex) {
      system.debug(ex);
    }
    Logs = '';
  }

  global abstract Void InsertDBLog(string message);

  private Void logMessage(string logType, string message, string stack) {
    String log =
      'Logger::' +
      logType +
      ' --- ' +
      message +
      ' --- ' +
      stack +
      ' --- ';
    system.debug(log);
    Integer logSize = log.length();
    if (log.length() > 131072)
      log = log.substring(0, 131068) + '...';
    if (Logs.length() + log.length() > 131072)
    {
      LogsList.add(Logs);
      Logs = '';
    }
    Logs += log;
  }
}

global interface ILogger {
  Void info(string message);
  Void warn(string message);
  Void error(string message);
  Void error(Exception ex);
  Void error(Exception ex, string message);
  Void flush();
}

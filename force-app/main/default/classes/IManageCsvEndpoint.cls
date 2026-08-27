@RestResource(urlMapping='/IManageCsv/*')
global class IManageCsvEndpoint {
  @HttpGet
  global static String doGet() {
    try {
      Logger.getInstance().info('IManageCsvEndpoint::doGet, start method.');
      RestResponse res = RestContext.response;

      // Checking is export enabled
      if (!iManageSettings__c.getOrgDefaults().Enable_CSV_Export__c) {
        res.statusCode = 400;
        Logger.getInstance()
          .warn('IManageCsvEndpoint::doGet, CSV export disabled.');
        return '';
      }

      RestRequest req = RestContext.request;
      Map<String, String> params = RestContext.request.params;

      String objectName = params.get('objectName');
      String separator = params.get('separator');
      String startDateString = params.get('startDate');
      String endDateString = params.get('endDate');

      // Checking and preparations params
      if (objectName == null || startDateString == null || separator == null) {
        res.statusCode = 400;
        Logger.getInstance()
          .warn('IManageCsvEndpoint::doGet, Missed parameters.');
        return '';
      }

      Logger.getInstance()
        .info(
          'IManageCsvEndpoint::doGet, Param->startDateString: ' +
          startDateString
        );
      Datetime startDate = DateTime.valueOf(startDateString);
      Datetime endDate = DateTime.now();

      if (endDateString != null)
        endDate = DateTime.valueOf(endDateString);

      // Get all iManage objects

      Logger.getInstance()
        .info(
          'IManageCsvEndpoint::doGet, Param->objectName: ' +
          objectName +
          ' --- --- ' +
          'IManageCsvEndpoint::doGet, Param->startDate: ' +
          startDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ') +
          ' --- --- ' +
          'IManageCsvEndpoint::doGet, Param->endDate: ' +
          endDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ')
        );

      List<IManageCsvHelper.CsvRow> data = IManageCsvHelper.getData(
        objectName,
        startDate,
        endDate
      );

      Logger.getInstance()
        .info(
          'IManageCsvEndpoint::doGet, IManageCsvHelper.getData results: ' +
          json.serialize(data)
        );

      // Get csv for all
      List<String> rows = new List<String>();

      rows.add(CreateCsvHeaders(separator));
      for (IManageCsvHelper.CsvRow row : data) {
        rows.add(CreateCsvRow(row, separator));
      }

      Logger.getInstance()
        .info(
          'IManageCsvEndpoint::doGet, Result: ' + String.join(rows, '\r\n')
        );
      return String.join(rows, '\r\n');
    } catch (Exception e) {
      Logger.getInstance().error(e, 'IManageCsvEndpoint::doGet');
      //res.statusCode = 400;
      return '';
    } finally {
      Logger.getInstance().Flush();
    }
  }

  private static String CreateCsvHeaders(String separator) {
    List<String> fields = new List<String>();
    fields.add('"ClientId"');
    fields.add('"ClientName"');
    fields.add('"MatterId"');
    fields.add('"MatterName"');
    return String.join(fields, separator);
  }

  private static String CreateCsvRow(
    IManageCsvHelper.CsvRow row,
    String separator
  ) {
    List<String> fields = new List<String>();
    fields.add('"' + row.ClientId + '"');
    fields.add('"' + row.ClientName + '"');
    fields.add('"' + row.MatterId + '"');
    fields.add('"' + row.MatterName + '"');
    return String.join(fields, separator);
  }
}
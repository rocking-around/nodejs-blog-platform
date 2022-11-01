@RestResource(urlMapping='/IManageCsv/*')
global class IManageCsvEndpoint {
  @HttpGet
  global static String doGet() {
    RestRequest req = RestContext.request;
    RestResponse res = RestContext.response;
    Map<String, String> params = RestContext.request.params;

    String objectName = params.get('objectName');
    String separator = params.get('separator');
    String startDateString = params.get('startDate');
    String endDateString = params.get('endDate');

    // Checking and preparations params
    if (objectName == null || startDateString == null || separator == null) {
      res.statusCode = 400;
      return '';
    }

    system.debug('startDateString:' + startDateString);
    Datetime startDate = DateTime.valueOf(startDateString);
    Datetime endDate = DateTime.now();

    if (endDateString != null)
      endDate = DateTime.valueOf(endDateString);

    // Get all iManage objects

    system.debug('objectName:' + objectName);
    system.debug(
      'startDate:' + startDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ')
    );
    system.debug('endDate:' + endDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));
    List<IManageCsvHelper.CsvRow> data = IManageCsvHelper.getData(
      startDate,
      endDate
    );

    system.debug(json.serialize(data));

    // Get csv for all

    List<String> rows = new List<String>();

    rows.add(CreateCsvHeaders(separator));
    for (IManageCsvHelper.CsvRow row : data) {
      rows.add(CreateCsvRow(row, separator));
    }

    return String.join(rows, '\r\n');
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

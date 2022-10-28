import { LightningElement, api } from "lwc";
import getData from "@salesforce/apex/IManageCsvHelper.getData";

const formatDate = (date) => {
  const dtf = new Intl.DateTimeFormat("en", {
    year: "numeric",
    month: "short",
    day: "2-digit"
  });
  const [{ value: mo }, , { value: da }, , { value: ye }] =
    dtf.formatToParts(date);
  return `${da}-${mo}-${ye}`;
};

const addDay = (date, days) => {
  var dt = date instanceof Date ? date : new Date(date);
  dt.setDate(dt.getDate() + days);
  return dt;
};
export default class IManageExportToCsv extends LightningElement {
  isDebug = true;
  isLoading = true;
  errorMessage;

  dateFrom;
  dateTo = formatDate(new Date());

  _recordId;
  _objectApiName;

  csvFields = [
    "Id",
    "LastModifiedDate",
    "ClientId",
    "ClientName",
    "ClientLastModifiedDate",
    "MatterId",
    "MatterName",
    "MatterLastModifiedDate"
  ];

  @api set recordId(value) {
    this._recordId = value;
    this.writeDebug(`IManageExportToCsv. Set recordId: ${this._recordId}`);
  }
  get recordId() {
    return this._recordId;
  }
  @api set objectApiName(value) {
    if (value !== this._objectApiName) {
      this._objectApiName = value;
      this.writeDebug(
        `IManageExportToCsv. Set objectApiName: ${this._objectApiName}`
      );
      this.isLoading = false;
    }
  }
  get objectApiName() {
    return this._objectApiName;
  }

  run() {
    this.isLoading = true;
    getData({
      objectApiName: null, //this.objectApiName,
      dateFrom: this.dateFrom,
      // add day because of yyyy-MM-dd 00:00:00
      dateTo: addDay(this.dateTo, 1)
    })
      .then((resp) => {
        this.writeDebug("*********** IManageExportToCsv. getData:", resp);
        return resp;
      })
      .then((data) => {
        // create csv
        const csv = this.toCsv(data);
        this.writeDebug("*********** IManageExportToCsv. CSV:", csv);
        this.downloadFile(csv, `iManage_${this.objectApiName}.csv`);
      })
      .catch((err) => {
        this.errorMessage = err.body.message || err;
        console.error(err);
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  validateDates() {
    const fromDate = new Date(this.dateFrom);
    const toDate = new Date(this.dateTo);
    if (fromDate > toDate) {
      this.errorMessage = "Date From must be greater or equal Date To";
    } else {
      this.errorMessage = undefined;
    }
  }

  onDateFromChange(evt) {
    let value = evt.target.value;
    this.writeDebug(`IManageExportToCsv. onDateFromChange: ${value}`);
    this.dateFrom = value;
    this.validateDates();
  }

  onDateToChange(evt) {
    let value = evt.target.value;
    this.writeDebug(`IManageExportToCsv. onDateToChange: ${value}`);
    this.dateTo = value;
    this.validateDates();
  }

  toCsv(data) {
    const delimiter = ",";
    const lines = [];
    let headerLine = this.csvFields.join(delimiter);
    lines.push(headerLine);
    (data || []).forEach((item) => {
      let values = Object.values(this.csvFields).map((v) => {
        return this.escapeCsvString(item[v], delimiter);
      });
      const line = values.join(delimiter);
      lines.push(line);
    });
    return lines.join("\n");
  }

  escapeCsvString(str, delimeter) {
    let result = (str + "").replaceAll('"', '""');
    if (result.indexOf(delimeter) !== -1) {
      result = `"${result}"`;
    }
    return result;
  }

  downloadFile(content, fileName) {
    let linkSource = `data:text/csv;charset=utf-8,${encodeURI(content)}`;
    let downloadLink = document.createElement("a");

    downloadLink.href = linkSource;
    downloadLink.download = fileName;
    downloadLink.click();
  }

  writeDebug() {
    if (this.isDebug) {
      console.log.apply(null, arguments);
    }
  }
}

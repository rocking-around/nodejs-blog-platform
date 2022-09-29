import { LightningElement, api, wire, track } from "lwc";

import { getRecord } from "lightning/uiRecordApi";
import GetIFrameFolder from "@salesforce/apex/iManageIFrameDialog.GetIFrameFolder";

const FIELDS = [
  "Opportunity.Name",
  "Opportunity.iManageMatter__c",
  "Opportunity.iManage_Client__c"
];

export default class IManageContainer extends LightningElement {
  @api recordId;
  @api objectApiName;
  @api height = "800px";
  @api referrerPolicy = "no-referrer";
  @api sandbox = "allow-same-origin allow-scripts";
  @api width = "100%";
  @api title = "";
  @api url = "";
  @track opportunity;
  MATTER_ID_PLACEHOLDER = "{matterId}";
  _iManageUrl = "";
  loading = true;

  @wire(getRecord, {
    recordId: "$recordId",
    fields: FIELDS
  })
  wiredOpportunity({ error, data }) {
    //console.log('wiredOpportunity', error, data);
    if (data) {
      this.opportunity = data;
      this.error = undefined;

      console.log(
        `Call GetIFrameFolder({clientId: ${this.iManageClientId}, matterId: ${this.iManageMatter}})`
      );
      GetIFrameFolder({
        clientId: this.iManageClientId,
        matterId: this.iManageMatter
      })
        .then((resp) => {
          console.log("*********** GetIFrameFolder:", resp);
          this._iManageUrl = resp;
        })
        .catch((err) => {
          this.error = err.body.message || err;
          console.error(err);
        })
        .finally(() => {
          this.loading = false;
        });
    } else if (error) {
      this.error = error;
      this.record = undefined;
      this.loading = false;
    }
  }

  get showIFrame() {
    return this.iManageMatter && this.iManageUrl.length;
  }

  get iManageUrl() {
    return this.iManageMatter && this._iManageUrl
      ? this._iManageUrl //this.url.replaceAll(this.MATTER_ID_PLACEHOLDER, this.iManageMatter)
      : "";
  }

  get iManageMatter() {
    if (this.opportunity) {
      return this.opportunity.fields.iManageMatter__c.value;
    }
    return "";
  }

  get iManageClientId() {
    if (this.opportunity) {
      return this.opportunity.fields.iManage_Client__c.value;
    }
    return "";
  }
}

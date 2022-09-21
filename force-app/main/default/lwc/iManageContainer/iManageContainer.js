import { LightningElement, api, wire, track } from "lwc";

import { getRecord } from "lightning/uiRecordApi";

const FIELDS = ["Opportunity.Name", "Opportunity.iManageMatter__c"];

export default class IManageContainer extends LightningElement {
  @api recordId;
  @api objectApiName;
  @api height = "500px";
  @api referrerPolicy = "no-referrer";
  @api sandbox = "";
  @api width = "100%";
  @api title = "";
  @api url = "";
  @track opportunity;
  MATTER_ID_PLACEHOLDER = "{matterId}";

  @wire(getRecord, {
    recordId: "$recordId",
    fields: FIELDS
  })
  wiredOpportunity({ error, data }) {
    //console.log('wiredOpportunity', error, data);
    if (data) {
      this.opportunity = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.record = undefined;
    }
  }

  get showIFrame() {
    return this.iManageMatter && this.iManageUrl.length;
  }

  get iManageUrl() {
    return this.iManageMatter
      ? this.url.replaceAll(this.MATTER_ID_PLACEHOLDER, this.iManageMatter)
      : "";
  }

  get iManageMatter() {
    if (this.opportunity) {
      return this.opportunity.fields.iManageMatter__c.value;
    }
    return "";
  }
}

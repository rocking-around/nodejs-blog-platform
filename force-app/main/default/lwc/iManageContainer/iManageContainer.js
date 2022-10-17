import { LightningElement, api } from "lwc";

// import messageEmptyClientOrMatter from '@salesforce/label/c.imanage_message_codes_empty_client_or_matter';
import GetIFrameFolder from "@salesforce/apex/iManageIFrameDialog.GetIFrameFolder";

export default class IManageContainer extends LightningElement {
  @api recordId;
  @api height = "1000px";
  @api referrerPolicy = "no-referrer";
  @api sandbox = "allow-same-origin allow-scripts allow-forms";
  @api width = "100%";
  @api title = "";
  @api url = "";
  _iManageUrl = "";
  loading = true;

  // label = {
  //   messageEmptyClientOrMatter
  // };

  connectedCallback() {
    console.log(`Call GetIFrameFolder({recordId: ${this.recordId}})`);
    GetIFrameFolder({
      entityId: this.recordId
    })
      .then((resp) => {
        console.log("*********** GetIFrameFolder:", JSON.stringify(resp));
        if(resp.Error != null && resp.Error.ErrorMessage != null)
          this.error = resp.Error.ErrorMessage;

        else
          this._iManageUrl = resp.Data;
      })
      .catch((err) => {
        this.error = err.body.message || err;
        console.error(err);
      })
      .finally(() => {
        this.loading = false;
      });
  }

  get showIFrame() {
    return this.recordId && this.iManageUrl.length;
  }

  get iManageUrl() {
    return this.recordId && this._iManageUrl ? this._iManageUrl : "";
  }
}
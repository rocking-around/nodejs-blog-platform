import { LightningElement, api } from "lwc";

/*
import messageEmptyClientOrMatter from "@salesforce/label/c.imanage_message_codes_empty_client_or_matter";
import messageEmptyCustomResource from "@salesforce/label/c.imanage_message_codes_empty_custom_resource";
import messageFolderNorFound from "@salesforce/label/c.imanage_message_codes_folder_not_found";
import messageUnathorized from "@salesforce/label/c.imanage_message_codes_unauthorized";
import licenseNotFound from "@salesforce/label/c.imanage_message_codes_license_not_found";
import licenseExpired from "@salesforce/label/c.imanage_message_codes_license_expired";
*/
import GetIFrameFolder from "@salesforce/apex/iManageIFrameDialog.GetIFrameFolder";

export default class IManageContainer extends LightningElement {
  @api recordId;
  @api height = "1000px";
  @api referrerPolicy = "no-referrer";
  @api sandbox =
    "allow-same-origin allow-scripts allow-forms allow-top-navigation-to-custom-protocols allow-top-navigation-by-user-activation allow-top-navigation allow-popups";
  @api width = "100%";
  @api title = "";
  @api url = "";
  _iManageUrl = "";
  loading = true;

  error = {}; //code, message
  errors = {
    /*EMPTY_CLIENT_OR_MATTER: messageEmptyClientOrMatter,
    UNAUTHORIZED: messageUnathorized,
    EMPTY_CUSTOM_RESOURCE: messageEmptyCustomResource,
    FOLDER_NOT_FOUND: messageFolderNorFound,
    LICENSE_NOT_FOUND: licenseNotFound,
    LICENSE_EXPIRED: licenseExpired*/
  };

  connectedCallback() {
    console.log(`Call GetIFrameFolder({recordId: ${this.recordId}})`);
    GetIFrameFolder({
      entityId: this.recordId
    })
      .then((resp) => {
        console.log("*********** GetIFrameFolder:", JSON.stringify(resp));
        /*if (resp.Error != null && resp.Error.ErrorMessage != null) {
          this.error = {
            code: resp.Error.Code,
            mesage: resp.Error.ErrorMessage
          };
        } else */
        this._iManageUrl = resp;
      })
      .catch((err) => {
        this.error = {
          code: "",
          message: err.body.message || err || "Unexpected error"
        };
        console.error(err);
      })
      .finally(() => {
        this.loading = false;
      });
  }

  handleRefreshClick() {
    this.loading = true;
    this._iManageUrl = "";
    this.connectedCallback();
    //window.location.reload();
  }

  get showIFrame() {
    return this.recordId && this.iManageUrl.length;
  }

  get iManageUrl() {
    return this.recordId && this._iManageUrl ? this._iManageUrl : "";
  }

  get errorMessage() {
    const { code, message } = this.error;
    return code ? this.errors[code] : message;
  }

  get notFound() {
    return this._iManageUrl && !this._iManageUrl.includes("&start=");
  }
}

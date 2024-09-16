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
    "allow-same-origin allow-scripts allow-forms allow-top-navigation-to-custom-protocols allow-top-navigation-by-user-activation allow-top-navigation allow-popups allow-downloads";
  @api width = "100%";
  @api title = "";
  @api url = "";
  _iManageUrl = "";
  loading = true;
  loaded = false;

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
        this.loaded = true;
      });
  }

  handleRefreshClick() {
    this.loading = true;
    this.loaded = false;
    this._iManageUrl = "";
    this.connectedCallback();
    //window.location.reload();
  }

  handleOpenNewTabClick() {
    var workspaceId = this.getQueryVariable(this._iManageUrl, "start");
    if (workspaceId)
    {
        var baseUrl = this._iManageUrl.substring(0, this._iManageUrl.indexOf("/work/partner-apps/"));
        var lib = workspaceId.split('!')[0];
        var url = baseUrl + "/work/web/r/libraries/" + lib + "/workspaces/" + workspaceId;
        window.open(url, '_blank')
    }   
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

  get found() {
    return this._iManageUrl.includes("&start=");
  }

  getQueryVariable(query, variable) {
    var vars = query.split('&');
    for (var i = 0; i < vars.length; i++) {
        var pair = vars[i].split('=');
        if (decodeURIComponent(pair[0]) == variable) {
            return decodeURIComponent(pair[1]);
        }
    }
  }

}

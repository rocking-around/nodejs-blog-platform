import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";

export default class FilePreview extends NavigationMixin(LightningElement) {
  @api recordId;
  @api label;

  clickHandle() {
    // console.log("+++++++ FilePreview.clickHandle ", this.recordId, e);
    // const event = new CustomEvent("customtypea", {
    //   composed: true,
    //   bubbles: true,
    //   cancelable: true,
    //   detail: {
    //     recordId: this.recordId
    //   }
    // });

    // this.dispatchEvent(event);

    this[NavigationMixin.Navigate]({
      type: "standard__namedPage",
      attributes: {
        pageName: "filePreview"
      },
      state: {
        selectedRecordId: this.recordId
      }
    });
  }
}
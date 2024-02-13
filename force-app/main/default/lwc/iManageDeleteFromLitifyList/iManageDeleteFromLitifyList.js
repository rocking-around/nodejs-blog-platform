import { LightningElement } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import deleteFromLitifyList from "@salesforce/apex/ConfigurationHelper.DeleteFromLitifyList";

export default class IManageDeleteFromLitifyList extends LightningElement {
    clientCode = '';
    matterCode = '';
    isInputNotEmpty = false;
    showSpinner = false;

    onClientCodeChanged(e) {
        this.clientCode = e.detail.value;
        this.calcIsInputNotEmpty();
    }

    onMatterCodeChanged(e) {
        this.matterCode = e.detail.value;
        this.calcIsInputNotEmpty();
    }
   
    calcIsInputNotEmpty()
    {
        this.isInputNotEmpty =  this.clientCode && this.matterCode;
    }

    async deleteClick() {
        this.showSpinner = true;
        try {

            var result = await deleteFromLitifyList(
                {
                clientCode: this.clientCode, 
                matterCode: this.matterCode
                })

            var isError = false;
            if (result.substr(0,6) == "Error:")
            {
                result = result.substr(6);
                isError = true;
            }

            var title = isError ? "Error" : "Delete...";
            var variant = isError ? "error" : "success";

            this.dispatchEvent(
                new ShowToastEvent({
                  title: title,
                  message: result,
                  variant: variant
                })
              );

            console.log(result);
        } catch (error) {
            console.error(error);
        } finally {
            this.showSpinner = false;
        }
    }
}
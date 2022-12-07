import { LightningElement, api } from "lwc";

export default class IManageMappingEditor extends LightningElement {
  _objectApiName = undefined;

  @api set objectApiName(value) {
    if (value !== this._objectApiName) {
      this._objectApiName = value;
      console.log(
        `IManageMappingEditor. Set objectApiName: ${this._objectApiName}`
      );
    }
  }
  get objectApiName() {
    return this._objectApiName;
  }
}

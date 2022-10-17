import { LightningElement, api, track } from "lwc";
import getMapping from "@salesforce/apex/IManageMappingHelper.getMapping";
import getFields from "@salesforce/apex/IManageMappingHelper.getFields";
import saveMapping from "@salesforce/apex/IManageMappingHelper.saveMapping";
import editTemplate from "./editTemplate.html";
import viewTemplate from "./viewTemplate.html";

export default class IManageMappingEditor extends LightningElement {
  isLoading = true;
  isSaving = false;
  initialized = false;

  defaultIManageMapping = {
    EntityType__c: "litify_pm__Matter__c",
    MatterIdField__c: null,
    EntityMatterIdObjectField__c: null,
    ClientIdField__c: null,
    EntityClientIdObjectField__c: null
  };

  @track iManageMapping;

  @track isEdit = false;
  _recordId;
  _objectApiName;
  @track entityId;

  matterIdObjectOptionsExt;
  @track matterIdObjectOptions;
  clientIdObjectOptionsExt;
  @track clientIdObjectOptions;
  @track matterIdObjectFieldOptions;
  @track clientIdObjectFieldOptions;

  entityType = {
    fieldLabel: "Matter",
    fieldName: "litify_pm__Matter__c",
    fieldType: "REFERENCE",
    referenceTo: ["litify_pm__Matter__c"]
  };

  @api set recordId(value) {
    this._recordId = value;
    console.log(`IManageMappingEditor. Set recordId: ${this._recordId}`);
  }
  get recordId() {
    return this._recordId;
  }
  @api set objectApiName(value) {
    if (value !== this._objectApiName) {
      this._objectApiName = value;
      console.log(
        `IManageMappingEditor. Set objectApiName: ${this._objectApiName}`
      );
      this.initComponent();
    }
  }
  get objectApiName() {
    return this._objectApiName;
  }

  connectedCallback() {
    console.log("*********** IManageMappingEditor. connectedCallback:");
    this.initComponent();
  }

  render() {
    return this.isEdit ? editTemplate : viewTemplate;
  }

  initComponent() {
    console.log("*********** IManageMappingEditor. initComponent:");
    if (!this.isEdit) {
      this.getIManageMapping();
    } else {
      this.initEditor(this.iManageMapping).finally(() => {
        this.isLoading = false;
      });
    }
  }

  get loading() {
    return this.isLoading || !this.objectApiName;
  }

  get matterIdObject() {
    let opt = (this.matterIdObjectOptions || []).find(
      (x) => x.value === this.iManageMapping.EntityMatterIdObjectField__c
    );
    return opt ? opt.label : this.iManageMapping.EntityMatterIdObjectField__c;
  }

  get matterIdField() {
    let opt = (this.matterIdObjectFieldOptions || []).find(
      (x) => x.value === this.iManageMapping.MatterIdField__c
    );
    return opt ? opt.label : this.iManageMapping.MatterIdField__c;
  }

  get clientIdObject() {
    let opt = (this.clientIdObjectOptions || []).find(
      (x) => x.value === this.iManageMapping.EntityClientIdObjectField__c
    );
    return opt ? opt.label : this.iManageMapping.EntityClientIdObjectField__c;
  }

  get clientIdField() {
    let opt = (this.clientIdObjectFieldOptions || []).find(
      (x) => x.value === this.iManageMapping.ClientIdField__c
    );
    return opt ? opt.label : this.iManageMapping.ClientIdField__c;
  }

  getIManageMapping() {
    if (!this.objectApiName) {
      return;
    }
    getMapping({ objectApiName: this.objectApiName })
      .then((resp) => {
        console.log(
          "*********** IManageMappingEditor. getIManageMapping:",
          resp
        );
        if (resp === null) {
          this.isEdit = true;
          this.iManageMapping = { ...this.defaultIManageMapping };
        } else {
          this.iManageMapping = resp;
        }
        return this.initEditor(this.iManageMapping);
      })
      .catch((err) => {
        this.error = err.body.message || err;
        console.error(err);
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  initEditor(mapping = {}) {
    console.log("*********** IManageMappingEditor. initEditor: ", mapping);

    return new Promise((resolve, reject) => {
      let entityMatterIdObjectField = this.getValueOrDefault(
        mapping.EntityMatterIdObjectField__c,
        this.defaultIManageMapping.EntityType__c
      );
      let entityClientIdObjectField = this.getValueOrDefault(
        mapping.EntityClientIdObjectField__c,
        this.defaultIManageMapping.EntityType__c
      );

      Promise.all([
        this.loadIdObjectOptions(
          "matterIdObjectOptions",
          this.defaultIManageMapping.EntityType__c
        ),
        this.loadIdObjectOptions(
          "clientIdObjectOptions",
          this.defaultIManageMapping.EntityType__c
        )
      ])
        .then(([matterResponse, clientResponse]) => {
          if (matterResponse) {
            let objType = matterResponse.find(
              (x) => x.fieldName === entityMatterIdObjectField
            );
            if (objType && objType.referenceTo) {
              this.loadIdObjFieldOptions(
                "matterIdObjectFieldOptions",
                objType.referenceTo[0]
              );
            }
          }
          if (clientResponse) {
            let objType = clientResponse.find(
              (x) => x.fieldName === entityClientIdObjectField
            );
            if (objType && objType.referenceTo) {
              this.loadIdObjFieldOptions(
                "clientIdObjectFieldOptions",
                objType.referenceTo[0]
              );
            }
          }
          resolve();
        })
        .catch((error) => reject(error));
    });
  }

  save() {
    console.log("*********** IManageMappingEditor. save:", this.iManageMapping);
    this.isSaving = true;
    saveMapping({ mapping: this.iManageMapping })
      .then((resp) => {
        console.log("*********** IManageMappingEditor. save:", resp);
      })
      .catch((err) => {
        this.error = err.body.message || err;
        console.error(err);
      })
      .finally(() => {
        this.isSaving = false;
      });
  }

  cancel() {
    this.isEdit = false;
  }

  edit() {
    this.isEdit = true;
    this.initEditor(this.iManageMapping);
  }

  loadIdObjectOptions(name, parentObjName) {
    console.log(
      `*********** IManageMappingEditor.loadIdObjectOptions ('${name}', '${parentObjName}');`
    );
    return new Promise((resolve, reject) => {
      getFields({
        objectName: parentObjName,
        fieldTypes: ["REFERENCE"]
      })
        .then((resp) => {
          console.log(
            "*********** IManageMappingEditor. loadIdObjectOptions:",
            resp
          );
          let data = [...[this.entityType], ...(resp || [])];
          this[`${name}Ext`] = data.filter(
            (x) => x.referenceTo && !(x.referenceTo.length > 1)
          );
          this[name] = Object.entries(this[`${name}Ext`]).map(
            ([, { fieldLabel, fieldName }]) => ({
              label: fieldLabel,
              value: fieldName
            })
          );
          resolve(this[`${name}Ext`]);
        })
        .catch((err) => {
          this.error = err.body.message || err;
          console.error(err);
          reject();
        })
        .finally(() => {});
    });
  }

  loadIdObjFieldOptions(name, objName) {
    console.log(
      `*********** IManageMappingEditor.loadMatterIdObjFields('${name}', '${objName}');`
    );
    getFields({
      objectName: objName,
      fieldTypes: ["ID", "STRING"]
    })
      .then((resp) => {
        console.log(
          "*********** IManageMappingEditor. loadIdObjFieldOptions:",
          resp
        );
        this[name] = Object.entries(resp).map(
          ([, { fieldLabel, fieldName }]) => ({
            label: fieldLabel,
            value: fieldName
          })
        );
      })
      .catch((err) => {
        this.error = err.body.message || err;
        console.error(err);
      })
      .finally(() => {});
  }

  onMatterIdObjectChanged(evt) {
    let value = evt.target.value;
    console.log(
      "*********** IManageMappingEditor. onMatterIdObjectChanged: " + value
    );
    let objType = this.matterIdObjectOptionsExt.find(
      (x) => x.fieldName === value
    );
    if (objType && objType.referenceTo) {
      this.iManageMapping = {
        ...this.iManageMapping,
        ...{ EntityMatterIdObjectField__c: objType.fieldName }
      };
      this.loadIdObjFieldOptions(
        "matterIdObjectFieldOptions",
        objType.referenceTo[0]
      );
    }
    this.iManageMapping = {
      ...this.iManageMapping,
      ...{ MatterIdField__c: undefined }
    };
  }

  onClientIdObjectChanged(evt) {
    let value = evt.target.value;
    console.log(
      "*********** IManageMappingEditor. onClientIdObjectChanged: " + value
    );
    let objType = this.matterIdObjectOptionsExt.find(
      (x) => x.fieldName === value
    );
    if (objType && objType.referenceTo) {
      this.iManageMapping = {
        ...this.iManageMapping,
        ...{ EntityClientIdObjectField__c: objType.fieldName }
      };
      this.loadIdObjFieldOptions(
        "clientIdObjectFieldOptions",
        objType.referenceTo[0]
      );
    }
    this.iManageMapping = {
      ...this.iManageMapping,
      ...{ ClientIdField__c: undefined }
    };
  }

  onMatterIdObjectFieldChanged(evt) {
    let value = evt.target.value;
    console.log(
      "*********** IManageMappingEditor. onMatterIdObjectFieldChanged: " + value
    );
    this.iManageMapping = {
      ...this.iManageMapping,
      ...{ MatterIdField__c: value }
    };
  }

  onClientIdObjectFieldChanged(evt) {
    let value = evt.target.value;
    console.log(
      "*********** IManageMappingEditor. onClientIdObjectFieldChanged: " + value
    );
    this.iManageMapping = {
      ...this.iManageMapping,
      ...{ ClientIdField__c: value }
    };
  }

  getValueOrDefault(obj, defaultValue) {
    return obj && obj !== null ? obj : defaultValue;
  }
}

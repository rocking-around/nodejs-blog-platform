import { LightningElement, api, track } from "lwc";
import getMapping from "@salesforce/apex/IManageMappingHelper.getMapping";
import getFields from "@salesforce/apex/IManageMappingHelper.getFields";
import saveMapping from "@salesforce/apex/IManageMappingHelper.saveMapping";
import editTemplate from "./editTemplate.html";
import viewTemplate from "./viewTemplate.html";
import mappingEntityTypeField from "@salesforce/schema/IManageMapping__c.EntityType__c";
import mappingMatterIdField from "@salesforce/schema/IManageMapping__c.MatterIdField__c";
import mappingMatterNameField from "@salesforce/schema/IManageMapping__c.MatterNameField__c";
import mappingEntityMatterIdObjectField from "@salesforce/schema/IManageMapping__c.EntityMatterIdObjectField__c";
import mappingClientIdField from "@salesforce/schema/IManageMapping__c.ClientIdField__c";
import mappingClientNameField from "@salesforce/schema/IManageMapping__c.ClientNameField__c";
import mappingEntityClientIdObjectField from "@salesforce/schema/IManageMapping__c.EntityClientIdObjectField__c";

export default class IManageMappingEditor extends LightningElement {
  isDebug = true;
  isLoading = true;
  isSaving = false;
  initialized = false;
  changed = false;

  defaultIManageMapping = {
    [mappingEntityTypeField.fieldApiName]: null,
    [mappingMatterIdField.fieldApiName]: null,
    [mappingMatterNameField.fieldApiName]: null,
    [mappingEntityMatterIdObjectField.fieldApiName]: null,
    [mappingClientIdField.fieldApiName]: null,
    [mappingClientNameField.fieldApiName]: null,
    [mappingEntityClientIdObjectField.fieldApiName]: null
  };

  @track iManageMapping;
  @track iManageMappingEdit = {};

  @track isEdit = false;
  _recordId;
  _objectApiName;
  @track entityId;

  matterIdObjectOptionsExt;
  @track matterIdObjectOptions;
  clientIdObjectOptionsExt;
  @track clientIdObjectOptions;
  @track matterIdObjectFieldOptions;
  @track matterNameObjectFieldOptions;
  @track clientIdObjectFieldOptions;
  @track clientNameObjectFieldOptions;

  entityType = {};

  @api set recordId(value) {
    this._recordId = value;
    this.writeDebug(`IManageMappingEditor. Set recordId: ${this._recordId}`);
  }
  get recordId() {
    return this._recordId;
  }
  @api set objectApiName(value) {
    if (value !== this._objectApiName) {
      this._objectApiName = value;
      this.writeDebug(
        `IManageMappingEditor. Set objectApiName: ${this._objectApiName}`
      );

      this.defaultIManageMapping[mappingEntityTypeField.fieldApiName] =
        this._objectApiName;
      this.entityType = {
        fieldLabel: "This object",
        fieldName: this._objectApiName,
        fieldType: "REFERENCE",
        referenceTo: [this._objectApiName]
      };

      this.initComponent();
    }
  }
  get objectApiName() {
    return this._objectApiName;
  }

  connectedCallback() {
    this.writeDebug("*********** IManageMappingEditor. connectedCallback:");
    this.initComponent();
  }

  render() {
    return this.isEdit ? editTemplate : viewTemplate;
  }

  initComponent() {
    this.writeDebug("*********** IManageMappingEditor. initComponent:");
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
    let val =
      this.iManageMapping[mappingEntityMatterIdObjectField.fieldApiName];
    let opt = (this.matterIdObjectOptions || []).find((x) => x.value === val);
    return opt ? opt.label : val;
  }

  get matterIdField() {
    let val = this.iManageMapping[mappingMatterIdField.fieldApiName];
    let opt = (this.matterIdObjectFieldOptions || []).find(
      (x) => x.value === val
    );
    return opt ? opt.label : val;
  }

  get matterNameField() {
    let val = this.iManageMapping[mappingMatterNameField.fieldApiName];
    let opt = (this.matterNameObjectFieldOptions || []).find(
      (x) => x.value === val
    );
    return opt ? opt.label : val;
  }

  get clientIdObject() {
    let val =
      this.iManageMapping[mappingEntityClientIdObjectField.fieldApiName];
    let opt = (this.clientIdObjectOptions || []).find((x) => x.value === val);
    return opt ? opt.label : val;
  }

  get clientIdField() {
    let val = this.iManageMapping[mappingClientIdField.fieldApiName];
    let opt = (this.clientIdObjectFieldOptions || []).find(
      (x) => x.value === val
    );
    return opt ? opt.label : val;
  }

  get clientNameField() {
    let val = this.iManageMapping[mappingClientNameField.fieldApiName];
    let opt = (this.clientNameObjectFieldOptions || []).find(
      (x) => x.value === val
    );
    return opt ? opt.label : val;
  }

  get editEntityTypeField() {
    return this.iManageMappingEdit[mappingEntityTypeField.fieldApiName];
  }
  get editMatterIdField() {
    return this.iManageMappingEdit[mappingMatterIdField.fieldApiName];
  }
  get editMatterNameField() {
    return this.iManageMappingEdit[mappingMatterNameField.fieldApiName];
  }
  get editEntityMatterIdObjectField() {
    return this.iManageMappingEdit[
      mappingEntityMatterIdObjectField.fieldApiName
    ];
  }
  get editClientIdField() {
    return this.iManageMappingEdit[mappingClientIdField.fieldApiName];
  }
  get editClientNameField() {
    return this.iManageMappingEdit[mappingClientNameField.fieldApiName];
  }
  get editEntityClientIdObjectField() {
    return this.iManageMappingEdit[
      mappingEntityClientIdObjectField.fieldApiName
    ];
  }

  getIManageMapping() {
    if (!this.objectApiName) {
      return;
    }
    getMapping({ objectApiName: this.objectApiName })
      .then((resp) => {
        this.writeDebug(
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
    this.writeDebug("*********** IManageMappingEditor. initEditor: ", mapping);

    return new Promise((resolve, reject) => {
      let entityMatterIdObjectField = this.getValueOrDefault(
        mapping[mappingEntityMatterIdObjectField.fieldApiName],
        this.defaultIManageMapping[mappingEntityTypeField.fieldApiName]
      );
      let entityClientIdObjectField = this.getValueOrDefault(
        mapping[mappingEntityClientIdObjectField.fieldApiName],
        this.defaultIManageMapping[mappingEntityTypeField.fieldApiName]
      );

      Promise.all([
        this.loadIdObjectOptions(
          "matterIdObjectOptions",
          this.defaultIManageMapping[mappingEntityTypeField.fieldApiName]
        ),
        this.loadIdObjectOptions(
          "clientIdObjectOptions",
          this.defaultIManageMapping[mappingEntityTypeField.fieldApiName]
        )
      ])
        .then(([matterResponse, clientResponse]) => {
          if (matterResponse) {
            let objType = matterResponse.find(
              (x) => x.fieldName === entityMatterIdObjectField
            );
            if (objType && objType.referenceTo) {
              this.loadIdObjFieldOptions(
                ["matterIdObjectFieldOptions", "matterNameObjectFieldOptions"],
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
                ["clientIdObjectFieldOptions", "clientNameObjectFieldOptions"],
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
    this.writeDebug(
      "*********** IManageMappingEditor. save:",
      this.iManageMappingEdit
    );
    this.isSaving = true;
    saveMapping({ mapping: this.iManageMappingEdit })
      .then((resp) => {
        this.writeDebug("*********** IManageMappingEditor. save:", resp);
        this.changed = false;
        this.iManageMapping = { ...this.iManageMappingEdit };
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
    this.changed = false;
    this.iManageMappingEdit = {};
  }

  edit() {
    this.isEdit = true;
    this.iManageMappingEdit = { ...this.iManageMapping };
    this.initEditor(this.iManageMappingEdit);
  }

  loadIdObjectOptions(name, parentObjName) {
    this.writeDebug(
      `*********** IManageMappingEditor.loadIdObjectOptions ('${name}', '${parentObjName}');`
    );
    return new Promise((resolve, reject) => {
      getFields({
        objectName: parentObjName,
        fieldTypes: ["REFERENCE"]
      })
        .then((resp) => {
          this.writeDebug(
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

  loadIdObjFieldOptions(names, objName) {
    this.writeDebug(
      `*********** IManageMappingEditor.loadMatterIdObjFields('${names}', '${objName}');`
    );
    getFields({
      objectName: objName,
      fieldTypes: ["ID", "STRING"]
    })
      .then((resp) => {
        this.writeDebug(
          "*********** IManageMappingEditor. loadIdObjFieldOptions:",
          resp
        );
        names.forEach((name) => {
          this[name] = Object.entries(resp).map(
            ([, { fieldLabel, fieldName }]) => ({
              label: fieldLabel,
              value: fieldName
            })
          );
        });
      })
      .catch((err) => {
        this.error = err.body.message || err;
        console.error(err);
      })
      .finally(() => {});
  }

  onMatterIdObjectChanged(evt) {
    let value = evt.target.value;
    this.writeDebug(
      "*********** IManageMappingEditor. onMatterIdObjectChanged: " + value
    );
    let objType = this.matterIdObjectOptionsExt.find(
      (x) => x.fieldName === value
    );
    if (objType && objType.referenceTo) {
      this.iManageMappingEdit = {
        ...this.iManageMappingEdit,
        ...{
          [mappingEntityMatterIdObjectField.fieldApiName]: objType.fieldName
        }
      };
      this.loadIdObjFieldOptions(
        ["matterIdObjectFieldOptions", "matterNameObjectFieldOptions"],
        objType.referenceTo[0]
      );
    }
    this.iManageMappingEdit = {
      ...this.iManageMappingEdit,
      ...{
        [mappingMatterIdField.fieldApiName]: undefined,
        [mappingMatterNameField.fieldApiName]: undefined
      }
    };
    this.changed = true;
  }

  onClientIdObjectChanged(evt) {
    let value = evt.target.value;
    this.writeDebug(
      "*********** IManageMappingEditor. onClientIdObjectChanged: " + value
    );
    let objType = this.matterIdObjectOptionsExt.find(
      (x) => x.fieldName === value
    );
    if (objType && objType.referenceTo) {
      this.iManageMappingEdit = {
        ...this.iManageMappingEdit,
        ...{
          [mappingEntityClientIdObjectField.fieldApiName]: objType.fieldName
        }
      };
      this.loadIdObjFieldOptions(
        ["clientIdObjectFieldOptions", "clientNameObjectFieldOptions"],
        objType.referenceTo[0]
      );
    }
    this.iManageMappingEdit = {
      ...this.iManageMappingEdit,
      ...{
        [mappingClientIdField.fieldApiName]: undefined,
        [mappingClientNameField.fieldApiName]: undefined
      }
    };
    this.changed = true;
  }

  onMatterIdObjectFieldChanged(evt) {
    let value = evt.target.value;
    this.writeDebug(
      "*********** IManageMappingEditor. onMatterIdObjectFieldChanged: " + value
    );
    this.iManageMappingEdit = {
      ...this.iManageMappingEdit,
      ...{ [mappingMatterIdField.fieldApiName]: value }
    };
    this.changed = true;
  }

  onMatterNameObjectFieldChanged(evt) {
    let value = evt.target.value;
    this.writeDebug(
      "*********** IManageMappingEditor. onMatterNameObjectFieldChanged: " +
        value
    );
    this.iManageMappingEdit = {
      ...this.iManageMappingEdit,
      ...{ [mappingMatterNameField.fieldApiName]: value }
    };
    this.changed = true;
  }

  onClientIdObjectFieldChanged(evt) {
    let value = evt.target.value;
    this.writeDebug(
      "*********** IManageMappingEditor. onClientIdObjectFieldChanged: " + value
    );
    this.iManageMappingEdit = {
      ...this.iManageMappingEdit,
      ...{ [mappingClientIdField.fieldApiName]: value }
    };
    this.changed = true;
  }

  onClientNameObjectFieldChanged(evt) {
    let value = evt.target.value;
    this.writeDebug(
      "*********** IManageMappingEditor. onClientNameObjectFieldChanged: " +
        value
    );
    this.iManageMappingEdit = {
      ...this.iManageMappingEdit,
      ...{ [mappingClientNameField.fieldApiName]: value }
    };
    this.changed = true;
  }

  getValueOrDefault(obj, defaultValue) {
    return obj && obj !== null ? obj : defaultValue;
  }

  writeDebug(value) {
    if (this.isDebug) {
      console.log(value);
    }
  }
}

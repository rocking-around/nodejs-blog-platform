import { LightningElement, api, track, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { loadStyle } from "lightning/platformResourceLoader";
import AppCSS from "@salesforce/resourceUrl/AppCSS";
import getMapping from "@salesforce/apex/IManageMappingHelper.getMapping";
import getAllSObjectsMetadata from "@salesforce/apex/IManageMappingHelper.getAllSObjectsMetadata";
import getFields from "@salesforce/apex/IManageMappingHelper.getFields";
import saveMapping from "@salesforce/apex/IManageMappingHelper.saveMapping";
import getSObjectMetadata from "@salesforce/apex/IManageMappingHelper.getSObjectMetadata";
import editTemplate from "./editTemplate.html";
import viewTemplate from "./viewTemplate.html";
import isCsvExportEnabled from "@salesforce/apex/IManageCsvHelper.isCsvExportEnabled";

const mappingEntityTypeField = { fieldApiName: "EntityType" };
const mappingMatterIdField = { fieldApiName: "MatterIdField" };
const mappingMatterNameField = { fieldApiName: "MatterNameField" };
const mappingEntityMatterIdObjectField = {
  fieldApiName: "EntityMatterIdObjectField"
};
const mappingClientIdField = { fieldApiName: "ClientIdField" };
const mappingClientNameField = { fieldApiName: "ClientNameField" };
const mappingEntityClientIdObjectField = {
  fieldApiName: "EntityClientIdObjectField"
};
const mappingWsTemplateField = { fieldApiName: "WsTemplateField" };
const mappingLibraryField = { fieldApiName: "LibraryField" };
const mappingUseOnlyCustom2 = { fieldApiName: "UseOnlyCustom2" };

export default class IManageMappingEditor extends LightningElement {
  isDebug = false;
  isLoading = true;
  isSaving = false;
  isInitialized = false;
  changed = false;

  defaultIManageMapping = {
    [mappingEntityTypeField.fieldApiName]: null,
    [mappingMatterIdField.fieldApiName]: null,
    [mappingMatterNameField.fieldApiName]: null,
    [mappingEntityMatterIdObjectField.fieldApiName]: null,
    [mappingClientIdField.fieldApiName]: null,
    [mappingClientNameField.fieldApiName]: null,
    [mappingEntityClientIdObjectField.fieldApiName]: null,
    [mappingWsTemplateField.fieldApiName]: null,
    [mappingLibraryField.fieldApiName]: null,
    [mappingUseOnlyCustom2.fieldApiName]: null,
  };

  @track iManageMapping;
  @track iManageMappingEdit = {};

  @track isEdit = false;
  _entityType;
  @track entityId;

  entityTypeFieldOptionsExt;
  @track entityTypeFieldOptions;

  matterIdObjectOptionsExt;
  @track matterIdObjectOptions;
  clientIdObjectOptionsExt;
  @track clientIdObjectOptions;
  @track matterIdObjectFieldOptions;
  @track matterNameObjectFieldOptions;
  @track clientIdObjectFieldOptions;
  @track clientNameObjectFieldOptions;
  @track wsTemplateObjectFieldOptions;
  @track libraryObjectFieldOptions;
  
  entityType = {};

  @wire(isCsvExportEnabled)
  _isCsvExportEnabled;

  @api set entityApiName(value) {
    if (value !== this._entityType) {
      this.setEntityApiName(value);
    }
  }
  get entityApiName() {
    return this._entityType;
  }

  get csvExportEnabled() {
    return !!(this._isCsvExportEnabled || {}).data;
  }

  connectedCallback() {
    this.initComponent();
  }

  async renderedCallback() {
    if (this.isInitialized) {
      return;
    }
    try {
      await loadStyle(this, AppCSS);
    } catch (err) {
      console.log(`Can't load AppCSS`, err);
    }
  }

  render() {
    return this.isEdit ? editTemplate : viewTemplate;
  }

  setEntityApiName(value) {
    this._entityType = value;
    this.writeDebug(
      `IManageMappingEditor. Set objectApiName: ${this._entityType}`
    );

    this.defaultIManageMapping[mappingEntityTypeField.fieldApiName] =
      this._entityType;

    this.loadEntityTypeMetadata(value, () => this.initComponent());
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
    return this.isLoading || !this.entityApiName;
  }

  get entityTypeField() {
    //mappingEntityTypeField
    let val = this.iManageMapping[mappingEntityTypeField.fieldApiName];
    //TODO: entityTypeFieldOptions
    let opt = (this.entityTypeFieldOptions || []).find((x) => x.value === val);
    return opt ? opt.label : val;
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

  get wsTemplateIdField() {
    let val = this.iManageMapping[mappingWsTemplateField.fieldApiName];
    let opt = (this.wsTemplateObjectFieldOptions || []).find(
      (x) => x.value === val
    );
    return opt ? opt.label : val;
  }

  get libraryField() {
    let val = this.iManageMapping[mappingLibraryField.fieldApiName];
    let opt = (this.libraryObjectFieldOptions || []).find(
      (x) => x.value === val
    );
    return opt ? opt.label : val;
  }

  get useOnlyCustom2() {
    return  this.iManageMapping[mappingUseOnlyCustom2.fieldApiName];
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
  get editWsTemplateField() {
    return this.iManageMappingEdit[mappingWsTemplateField.fieldApiName];
  }
  get editLibraryField() {
    return this.iManageMappingEdit[mappingLibraryField.fieldApiName];
  }

  get editUseOnlyCustom2() {
    return this.iManageMappingEdit[mappingUseOnlyCustom2.fieldApiName];
  }

getIManageMapping() {
    if (!this.entityApiName) {
      return;
    }
    getMapping({ objectApiName: this.entityApiName })
      .then((resp) => {
        this.writeDebug(
          "*********** IManageMappingEditor. getIManageMapping:",
          resp
        );
        console.log("getIManageMapping");
        console.log(resp);
        if (resp === null) {
          this.isEdit = true;
          this.iManageMapping = { ...this.defaultIManageMapping };
        } else {
          this.iManageMapping = resp;
        }
        return this.initEditor(this.iManageMapping);
      })
      .catch((err) => {
        this.error = err.body ? err.body.message || err : err;
        console.error(err);
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  loadEntityTypeMetadata(objectApiName, callback) {
    getSObjectMetadata({
      objApiName: objectApiName
    })
      .then((objMetadata) => {
        this.writeDebug(
          "*********** IManageMappingEditor. getSObjectMetadata. Result: ",
          JSON.parse(JSON.stringify(objMetadata))
        );
        this.entityType = {
          fieldLabel: objMetadata.label,
          fieldName: this._entityType,
          fieldType: "REFERENCE",
          referenceTo: [this._entityType]
        };
        callback();
      })
      .catch(this.handleErrors);
  }

  initEditor(mapping = {}) {
    this.writeDebug(
      "*********** IManageMappingEditor. initEditor: ",
      JSON.parse(JSON.stringify(mapping))
    );

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
        this.loadEntityTypeFieldOptions(),
        this.loadIdObjectOptions(
          "matterIdObjectOptions",
          this.defaultIManageMapping[mappingEntityTypeField.fieldApiName]
        ),
        this.loadIdObjectOptions(
          "clientIdObjectOptions",
          this.defaultIManageMapping[mappingEntityTypeField.fieldApiName]
        ),
        this.loadIdObjFieldOptions(
          [{name: "wsTemplateObjectFieldOptions", required: false}],
          this.defaultIManageMapping[mappingEntityTypeField.fieldApiName],
          ['STRING']
        ),
        this.loadIdObjFieldOptions(
          [{name: "libraryObjectFieldOptions", required: false}],
          this.defaultIManageMapping[mappingEntityTypeField.fieldApiName],
          ['STRING']
        )
      ])
        .then(([entityTypeResponse, matterResponse, clientResponse]) => {
          if (entityTypeResponse) {
            //debugger;
          }

          if (matterResponse) {
            let objType = matterResponse.find(
              (x) => x.fieldName === entityMatterIdObjectField
            );
            if (objType && objType.referenceTo) {
              this.loadIdObjFieldOptions(
                [
                  {name: "matterIdObjectFieldOptions", required: true},
                  {name: "matterNameObjectFieldOptions", required: true}
                ],
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
                [
                  {name: "clientIdObjectFieldOptions", required: true},
                  {name: "clientNameObjectFieldOptions", required: true}
                ],
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
    saveMapping({
      mapping: this.iManageMappingEdit
    })
      .then((resp) => {
        this.writeDebug("*********** IManageMappingEditor. save:", resp);
        this.changed = false;
        this.iManageMapping = { ...this.iManageMappingEdit };

        this.dispatchEvent(
          new ShowToastEvent({
            title: "Save...",
            message: "iManage mapping saved successfuly",
            variant: "success"
          })
        );
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

  async edit() {
    this.isEdit = true;
    this.iManageMappingEdit = { ...this.iManageMapping };
    try {
      await this.initEditor(this.iManageMappingEdit);
    } catch (error) {
      if (error?.body?.message.includes(`Invalid sobject provided`)) {
        this.handleErrors(
          "Invalid Salesforce entity type provided. Contact the Administrator."
        );
      } else {
        this.handleErrors(error);
      }
    }
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

          const _sortedData = Object.entries(this[`${name}Ext`]).map(
            ([, { fieldLabel, fieldName }]) => ({
              label: fieldLabel,
              value: fieldName
            })
          );
          _sortedData.sort((a, b) => {
            // entityType should be the first option
            if (a.label === this.entityType.fieldLabel) {
              return -1;
            } else if (b.label === this.entityType.fieldLabel) {
              return 1;
            }
            return a.label.localeCompare(b.label, undefined, {
              sensitivity: "base"
            });
          });
          this[name] = _sortedData;
          resolve(this[`${name}Ext`]);
        })
        .catch((err) => {
          reject(err);
        })
        .finally(() => {});
    });
  }

  loadEntityTypeFieldOptions() {
    this.writeDebug(
      `*********** IManageMappingEditor.loadEntityTypeFieldOptions();`
    );
    return new Promise((resolve, reject) => {
      getAllSObjectsMetadata()
        .then((resp) => {
          this.writeDebug(
            "*********** IManageMappingEditor. loadEntityTypeFieldOptions:",
            resp
          );
          let data = [...(resp || [])];
          data.sort((a, b) =>
            a.label.localeCompare(b.label, undefined, { sensitivity: "base" })
          );
          this.entityTypeFieldOptionsExt = data.filter((x) => x);
          this.entityTypeFieldOptions = Object.entries(
            this.entityTypeFieldOptionsExt
          ).map(([, { label, name }]) => ({
            label,
            value: name
          }));
          resolve(this.entityTypeFieldOptionsExt);
        })
        .catch((err) => {
          reject(err);
        })
        .finally(() => {});
    });
  }

  loadIdObjFieldOptions(optionsSettings, objName, fieldTypes) {
    this.writeDebug(
      `*********** IManageMappingEditor.loadMatterIdObjFields('${optionsSettings}', '${objName}', ${fieldTypes});`
    );
    getFields({
      objectName: objName,
      fieldTypes: fieldTypes || ["ID", "STRING", "INTEGER", "DOUBLE", "LONG", "PICKLIST"]
    })
      .then((resp) => {
        this.writeDebug(
          "*********** IManageMappingEditor. loadIdObjFieldOptions:",
          resp
        );
        optionsSettings.forEach(({name, required}) => {
          let _data = Object.entries(resp).map(
            ([, { fieldLabel, fieldName }]) => ({
              label: fieldLabel,
              value: fieldName
            })
          );
          _data.sort((a, b) =>
            a.label.localeCompare(b.label, undefined, { sensitivity: "base" })
          );
          if (!required) {
            _data = [...[{label: '--None--', value: ''}], ..._data];
          }
          this[name] = _data;
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
        [
          {name: "matterIdObjectFieldOptions", required: true},
          {name: "matterNameObjectFieldOptions", required: true}
        ],
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
        [
          {name: "clientIdObjectFieldOptions", required: true},
          {name: "clientNameObjectFieldOptions", required: true}
        ],
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

  onWsTemplateFieldChanged(evt) {
    let value = evt.target.value;
    this.writeDebug(
      "*********** IManageMappingEditor. onWsTemplateFieldChanged: " +
        value
    );
    this.iManageMappingEdit = {
      ...this.iManageMappingEdit,
      ...{ [mappingWsTemplateField.fieldApiName]: (value.length === 0 ? undefined : value) }
    };
    this.changed = true;
  }

  onLlibraryFieldChanged(evt) {
    let value = evt.target.value;
    this.writeDebug(
      "*********** IManageMappingEditor. onLlibraryFieldChanged: " +
        value
    );
    this.iManageMappingEdit = {
      ...this.iManageMappingEdit,
      ...{ [mappingLibraryField.fieldApiName]: (value.length === 0 ? undefined : value) }
    };
    this.changed = true;
  }

  
  onUseOnlyCustom2Changed(evt) {
    const { checked } = evt.detail;
    
    this.writeDebug(
      "*********** IManageMappingEditor. onUseOnlyCustom2Changed: " +
        checked
    );
    this.iManageMappingEdit = {
      ...this.iManageMappingEdit,
      ...{ [mappingUseOnlyCustom2.fieldApiName]: checked }
    };
    this.changed = true;
  }

  onEntityTypeFieldChanged(evt) {
    let value = evt.target.value;
    this.writeDebug(
      "*********** IManageMappingEditor. onEntityTypeFieldChanged: " + value
    );
    this.iManageMappingEdit = {
      ...this.iManageMappingEdit,
      ...{
        [mappingEntityTypeField.fieldApiName]: value,
        [mappingMatterIdField.fieldApiName]: undefined,
        [mappingMatterNameField.fieldApiName]: undefined,
        [mappingEntityMatterIdObjectField.fieldApiName]: undefined,
        [mappingClientIdField.fieldApiName]: undefined,
        [mappingClientNameField.fieldApiName]: undefined,
        [mappingEntityClientIdObjectField.fieldApiName]: undefined,
        [mappingWsTemplateField.fieldApiName]: undefined,
        [mappingLibraryField.fieldApiName]: undefined
      }
    };
    this.changed = true;

    this.setEntityApiName(value);
  }

  getValueOrDefault(obj, defaultValue) {
    return obj && obj !== null ? obj : defaultValue;
  }

  writeDebug() {
    if (this.isDebug) {
      console.log.apply(null, arguments);
    }
  }

  handleErrors(err) {
    console.error(err);
    this.dispatchEvent(
      new ShowToastEvent({
        title: "Error",
        message: err.message || err?.body?.message || err,
        variant: "error"
      })
    );
  }
}
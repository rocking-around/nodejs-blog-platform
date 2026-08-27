import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import LightningConfirm from "lightning/confirm";
import getMappings from "@salesforce/apex/IManageMappingHelper.getMappings";
import getAllSObjectsMetadata from "@salesforce/apex/IManageMappingHelper.getAllSObjectsMetadata";
import getFields from "@salesforce/apex/IManageMappingHelper.getFields";
import saveMappingConfiguration from "@salesforce/apex/IManageMappingHelper.saveMappingConfiguration";
import deleteMappingConfiguration from "@salesforce/apex/IManageMappingHelper.deleteMappingConfiguration";
import gridTemplate from "./iManageMappingConfiguration.html";
import recordTemplate from "./recordTemplate.html";

const VALUE_FIELD_TYPES = [
  "ID",
  "STRING",
  "INTEGER",
  "DOUBLE",
  "LONG",
  "PICKLIST"
];
const METADATA_FIELD_TYPES = [...VALUE_FIELD_TYPES, "REFERENCE"];

const EMPTY_MAPPING = {
  MappingId: null,
  EntityType: "",
  EntityClientIdObjectField: "",
  ClientIdField: "",
  ClientNameField: "",
  EntityMatterIdObjectField: "",
  MatterIdField: "",
  MatterNameField: "",
  WsTemplateField: "",
  LibraryField: "",
  UseOnlyCustom2: false
};

export default class IManageMappingConfiguration extends LightningElement {
  @api entityApiName;

  rows = [];
  entityOptions = [];
  entityLabels = new Map();
  fieldCache = new Map();
  isLoading = true;
  isPreparingRow = false;
  nextKey = 1;
  optionLoadVersions = new Map();

  connectedCallback() {
    this.initialize();
  }

  render() {
    return this.entityApiName ? recordTemplate : gridTemplate;
  }

  get hasRows() {
    return this.rows.length > 0;
  }

  get disableAdd() {
    return (
      this.isPreparingRow ||
      this.rows.some((row) => row.isEditing) ||
      (this.entityApiName && this.rows.length > 0)
    );
  }

  async initialize() {
    this.isLoading = true;
    try {
      const [mappings, entities] = await Promise.all([
        getMappings(),
        getAllSObjectsMetadata()
      ]);
      this.entityOptions = (entities || [])
        .map((entity) => ({ label: entity.label, value: entity.name }))
        .sort(this.sortOptions);
      this.entityLabels = new Map(
        this.entityOptions.map((option) => [option.value, option.label])
      );
      const visibleMappings = this.entityApiName
        ? (mappings || []).filter(
            (mapping) => mapping.EntityType === this.entityApiName
          )
        : mappings || [];
      this.rows = await Promise.all(
        visibleMappings.map((mapping) => this.prepareRow(mapping, false))
      );
    } catch (error) {
      this.showError(error);
    } finally {
      this.isLoading = false;
    }
  }

  async prepareRow(mapping, isEditing) {
    const row = {
      ...EMPTY_MAPPING,
      ...mapping,
      key: mapping.MappingId || `new-${this.nextKey++}`,
      isEditing,
      isPersisted: !!mapping.MappingId,
      isSaving: false,
      clientObjectOptions: [],
      matterObjectOptions: [],
      clientFieldOptions: [],
      matterFieldOptions: [],
      entityFieldOptions: []
    };
    await this.loadRowOptions(row);
    row.entityOptions = this.availableEntityOptions(row.EntityType);
    return this.decorateRow(row);
  }

  availableEntityOptions(currentEntityType) {
    const usedEntityTypes = new Set(
      this.rows
        .map((row) => row.EntityType)
        .filter((entityType) => entityType && entityType !== currentEntityType)
    );
    return this.entityOptions.filter(
      (option) =>
        (!this.entityApiName || option.value === this.entityApiName) &&
        !usedEntityTypes.has(option.value)
    );
  }

  async loadRowOptions(row) {
    if (!row.EntityType) {
      return;
    }

    const entityFields = await this.loadFields(row.EntityType);
    const objectOptions = [
      {
        label: this.entityLabels.get(row.EntityType) || row.EntityType,
        value: row.EntityType,
        objectApiName: row.EntityType
      },
      ...entityFields
        .filter((field) => field.referenceTo?.length === 1)
        .map((field) => ({
          label: field.fieldLabel,
          value: field.fieldName,
          objectApiName: field.referenceTo[0]
        }))
    ].sort(this.sortOptions);

    row.clientObjectOptions = objectOptions;
    row.matterObjectOptions = objectOptions;
    row.entityFieldOptions = this.toFieldOptions(entityFields, false);

    const clientObject = this.resolveObjectApiName(
      row.EntityClientIdObjectField,
      objectOptions
    );
    const matterObject = this.resolveObjectApiName(
      row.EntityMatterIdObjectField,
      objectOptions
    );

    row.clientFieldOptions = clientObject
      ? this.toFieldOptions(await this.loadFields(clientObject), false)
      : [];
    row.matterFieldOptions = matterObject
      ? this.toFieldOptions(await this.loadFields(matterObject), false)
      : [];
  }

  loadFields(objectName) {
    if (!this.fieldCache.has(objectName)) {
      this.fieldCache.set(
        objectName,
        getFields({ objectName, fieldTypes: METADATA_FIELD_TYPES }).catch(
          (error) => {
            this.fieldCache.delete(objectName);
            throw error;
          }
        )
      );
    }
    return this.fieldCache.get(objectName);
  }

  toFieldOptions(fields, required) {
    const options = (fields || [])
      .filter((field) => VALUE_FIELD_TYPES.includes(field.fieldType))
      .map((field) => ({ label: field.fieldLabel, value: field.fieldName }))
      .sort(this.sortOptions);
    return required ? options : [{ label: "--None--", value: "" }, ...options];
  }

  resolveObjectApiName(value, options) {
    return options.find((option) => option.value === value)?.objectApiName;
  }

  get tableScrollClass() {
    return this.rows.some((row) => row.isEditing)
      ? "table-scroll table-scroll_editing slds-p-horizontal_medium"
      : "table-scroll slds-p-horizontal_medium";
  }

  decorateRow(row) {
    const labelFor = (options, value) =>
      options.find((option) => option.value === value)?.label || value || "";
    return {
      ...row,
      entityLabel: labelFor(this.entityOptions, row.EntityType),
      clientObjectLabel: labelFor(
        row.clientObjectOptions,
        row.EntityClientIdObjectField
      ),
      clientIdLabel: labelFor(row.clientFieldOptions, row.ClientIdField),
      clientNameLabel: labelFor(row.clientFieldOptions, row.ClientNameField),
      matterObjectLabel: labelFor(
        row.matterObjectOptions,
        row.EntityMatterIdObjectField
      ),
      matterIdLabel: labelFor(row.matterFieldOptions, row.MatterIdField),
      matterNameLabel: labelFor(row.matterFieldOptions, row.MatterNameField),
      templateLabel: labelFor(row.entityFieldOptions, row.WsTemplateField),
      libraryLabel: labelFor(row.entityFieldOptions, row.LibraryField),
      custom2Label: row.UseOnlyCustom2 ? "Yes" : "No"
    };
  }

  async addRow() {
    if (this.disableAdd) {
      return;
    }
    this.isPreparingRow = true;
    try {
      const entityType = this.entityApiName || "";
      const row = await this.prepareRow(
        {
          ...EMPTY_MAPPING,
          EntityType: entityType,
          EntityClientIdObjectField: entityType,
          EntityMatterIdObjectField: entityType
        },
        true
      );
      this.rows = [...this.rows, row];
    } finally {
      this.isPreparingRow = false;
    }
  }

  editRow(event) {
    const key = event.currentTarget.dataset.key;
    if (this.rows.some((row) => row.isEditing && row.key !== key)) {
      return;
    }
    this.rows = this.rows.map((row) => ({
      ...row,
      entityOptions: this.availableEntityOptions(row.EntityType),
      isEditing: row.key === key
    }));
  }

  cancelEdit(event) {
    const key = event.currentTarget.dataset.key;
    const row = this.rows.find((item) => item.key === key);
    if (!row?.isPersisted) {
      this.rows = this.rows.filter((item) => item.key !== key);
      return;
    }
    this.initialize();
  }

  async deleteRow(event) {
    const key = event.currentTarget.dataset.key;
    if (this.rows.some((row) => row.isEditing && row.key !== key)) {
      return;
    }
    const row = this.rows.find((item) => item.key === key);
    if (!row) {
      return;
    }
    if (!row.isPersisted) {
      this.rows = this.rows.filter((item) => item.key !== key);
      return;
    }

    const confirmed = await LightningConfirm.open({
      label: "Delete Mapping",
      message: `Delete the mapping for ${row.entityLabel}?`,
      variant: "headerless"
    });
    if (!confirmed) {
      return;
    }

    this.isLoading = true;
    try {
      await deleteMappingConfiguration({ mappingId: row.MappingId });
      this.rows = this.rows.filter((item) => item.key !== key);
      this.showToast("Mapping deleted", "success");
    } catch (error) {
      this.showError(error);
    } finally {
      this.isLoading = false;
    }
  }

  async fieldChanged(event) {
    const key = event.target.dataset.key;
    const field = event.target.dataset.field;
    const index = this.rows.findIndex((row) => row.key === key);
    if (index < 0) {
      return;
    }

    const row = { ...this.rows[index] };
    row[field] =
      event.target.type === "checkbox"
        ? event.target.checked
        : event.detail.value;

    const reloadOptions = [
      "EntityType",
      "EntityClientIdObjectField",
      "EntityMatterIdObjectField"
    ].includes(field);

    if (field === "EntityType") {
      Object.assign(row, {
        EntityClientIdObjectField: row.EntityType,
        ClientIdField: "",
        ClientNameField: "",
        EntityMatterIdObjectField: row.EntityType,
        MatterIdField: "",
        MatterNameField: "",
        WsTemplateField: "",
        LibraryField: "",
        clientObjectOptions: [],
        matterObjectOptions: [],
        clientFieldOptions: [],
        matterFieldOptions: [],
        entityFieldOptions: []
      });
    } else if (field === "EntityClientIdObjectField") {
      row.ClientIdField = "";
      row.ClientNameField = "";
      row.clientFieldOptions = [];
    } else if (field === "EntityMatterIdObjectField") {
      row.MatterIdField = "";
      row.MatterNameField = "";
      row.matterFieldOptions = [];
    }

    this.rows = this.rows.map((item) => {
      return item.key === key ? this.decorateRow(row) : item;
    });
    if (!reloadOptions) {
      return;
    }

    const version = (this.optionLoadVersions.get(key) || 0) + 1;
    this.optionLoadVersions.set(key, version);
    await this.loadRowOptions(row);
    if (this.optionLoadVersions.get(key) !== version) {
      return;
    }

    const optionFields = [
      "clientObjectOptions",
      "matterObjectOptions",
      "clientFieldOptions",
      "matterFieldOptions",
      "entityFieldOptions"
    ];
    this.rows = this.rows.map((item) => {
      if (item.key !== key) {
        return item;
      }
      const updated = { ...item };
      optionFields.forEach((optionField) => {
        updated[optionField] = row[optionField];
      });
      updated.entityOptions = this.availableEntityOptions(updated.EntityType);
      return this.decorateRow(updated);
    });
  }

  async saveRow(event) {
    const key = event.currentTarget.dataset.key;
    const row = this.rows.find((item) => item.key === key);
    if (!row || !this.validateRow(key)) {
      return;
    }

    this.rows = this.rows.map((item) => ({
      ...item,
      isSaving: item.key === key
    }));
    try {
      const saved = await saveMappingConfiguration({
        mapping: this.toMapping(row)
      });
      const savedRow = await this.prepareRow(saved, false);
      this.rows = this.rows.map((item) => (item.key === key ? savedRow : item));
      this.showToast("iManage mapping saved", "success");
    } catch (error) {
      this.showError(error);
      this.rows = this.rows.map((item) => ({ ...item, isSaving: false }));
    }
  }

  validateRow(key) {
    return [...this.template.querySelectorAll(`[data-key="${key}"]`)]
      .filter((input) => typeof input.reportValidity === "function")
      .reduce((valid, input) => input.reportValidity() && valid, true);
  }

  toMapping(row) {
    return Object.keys(EMPTY_MAPPING).reduce((mapping, field) => {
      mapping[field] = row[field];
      return mapping;
    }, {});
  }

  sortOptions(a, b) {
    return a.label.localeCompare(b.label, undefined, { sensitivity: "base" });
  }

  showToast(message, variant) {
    this.dispatchEvent(
      new ShowToastEvent({ title: "iManage Mapping", message, variant })
    );
  }

  showError(error) {
    const message = error?.body?.message || error?.message || String(error);
    this.showToast(message, "error");
  }
}

class FormField {
  name;
  value;
  initialValue;

  constructor(name, initialValue) {
    this.name = name;
    this.initialValue = initialValue;
    this.value = initialValue;
  }

  get changed() {
    return this.value !== this.initialValue;
  }

  changeField(fieldValue) {
    this.value = fieldValue;
  }

  reset() {
    this.value = this.initialValue;
  }
}

class SettingsForm {
  _delimeter = ":";
  edit = false;
  fields = undefined;
  prefix = undefined;

  constructor(prefix, source) {
    this.prefix = prefix;

    const data = {};
    for (const [key, value] of Object.entries(source)) {
      const [fieldPrefix, fieldName] = key.split(this._delimeter);
      if (fieldPrefix === prefix) {
        const field = new FormField(fieldName, value);
        data[fieldName] = field;
      }
    }
    this.fields = data;
  }

  get changed() {
    if (!this.fields) {
      return false;
    }

    return Object.entries(this.fields).some(([, field]) => {
      return field.changed;
    });
  }

  reset() {
    for (const [, field] of Object.entries(this.fields)) {
      field.reset();
    }
  }

  setValue(name, value) {
    if (Object.keys(this.fields).some((f) => f === name)) {
      this.fields[name].changeField(value);
    }
  }

  getChanged(params = {}) {
    const result = this.selectFields(
      (f) => f.changed,
      (f) => f.value,
      (f) => {
        return params.fieldNameWithPrefix ? `${this.prefix}:${f.name}` : f.name;
      }
    );
    return result;
  }

  selectFields(fieldFilter, valueSelector, nameSelector) {
    const result = Object.entries(this.fields).reduce((o, [, field]) => {
      if (fieldFilter(field)) {
        const fieldName = nameSelector(field);
        return { ...o, ...{ [fieldName]: valueSelector(field) } };
      }
      return o;
    }, {});
    return result;
  }
}

export class GeneralSettingsForm extends SettingsForm {
  constructor(data) {
    super("general", data);
  }
}

export class IManageDocumentSettingsForm extends SettingsForm {
  constructor(data) {
    super("iManageDocuments", data);
  }
}

export const defaultGeneralSettings = {
  "general:Url": undefined,
  "general:MatterField": undefined,
  "general:Client_Id": undefined,
  "general:ClientField": undefined,
  "general:Enable_CSV_Export": false,
  "general:Verbose_Logging": false
};

export const DEFAULT_IMANAGE_MAPPING_ENTITY = "litify_pm__Matter__c";

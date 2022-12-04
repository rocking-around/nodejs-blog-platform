// const uuidv4 = () => {
//     return ([1e7]+-1e3+-4e3+-8e3+-1e11).replace(/[018]/g, c =>
//       (c ^ crypto.getRandomValues(new Uint8Array(1))[0] & 15 >> c / 4).toString(16)
//     );
//   }

// class Publisher {
//   listeners = new Map();
//   id = uuidv4();

//   on(eventName, eventHandler) {
//     if (!this.listeners.has(eventName)) {
//       this.listeners.set(eventName, []);
//     }
//     this.listeners.get(eventName).push(eventHandler);
//     console.log(`on event "${eventName}": publisherId = ${this.id}`);
//   }

//   off(eventName, eventHandler) {
//     let listeners = this.listeners.get(eventName);
//     if (listeners) {
//       this.listeners.set(
//         eventName,
//         eventHandler
//           ? listeners.filter((value) => !(value === eventHandler))
//           : []
//       );
//     }
//     console.log(`off event "${eventName}": publisherId = ${this.id}`);
//   }

//   trigger(eventName, ...args) {
//     console.log(`trigger event "${eventName}": publisherId = ${this.id}`, args);
//     let listeners = this.listeners.get(eventName);
//     if (listeners && listeners.length) {
//       listeners.forEach((listener) => {
//         listener(...args);
//       });
//     }
//   }
// }

class FormField /* extends Publisher*/ {
  name;
  value;
  initialValue;

  constructor(name, initialValue) {
    //super();
    this.name = name;
    this.initialValue = initialValue;
    this.value = initialValue;
    // this.onChange = (e) => {
    //   const isCkeckbox = e.detail.checked !== undefined;
    //   this.changeField(
    //     this.name,
    //     isCkeckbox ? e.detail.checked : e.detail.value
    //   );
    //   //this.changeField(this.name, e.target.value);
    // };
  }

  get changed() {
    return this.value !== this.initialValue;
  }

  changeField(fieldValue) {
    this.value = fieldValue;
    //this.trigger("onChanged", this.name, this.value);
  }

  reset() {
    this.value = this.initialValue;
    //this.trigger("onReset", this.name, this.value);
  }
}

class SettingsForm /*extends Publisher */ {
  _delimeter = ":";
  edit = false;
  fields = undefined;
  prefix = undefined;

  constructor(prefix, source) {
    //super();
    this.prefix = prefix;

    const data = {};
    for (const [key, value] of Object.entries(source)) {
      const [fieldPrefix, fieldName] = key.split(this._delimeter);
      if (fieldPrefix === prefix) {
        const field = new FormField(fieldName, value);
        //field.on("onChanged", () => this.trigger("onChanged", this.changed));
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
    //this.trigger("onChanged", this.changed);
  }

  setValue(name, value) {
    if (Object.keys(this.fields).some((f) => f === name)) {
      this.fields[name].changeField(value);
    }
  }

  getChanged(params = {}) {
    const result = Object.entries(this.fields).reduce((o, [, field]) => {
      const fieldName = params.fieldNameWithPrefix
        ? `${this.prefix}:${field.name}`
        : field.name;
      if (field.changed) {
        return { ...o, ...{ [fieldName]: field.value } };
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

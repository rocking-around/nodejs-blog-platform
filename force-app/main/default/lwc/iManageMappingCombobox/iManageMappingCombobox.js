import { LightningElement, api } from "lwc";

const MENU_MAX_HEIGHT = 240;
const VIEWPORT_MARGIN = 8;

export default class IManageMappingCombobox extends LightningElement {
  @api label;
  @api options = [];
  @api placeholder = "Select an Option";
  @api required = false;

  _value = "";

  isOpen = false;
  hasError = false;
  dropdownStyle = "";
  shouldPosition = false;

  @api
  get value() {
    return this._value;
  }

  set value(value) {
    this._value = value || "";
  }

  connectedCallback() {
    window.addEventListener("click", this.handleOutsideClick);
    window.addEventListener("resize", this.closeDropdown);
  }

  disconnectedCallback() {
    window.removeEventListener("click", this.handleOutsideClick);
    window.removeEventListener("resize", this.closeDropdown);
  }

  renderedCallback() {
    if (!this.isOpen || !this.shouldPosition) {
      return;
    }
    this.shouldPosition = false;
    this.positionDropdown();
  }

  get selectedLabel() {
    return (
      this.options.find((option) => option.value === this._value)?.label || ""
    );
  }

  get displayValue() {
    return this.selectedLabel || this.placeholder;
  }

  get triggerClass() {
    return `trigger slds-combobox__input slds-input_faux${
      this.hasError ? " trigger_error" : ""
    }`;
  }

  get decoratedOptions() {
    return this.options.map((option) => {
      const isSelected = option.value === this._value;
      return {
        ...option,
        isSelected,
        className: `option${isSelected ? " option_selected" : ""}`
      };
    });
  }

  stopPropagation(event) {
    event.stopPropagation();
  }

  toggleDropdown() {
    if (this.isOpen) {
      this.closeDropdown();
      return;
    }
    this.hasError = false;
    this.shouldPosition = true;
    this.isOpen = true;
  }

  positionDropdown() {
    const trigger = this.template.querySelector(".trigger");
    if (!trigger) {
      return;
    }

    const rect = trigger.getBoundingClientRect();
    const width = Math.min(
      rect.width * 2,
      window.innerWidth - VIEWPORT_MARGIN * 2
    );
    const left = Math.min(
      Math.max(VIEWPORT_MARGIN, rect.left),
      window.innerWidth - width - VIEWPORT_MARGIN
    );
    const spaceBelow = window.innerHeight - rect.bottom - VIEWPORT_MARGIN;
    const spaceAbove = rect.top - VIEWPORT_MARGIN;
    const openBelow = spaceBelow >= Math.min(MENU_MAX_HEIGHT, spaceAbove);
    const maxHeight = Math.max(
      96,
      Math.min(MENU_MAX_HEIGHT, openBelow ? spaceBelow : spaceAbove)
    );
    const verticalPosition = openBelow
      ? `top:${rect.bottom}px;`
      : `bottom:${window.innerHeight - rect.top}px;`;

    this.dropdownStyle =
      `left:${left}px;width:${width}px;max-height:${maxHeight}px;` +
      verticalPosition;
  }

  selectOption(event) {
    const value = event.currentTarget.dataset.value;
    this._value = value;
    this.closeDropdown();
    this.dispatchEvent(
      new CustomEvent("change", {
        detail: { value },
        bubbles: true,
        composed: true
      })
    );
  }

  handleTriggerKeydown(event) {
    if (["Enter", " ", "ArrowDown"].includes(event.key)) {
      event.preventDefault();
      this.toggleDropdown();
    }
  }

  handleDropdownKeydown(event) {
    if (event.key === "Escape") {
      event.preventDefault();
      this.closeDropdown();
      this.template.querySelector(".trigger")?.focus();
    }
  }

  handleOutsideClick = () => {
    this.closeDropdown();
  };

  closeDropdown = () => {
    this.isOpen = false;
    this.dropdownStyle = "";
    this.shouldPosition = false;
  };

  @api
  reportValidity() {
    this.hasError = this.required && !this._value;
    return !this.hasError;
  }

  @api
  focus() {
    this.template.querySelector(".trigger")?.focus();
  }
}

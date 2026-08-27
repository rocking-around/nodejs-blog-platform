import { createElement } from "lwc";
import IManageMappingCombobox from "c/iManageMappingCombobox";

const flushPromises = () => Promise.resolve();

const createCombobox = () => {
  const element = createElement("c-i-manage-mapping-combobox", {
    is: IManageMappingCombobox
  });
  element.label = "Entity";
  element.value = "Opportunity";
  element.options = [
    { label: "Opportunity", value: "Opportunity" },
    {
      label: "Authorization Form Data Use Share",
      value: "AuthorizationFormDataUseShare"
    }
  ];
  document.body.appendChild(element);
  return element;
};

describe("c-i-manage-mapping-combobox", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("opens a double-width viewport-positioned dropdown", async () => {
    const element = createCombobox();
    await flushPromises();
    const trigger = element.shadowRoot.querySelector(".trigger");
    trigger.getBoundingClientRect = jest.fn(() => ({
      bottom: 132,
      height: 32,
      left: 100,
      right: 260,
      top: 100,
      width: 160
    }));

    trigger.click();
    await flushPromises();
    await flushPromises();

    const dropdown = element.shadowRoot.querySelector(".dropdown");
    expect(dropdown).not.toBeNull();
    expect(dropdown.getAttribute("style")).toContain("left:100px");
    expect(dropdown.getAttribute("style")).toContain("width:320px");
    expect(dropdown.getAttribute("style")).toContain("max-height:240px");
  });

  it("selects an option and closes without retaining open styling", async () => {
    const element = createCombobox();
    const handler = jest.fn();
    element.addEventListener("change", handler);
    await flushPromises();

    element.shadowRoot.querySelector(".trigger").click();
    await flushPromises();
    element.shadowRoot
      .querySelector('[data-value="AuthorizationFormDataUseShare"]')
      .click();
    await flushPromises();

    expect(handler).toHaveBeenCalledWith(
      expect.objectContaining({
        detail: { value: "AuthorizationFormDataUseShare" }
      })
    );
    expect(element.shadowRoot.querySelector(".dropdown")).toBeNull();
    expect(element.shadowRoot.querySelector(".trigger").textContent).toContain(
      "Authorization Form Data Use Share"
    );
  });

  it("closes on an outside click and validates a required value", async () => {
    const element = createCombobox();
    element.required = true;
    element.value = "";
    await flushPromises();

    element.shadowRoot.querySelector(".trigger").click();
    await flushPromises();
    window.dispatchEvent(new MouseEvent("click"));
    await flushPromises();

    expect(element.shadowRoot.querySelector(".dropdown")).toBeNull();
    expect(element.reportValidity()).toBe(false);
    await flushPromises();
    expect(element.shadowRoot.querySelector('[role="alert"]')).not.toBeNull();
  });
});

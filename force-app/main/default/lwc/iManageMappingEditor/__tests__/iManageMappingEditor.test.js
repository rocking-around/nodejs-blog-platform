import { createElement } from "lwc";
import IManageMappingEditor from "c/iManageMappingEditor";

describe("c-i-manage-mapping-editor", () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("passes the record object type to the mapping grid", () => {
    const element = createElement("c-i-manage-mapping-editor", {
      is: IManageMappingEditor
    });
    element.objectApiName = "Opportunity";
    document.body.appendChild(element);
    const grid = element.shadowRoot.querySelector(
      "c-i-manage-mapping-configuration"
    );
    expect(grid).not.toBeNull();
    expect(grid.entityApiName).toBe("Opportunity");
  });
});

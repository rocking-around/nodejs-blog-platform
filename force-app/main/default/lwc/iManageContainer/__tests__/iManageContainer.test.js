import { createElement } from "lwc";
import IManageContainer from "c/iManageContainer";
import { getRecord } from "lightning/uiRecordApi";
const mockGetOpportunityRecord = require("./data/getOpportunityRecord.json");

describe("c-i-manage-container", () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("iFrame shoul be visible", () => {
    // Arrange
    const element = createElement("c-i-manage-container", {
      is: IManageContainer
    });

    element.url = "http://host.com?m={matterId}";
    element.opportunity = {
      fields: {
        iManageMatter__c: {
          value: "IM-TEST-01"
        }
      }
    };
    // Act
    document.body.appendChild(element);

    // Emit mock record into the wired field
    getRecord.emit(mockGetOpportunityRecord);

    // Resolve a promise to wait for a rerender of the new content.
    return Promise.resolve().then(() => {
      const iFrame = element.shadowRoot.querySelector("iframe");
      expect(iFrame).not.toBeNull();
    });
  });

  it("iFrame shoul be invisible", () => {
    // Arrange
    const element = createElement("c-i-manage-container", {
      is: IManageContainer
    });

    element.url = "http://host.com?m={matterId}";

    // Act
    document.body.appendChild(element);

    // Resolve a promise to wait for a rerender of the new content.
    return Promise.resolve().then(() => {
      const iFrame = element.shadowRoot.querySelector("iframe");
      expect(iFrame).toBeNull();
    });
  });
});

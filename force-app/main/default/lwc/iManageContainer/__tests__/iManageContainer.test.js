import { createElement } from "lwc";
import IManageContainer from "c/iManageContainer";
import GetIFrameFolder from "@salesforce/apex/iManageIFrameDialog.GetIFrameFolder";
import messageEmptyClientOrMatter from "@salesforce/label/c.imanage_message_codes_empty_client_or_matter";

// Mocking imperative Apex method call
jest.mock(
  "@salesforce/apex/iManageIFrameDialog.GetIFrameFolder",
  () => {
    return {
      default: jest.fn()
    };
  },
  { virtual: true }
);

const APEX_GetIFrameFolder_ERROR = {
  Error: {
    Code: "EMPTY_CLIENT_OR_MATTER",
    ErrorMessage: "foo"
  }
};

const APEX_GetIFrameFolder_SUCCESS = {
  Data: "https://imanage.test"
};

describe("c-i-manage-container", () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    // Prevent data saved on mocks from leaking between tests
    jest.clearAllMocks();
  });

  async function flushPromises() {
    return Promise.resolve();
  }

  it("iFrame shoul be visible", async () => {
    GetIFrameFolder.mockResolvedValue(APEX_GetIFrameFolder_SUCCESS);

    const element = createElement("c-i-manage-container", {
      is: IManageContainer
    });

    document.body.appendChild(element);

    element.recordId = "test";

    await flushPromises();
    const iFrame = element.shadowRoot.querySelector("iframe");
    expect(iFrame).not.toBeNull();
  });

  it("iFrame shoul be invisible", async () => {
    GetIFrameFolder.mockResolvedValue(APEX_GetIFrameFolder_ERROR);

    const element = createElement("c-i-manage-container", {
      is: IManageContainer
    });

    document.body.appendChild(element);

    element.recordId = "test";

    await flushPromises();
    const iFrame = element.shadowRoot.querySelector("iframe");
    expect(iFrame).toBeNull();
  });

  it("Error by code", async () => {
    GetIFrameFolder.mockResolvedValue(APEX_GetIFrameFolder_ERROR);

    const element = createElement("c-i-manage-container", {
      is: IManageContainer
    });

    document.body.appendChild(element);

    element.recordId = "test";

    // Wait for any asynchronous DOM updates
    await flushPromises();

    const errElm = element.shadowRoot.querySelector(".error");
    expect(errElm.textContent).toBe(messageEmptyClientOrMatter);
  });
});

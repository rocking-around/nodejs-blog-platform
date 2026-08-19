import { createElement } from "lwc";
import IManageCreateWsContainer from "c/iManageCreateWsContainer";
import getIManageWorkspaceSettings from "@salesforce/apex/ConfigurationHelper.getIManageWorkspaceSettings";
import getIManageDataFromSObject from "@salesforce/apex/IManageMappingHelper.getIManageDataFromSObject";
import findEntityWorkspaceInCache from "@salesforce/apex/iManageWorkspacesHelper.findEntityWorkspaceInCache";
import findEntityWorkspaceInImanageAndPutToCache from "@salesforce/apex/iManageWorkspacesHelper.findEntityWorkspaceInImanageAndPutToCache";
import prepareCustomFields from "@salesforce/apex/IManageWsProvisioningService.prepareCustomFields";
import getActiveProvisioning from "@salesforce/apex/IManageWsProvisioningService.getActiveProvisioning";
import startProvisioning from "@salesforce/apex/IManageWsProvisioningService.startProvisioning";
import getProvisioningStatus from "@salesforce/apex/IManageWsProvisioningService.getProvisioningStatus";
import iManageCreateWsModal from "c/iManageCreateWsModal";

jest.mock(
  "@salesforce/apex/ConfigurationHelper.getIManageWorkspaceSettings",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/IManageMappingHelper.getIManageDataFromSObject",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/iManageWorkspacesHelper.findEntityWorkspaceInCache",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/iManageWorkspacesHelper.findEntityWorkspaceInImanageAndPutToCache",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/IManageWsProvisioningService.prepareCustomFields",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/IManageWsProvisioningService.getActiveProvisioning",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/IManageWsProvisioningService.startProvisioning",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/IManageWsProvisioningService.getProvisioningStatus",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock("c/iManageCreateWsModal", () => ({
  default: { open: jest.fn() }
}));

const flushPromises = () =>
  Array.from({ length: 20 }).reduce(
    (promise) => promise.then(() => Promise.resolve()),
    Promise.resolve()
  );

describe("c-i-manage-create-ws-container", () => {
  beforeEach(() => {
    jest.useFakeTimers();
    getIManageWorkspaceSettings.mockResolvedValue({
      "iManageWs:Folder_Template_Id": "ACTIVE::T!1",
      "iManageWs:Create_Ws_Enabled": true,
      "iManageWs:Auto_Create": false,
      "iManageWs:Name_Pattern": "{CLIENTCODE}.{MATTERCODE}"
    });
    findEntityWorkspaceInCache.mockResolvedValue({});
    findEntityWorkspaceInImanageAndPutToCache.mockResolvedValue({});
    getActiveProvisioning.mockResolvedValue(null);
    prepareCustomFields.mockResolvedValue(undefined);
    startProvisioning.mockResolvedValue("a00-operation");
    getIManageDataFromSObject.mockResolvedValue({
      clientId: "1000",
      matterId: "2000",
      clientName: "Client",
      matterName: "Matter",
      wsTemplate: "ACTIVE::T!1"
    });
    iManageCreateWsModal.open = jest.fn();
  });

  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
    jest.useRealTimers();
  });

  it("does not auto-discover a workspace while provisioning is active", async () => {
    getActiveProvisioning.mockResolvedValue(
      JSON.stringify({
        operationId: "a00-operation",
        status: "InProgress"
      })
    );
    const element = createContainer();

    await flushPromises();

    expect(getActiveProvisioning).toHaveBeenCalledWith({
      entityId: "001000000000001AAA"
    });
    expect(findEntityWorkspaceInImanageAndPutToCache).not.toHaveBeenCalled();
    document.body.removeChild(element);
  });

  it("keeps the existing spinner flow while polling the async operation", async () => {
    getProvisioningStatus
      .mockResolvedValueOnce(JSON.stringify({ status: "InProgress" }))
      .mockResolvedValueOnce(
        JSON.stringify({
          status: "Completed",
          workspaceId: "ACTIVE!100",
          workspaceName: "1000.2000",
          workspaceDatabase: "ACTIVE"
        })
      );
    iManageCreateWsModal.open.mockImplementation(async (options) =>
      options.createWs("ACTIVE::T!1")
    );
    const element = createContainer();
    const toastHandler = jest.fn();
    element.addEventListener("lightning__showtoast", toastHandler);
    await flushPromises();

    element.shadowRoot.querySelector("lightning-button").click();
    await flushPromises();

    expect(startProvisioning).toHaveBeenCalledWith({
      requestJson: JSON.stringify({
        entityId: "001000000000001AAA",
        workspaceName: "1000.2000",
        clientId: "1000",
        matterId: "2000",
        libraryId: "ACTIVE",
        templateId: "T!1",
        autoCreated: false,
        source: "SF"
      })
    });
    expect(getProvisioningStatus).toHaveBeenCalledTimes(1);

    jest.advanceTimersByTime(5000);
    await flushPromises();

    expect(getProvisioningStatus).toHaveBeenCalledTimes(2);
    expect(toastHandler).toHaveBeenCalledTimes(1);
  });

  it("routes a failed operation through the existing error callback", async () => {
    getProvisioningStatus.mockResolvedValue(
      JSON.stringify({
        status: "Failed",
        lastError: "Folder provisioning failed"
      })
    );
    iManageCreateWsModal.open.mockImplementation(async (options) => {
      try {
        return await options.createWs("ACTIVE::T!1");
      } catch (error) {
        options.ifErrorCallback(error);
        return undefined;
      }
    });
    const element = createContainer();
    const toastHandler = jest.fn();
    element.addEventListener("lightning__showtoast", toastHandler);
    await flushPromises();

    element.shadowRoot.querySelector("lightning-button").click();
    await flushPromises();

    expect(getProvisioningStatus).toHaveBeenCalledTimes(1);
    expect(toastHandler).toHaveBeenCalledTimes(1);
  });

  it("settles polling when the component is disconnected", async () => {
    getProvisioningStatus.mockResolvedValue(
      JSON.stringify({ status: "InProgress" })
    );
    let modalSettled = false;
    iManageCreateWsModal.open.mockImplementation(async (options) => {
      const result = await options.createWs("ACTIVE::T!1");
      modalSettled = true;
      return result;
    });
    const element = createContainer();
    await flushPromises();

    element.shadowRoot.querySelector("lightning-button").click();
    await flushPromises();
    document.body.removeChild(element);
    jest.advanceTimersByTime(5000);
    await flushPromises();

    expect(getProvisioningStatus).toHaveBeenCalledTimes(1);
    expect(modalSettled).toBe(true);
  });

  function createContainer() {
    const element = createElement("c-i-manage-create-ws-container", {
      is: IManageCreateWsContainer
    });
    element.recordId = "001000000000001AAA";
    document.body.appendChild(element);
    return element;
  }
});

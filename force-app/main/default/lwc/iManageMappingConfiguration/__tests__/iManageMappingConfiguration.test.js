import { createElement } from "lwc";
import IManageMappingConfiguration from "c/iManageMappingConfiguration";
import getMappings from "@salesforce/apex/IManageMappingHelper.getMappings";
import getAllSObjectsMetadata from "@salesforce/apex/IManageMappingHelper.getAllSObjectsMetadata";
import getFields from "@salesforce/apex/IManageMappingHelper.getFields";
import saveMappingConfiguration from "@salesforce/apex/IManageMappingHelper.saveMappingConfiguration";
import deleteMappingConfiguration from "@salesforce/apex/IManageMappingHelper.deleteMappingConfiguration";
import LightningConfirm from "lightning/confirm";

jest.mock(
  "@salesforce/apex/IManageMappingHelper.getMappings",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/IManageMappingHelper.getAllSObjectsMetadata",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/IManageMappingHelper.getFields",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/IManageMappingHelper.saveMappingConfiguration",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/IManageMappingHelper.deleteMappingConfiguration",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock("lightning/confirm", () => ({ open: jest.fn() }), {
  virtual: true
});

const flushPromises = () =>
  Array.from({ length: 20 }).reduce(
    (promise) => promise.then(() => Promise.resolve()),
    Promise.resolve()
  );

const opportunityMapping = {
  MappingId: "a01000000000001AAA",
  EntityType: "Opportunity",
  EntityClientIdObjectField: "AccountId",
  ClientIdField: "Id",
  ClientNameField: "Name",
  EntityMatterIdObjectField: "Opportunity",
  MatterIdField: "Id",
  MatterNameField: "Name",
  WsTemplateField: "Description",
  LibraryField: "Type",
  UseOnlyCustom2: false
};

const accountMapping = {
  ...opportunityMapping,
  MappingId: "a01000000000002AAA",
  EntityType: "Account",
  EntityClientIdObjectField: "Account",
  EntityMatterIdObjectField: "Account"
};

const namespacedMapping = {
  ...opportunityMapping,
  EntityClientIdObjectField: "Opportunity",
  ClientIdField: "gdsi_imanage__DMSClientID__c",
  ClientNameField: "gdsi_imanage__DMSClientName__c",
  MatterIdField: "gdsi_imanage__DMSMatterId__c",
  MatterNameField: "gdsi_imanage__DMSMatterName__c",
  WsTemplateField: "gdsi_imanage__iManageMatter12__c"
};

const fieldsByObject = {
  Opportunity: [
    {
      fieldName: "Id",
      fieldLabel: "Opportunity ID",
      fieldType: "ID",
      referenceTo: []
    },
    {
      fieldName: "Name",
      fieldLabel: "Opportunity Name",
      fieldType: "STRING",
      referenceTo: []
    },
    {
      fieldName: "Description",
      fieldLabel: "Description",
      fieldType: "STRING",
      referenceTo: []
    },
    {
      fieldName: "Type",
      fieldLabel: "Type",
      fieldType: "PICKLIST",
      referenceTo: []
    },
    {
      fieldName: "AccountId",
      fieldLabel: "Account",
      fieldType: "REFERENCE",
      referenceTo: ["Account"]
    }
  ],
  Account: [
    {
      fieldName: "Id",
      fieldLabel: "Account ID",
      fieldType: "ID",
      referenceTo: []
    },
    {
      fieldName: "Name",
      fieldLabel: "Account Name",
      fieldType: "STRING",
      referenceTo: []
    }
  ]
};

describe("c-i-manage-mapping-configuration", () => {
  beforeEach(() => {
    getAllSObjectsMetadata.mockResolvedValue([
      { label: "Opportunity", name: "Opportunity" },
      { label: "Account", name: "Account" }
    ]);
    getFields.mockImplementation(({ objectName }) =>
      Promise.resolve(fieldsByObject[objectName] || [])
    );
  });

  afterEach(() => {
    jest.clearAllMocks();
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("renders migrated mappings with field labels", async () => {
    getMappings.mockResolvedValue([opportunityMapping]);
    const element = createElement("c-i-manage-mapping-configuration", {
      is: IManageMappingConfiguration
    });

    document.body.appendChild(element);
    await flushPromises();
    await flushPromises();

    const row = element.shadowRoot.querySelector("tbody tr");
    expect(row).not.toBeNull();
    expect(element.shadowRoot.querySelectorAll("thead .slds-required")).toHaveLength(
      7
    );
    const headings = [
      ...element.shadowRoot.querySelectorAll("thead th")
    ].map((heading) =>
      heading.textContent.replace("*", "").replace(/\s+/g, " ").trim()
    );
    expect(headings).toEqual(
      expect.arrayContaining([
        "Salesforce Parent ID Object",
        "Salesforce Parent ID Field",
        "Salesforce Parent Name Field",
        "Salesforce Child ID Object",
        "Salesforce Child ID Field",
        "Salesforce Child Name Field"
      ])
    );
    expect(row.textContent).toContain("Opportunity");
    expect(row.textContent).toContain("Account");
    expect(row.textContent).toContain("Account ID");
    expect(row.textContent).toContain("Opportunity ID");
    expect(getFields).toHaveBeenCalledTimes(2);
    expect(getFields).toHaveBeenCalledWith({
      objectName: "Opportunity",
      fieldTypes: [
        "ID",
        "STRING",
        "INTEGER",
        "DOUBLE",
        "LONG",
        "PICKLIST",
        "REFERENCE"
      ]
    });
  });

  it("renders and retains namespaced field values", async () => {
    getMappings.mockResolvedValue([namespacedMapping]);
    getFields.mockImplementation(({ objectName }) => {
      if (objectName !== "Opportunity") {
        return Promise.resolve(fieldsByObject[objectName] || []);
      }
      return Promise.resolve([
        ...fieldsByObject.Opportunity,
        {
          fieldName: "gdsi_imanage__DMSClientID__c",
          fieldLabel: "DMS Client ID",
          fieldType: "STRING",
          referenceTo: []
        },
        {
          fieldName: "gdsi_imanage__DMSClientName__c",
          fieldLabel: "DMS Client Name",
          fieldType: "STRING",
          referenceTo: []
        },
        {
          fieldName: "gdsi_imanage__DMSMatterId__c",
          fieldLabel: "DMS Matter Id",
          fieldType: "STRING",
          referenceTo: []
        },
        {
          fieldName: "gdsi_imanage__DMSMatterName__c",
          fieldLabel: "DMS Matter Name",
          fieldType: "STRING",
          referenceTo: []
        },
        {
          fieldName: "gdsi_imanage__iManageMatter12__c",
          fieldLabel: "iManageMatter12",
          fieldType: "STRING",
          referenceTo: []
        }
      ]);
    });
    const element = createElement("c-i-manage-mapping-configuration", {
      is: IManageMappingConfiguration
    });

    document.body.appendChild(element);
    await flushPromises();
    await flushPromises();

    const rowText = element.shadowRoot.querySelector("tbody tr").textContent;
    expect(rowText).toContain("DMS Client ID");
    expect(rowText).toContain("DMS Client Name");
    expect(rowText).toContain("DMS Matter Id");
    expect(rowText).toContain("DMS Matter Name");
    expect(rowText).not.toContain("gdsi_imanage__DMSClientID__c");

    element.shadowRoot
      .querySelector('lightning-button-icon[title="Edit"]')
      .click();
    await flushPromises();

    const comboboxes = [
      ...element.shadowRoot.querySelectorAll("c-i-manage-mapping-combobox")
    ];
    const values = comboboxes.map((input) => input.value);
    expect(values).toEqual(
      expect.arrayContaining([
        "gdsi_imanage__DMSClientID__c",
        "gdsi_imanage__DMSClientName__c",
        "gdsi_imanage__DMSMatterId__c",
        "gdsi_imanage__DMSMatterName__c",
        "gdsi_imanage__iManageMatter12__c"
      ])
    );
    expect(
      element.shadowRoot.querySelector(".table-scroll_editing")
    ).not.toBeNull();
    expect(comboboxes).toHaveLength(9);
  });

  it("shows only the current entity mapping in record context", async () => {
    getMappings.mockResolvedValue([opportunityMapping, accountMapping]);
    const element = createElement("c-i-manage-mapping-configuration", {
      is: IManageMappingConfiguration
    });
    element.entityApiName = "Opportunity";

    document.body.appendChild(element);
    await flushPromises();
    await flushPromises();

    expect(element.shadowRoot.querySelector("lightning-card")).not.toBeNull();
    expect(element.shadowRoot.querySelector("table")).toBeNull();
    expect(
      element.shadowRoot.querySelectorAll(".imanage-mapping-container")
    ).toHaveLength(1);
    expect(element.shadowRoot.querySelector("lightning-input").value).toBe(
      "Opportunity"
    );
    expect(element.shadowRoot.querySelector("lightning-button").label).toBe(
      "Edit"
    );
  });

  it("prefills the current entity when adding from a record", async () => {
    getMappings.mockResolvedValue([]);
    const element = createElement("c-i-manage-mapping-configuration", {
      is: IManageMappingConfiguration
    });
    element.entityApiName = "Account";

    document.body.appendChild(element);
    await flushPromises();
    element.shadowRoot.querySelector("lightning-button").click();
    await flushPromises();

    const entityInput = element.shadowRoot.querySelector(
      'lightning-combobox[data-field="EntityType"]'
    );
    expect(entityInput.value).toBe("Account");
    expect(entityInput.options).toEqual([
      expect.objectContaining({ value: "Account" })
    ]);
    expect(
      element.shadowRoot.querySelector(
        'lightning-combobox[data-field="EntityClientIdObjectField"]'
      ).value
    ).toBe("Account");
    expect(
      element.shadowRoot.querySelector(
        'lightning-combobox[data-field="EntityMatterIdObjectField"]'
      ).value
    ).toBe("Account");
  });

  it("shows an editable row with dependent object options", async () => {
    getMappings.mockResolvedValue([]);
    const element = createElement("c-i-manage-mapping-configuration", {
      is: IManageMappingConfiguration
    });
    document.body.appendChild(element);
    await flushPromises();

    element.shadowRoot.querySelector("lightning-button").click();
    await flushPromises();
    const entityInput = element.shadowRoot.querySelector(
      'c-i-manage-mapping-combobox[data-field="EntityType"]'
    );
    entityInput.dispatchEvent(
      new CustomEvent("change", { detail: { value: "Opportunity" } })
    );
    await flushPromises();
    await flushPromises();

    const clientObjectInput = element.shadowRoot.querySelector(
      'c-i-manage-mapping-combobox[data-field="EntityClientIdObjectField"]'
    );
    expect(clientObjectInput.options).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ value: "Opportunity" }),
        expect.objectContaining({ value: "AccountId" })
      ])
    );
  });

  it("excludes configured entities and ignores a repeated Add click", async () => {
    getMappings.mockResolvedValue([opportunityMapping]);
    const element = createElement("c-i-manage-mapping-configuration", {
      is: IManageMappingConfiguration
    });
    document.body.appendChild(element);
    await flushPromises();
    await flushPromises();

    const addButton = element.shadowRoot.querySelector("lightning-button");
    addButton.click();
    addButton.click();
    await flushPromises();

    const entityInputs = element.shadowRoot.querySelectorAll(
      'c-i-manage-mapping-combobox[data-field="EntityType"]'
    );
    expect(entityInputs).toHaveLength(1);
    expect(entityInputs[0].options).not.toEqual(
      expect.arrayContaining([
        expect.objectContaining({ value: "Opportunity" })
      ])
    );
  });

  it("preserves a checkbox change while dependent options are loading", async () => {
    getMappings.mockResolvedValue([]);
    let resolveOpportunityFields;
    const opportunityFields = new Promise((resolve) => {
      resolveOpportunityFields = resolve;
    });
    getFields.mockImplementation(({ objectName }) => {
      return objectName === "Opportunity"
        ? opportunityFields
        : Promise.resolve(fieldsByObject[objectName] || []);
    });
    const element = createElement("c-i-manage-mapping-configuration", {
      is: IManageMappingConfiguration
    });
    document.body.appendChild(element);
    await flushPromises();

    element.shadowRoot.querySelector("lightning-button").click();
    await flushPromises();
    const entityInput = element.shadowRoot.querySelector(
      'c-i-manage-mapping-combobox[data-field="EntityType"]'
    );
    const custom2Input = element.shadowRoot.querySelector(
      'lightning-input[data-field="UseOnlyCustom2"]'
    );
    entityInput.dispatchEvent(
      new CustomEvent("change", { detail: { value: "Opportunity" } })
    );
    custom2Input.checked = true;
    custom2Input.dispatchEvent(new CustomEvent("change"));

    resolveOpportunityFields(fieldsByObject.Opportunity);
    await flushPromises();
    await flushPromises();

    expect(
      element.shadowRoot.querySelector(
        'lightning-input[data-field="UseOnlyCustom2"]'
      ).checked
    ).toBe(true);
  });

  it("deletes a persisted mapping after confirmation", async () => {
    getMappings.mockResolvedValue([opportunityMapping]);
    LightningConfirm.open.mockResolvedValue(true);
    deleteMappingConfiguration.mockResolvedValue();
    const element = createElement("c-i-manage-mapping-configuration", {
      is: IManageMappingConfiguration
    });
    document.body.appendChild(element);
    await flushPromises();
    await flushPromises();

    element.shadowRoot
      .querySelector('lightning-button-icon[title="Delete"]')
      .click();
    await flushPromises();
    await flushPromises();

    expect(deleteMappingConfiguration).toHaveBeenCalledWith({
      mappingId: opportunityMapping.MappingId
    });
    expect(element.shadowRoot.querySelector("tbody tr")).toBeNull();
    expect(element.shadowRoot.textContent).toContain("No mappings configured");
  });

  it("saves an edited row through the grid endpoint", async () => {
    getMappings.mockResolvedValue([opportunityMapping]);
    saveMappingConfiguration.mockResolvedValue(opportunityMapping);
    const element = createElement("c-i-manage-mapping-configuration", {
      is: IManageMappingConfiguration
    });
    document.body.appendChild(element);
    await flushPromises();
    await flushPromises();

    element.shadowRoot
      .querySelector('lightning-button-icon[title="Edit"]')
      .click();
    await flushPromises();
    element.shadowRoot
      .querySelectorAll("c-i-manage-mapping-combobox, lightning-input")
      .forEach((input) => {
        input.reportValidity = jest.fn(() => true);
      });
    element.shadowRoot
      .querySelector('lightning-button-icon[title="Save"]')
      .click();
    await flushPromises();
    await flushPromises();

    expect(saveMappingConfiguration).toHaveBeenCalledWith({
      mapping: opportunityMapping
    });
    expect(
      element.shadowRoot.querySelector('lightning-button-icon[title="Edit"]')
    ).not.toBeNull();
  });
});

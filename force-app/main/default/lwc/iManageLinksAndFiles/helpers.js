import FILE_LINK_FIELD from "@salesforce/schema/IManage_File_Link__c.File_Link__c";

export const COLUMNS_DEFINITION = [
  {
    type: "linkOrPreview",
    fieldName: "fileUrl",
    label: "Document Name",
    //wrapText: true,
    typeAttributes: {
      target: "_blank",
      label: { fieldName: "fileUrlLabel" },
      preview: { fieldName: "preview" },
      id: { fieldName: "id" }
    }
  },
  {
    type: "boolean",
    fieldName: "isInIManage",
    label: "iManage Link",
    initialWidth: 110
  },
  {
    type: "button",
    typeAttributes: {
      label: "Save to Salesforce",
      name: "save_to_sf",
      title: "Save to Salesforce",
      disabled: { fieldName: "isNotInIManage" }
    },
    initialWidth: 180
  }
];

export const mapLinksToGridModel = (links) => {
  return links.map((l) => ({
    id: l.Id,
    fileName: l.Name,
    lastModifiedDate: l.LastModifiedDate,
    isInIManage: true, // ALWAYS TRUE
    isNotInIManage: false, // OPPOSIT TO isInIManage
    fileUrl: l[FILE_LINK_FIELD.fieldApiName],
    fileUrlLabel: l.Name,
    preview: false // always false,
  }));
};

export const mapFilesToGridModel = (files = []) => {
  return files.map(({ ContentDocument: cd }) => ({
    id: cd.Id,
    lastModifiedDate: cd.LastModifiedDate,
    fileName: cd.Title,
    isInIManage: false, // ALWAYS false
    isNotInIManage: true, // OPPOSIT TO isInIManage
    fileUrl: `/lightning/r/ContentDocument/${cd.Id}/view`,
    fileUrlLabel: cd.Title + (cd.FileExtension ? `.${cd.FileExtension}` : ""),
    preview: true // always true
  }));
};

export function writeDebug() {
  if (this.isDebug) {
    console.log.apply(null, arguments);
  }
}

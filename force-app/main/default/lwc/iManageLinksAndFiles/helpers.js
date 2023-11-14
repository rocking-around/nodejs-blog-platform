import FILE_LINK_FIELD from "@salesforce/schema/IManage_File_Link__c.File_Link__c";
import FOLDER_LINK_IMANAGR_ID_FIELD from "@salesforce/schema/IManage_Folder_Link__c.iManage_Id__c";

export const ROW_ACTIONS = [
  { label: "Delete", name: "delete" },
  { label: "Save to Salesforce", name: "save_to_sf" }
];

export const COLUMNS_DEFINITION = [
  {
    type: "linkOrPreview",
    fieldName: "fileUrl",
    label: "Salesforce Name",
    wrapText: true,
    hideDefaultActions: true,
    typeAttributes: {
      target: "_blank",
      label: { fieldName: "fileUrlLabel" },
      preview: { fieldName: "preview" },
      id: { fieldName: "id" },
      iFrameUrl: { fieldName: "iFrameUrl" }
    }
  },
  {
    fieldName: "metadataName",
    label: "iManage Name",
    wrapText: true,
    hideDefaultActions: true
  },
  {
    fieldName: "metadataDocumentClass",
    label: "iManage Class",
    wrapText: true,
    hideDefaultActions: true,
    initialWidth: 105
  },
  {
    fieldName: "metadataDocumentNumber",
    label: "Number",
    wrapText: true,
    hideDefaultActions: true
  },
  {
    fieldName: "metadataVersion",
    label: "Version",
    wrapText: true,
    hideDefaultActions: true,
    initialWidth: 70
  },
  {
    fieldName: "metadataDocumentAuthor",
    label: "Author",
    wrapText: true,
    hideDefaultActions: true
  },
  {
    type: "boolean",
    fieldName: "isInIManage",
    label: "Link",
    wrapText: true,
    hideDefaultActions: true,
    initialWidth: 55
  },
  {
    type: "boolean",
    fieldName: "isIManageFolder",
    label: "Folder",
    wrapText: true,
    hideDefaultActions: true,
    initialWidth: 55
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
    preview: false, // always false,
    metadataName: l.metadata?.Name,
    metadataVersion: l.metadata?.Document_Version__c,
    metadataDocumentNumber: l.metadata?.DocNumber__c,
    metadataDocumentClass: l.metadata?.Document_Class__c,
    metadataDocumentAuthor: l.metadata?.Document_Author__c,
    isIManageFolder: false,
    iFrameUrl: null
  }));
};

export const mapFolderLinksToGridModel = (links) => {
  return links.map((l) => ({
    id: l.Id,
    fileName: l.Name,
    lastModifiedDate: l.LastModifiedDate,
    isInIManage: true, // ALWAYS TRUE
    isNotInIManage: false, // OPPOSIT TO isInIManage
    fileUrl: l.Name,
    fileUrlLabel: l.Name,
    preview: false, // always false,
    metadataName: l.Name,
    metadataVersion: null,
    metadataDocumentNumber: null,
    metadataDocumentClass: null,
    metadataDocumentAuthor: null,
    isIManageFolder: true,
    iFrameUrl: l.iframeUrl
  }));
};

export const mapFilesToGridModel = (files = []) => {
  return files.map(({ ContentDocument: cd, metadata }) => ({
    id: cd.Id,
    lastModifiedDate: cd.LastModifiedDate,
    fileName: cd.Title,
    isInIManage: false, // ALWAYS false
    isNotInIManage: true, // OPPOSIT TO isInIManage
    fileUrl: `/lightning/r/ContentDocument/${cd.Id}/view`,
    fileUrlLabel: cd.Title + (cd.FileExtension ? `.${cd.FileExtension}` : ""),
    preview: true, // always true
    metadataName: metadata?.Name,
    metadataVersion: metadata?.Document_Version__c,
    metadataDocumentNumber: metadata?.DocNumber__c,
    metadataDocumentClass: metadata?.Document_Class__c,
    metadataDocumentAuthor: metadata?.Document_Author__c,
    isIManageFolder: false,
    iFrameUrl: null
  }));
};

export function writeDebug() {
  if (this.isDebug) {
    console.log.apply(null, arguments);
  }
}

export const buildFilderLinkUrl = (folderLink, imFolderUrl) => {
  const imId = folderLink[FOLDER_LINK_IMANAGR_ID_FIELD.fieldApiName];
  const url = new URL(imFolderUrl);
  url.searchParams.set('start', imId);
  return url.toString();
}
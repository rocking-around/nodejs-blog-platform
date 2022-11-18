import LightningDatatable from "lightning/datatable";
import linkOrPreview from "./linkOrPreview.html";

export default class IManageLinksAndFilesDatatable extends LightningDatatable {
  static customTypes = {
    linkOrPreview: {
      template: linkOrPreview,
      standardCellLayout: true,
      typeAttributes: ["id", "label", "preview"]
    }
  };
}

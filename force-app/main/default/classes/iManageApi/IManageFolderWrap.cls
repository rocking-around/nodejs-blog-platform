public class IManageFolderWrap extends IManageWrapBase {
  private List<IManageFolderWrap> pFolderWrapsPath;
  private string pFolderFullPath;

  public IManageFolderWrap(IManageWFolder folder) {
    super(folder);
  }

  public IManageFolderWrap parentFolder { get; set; }

  public String workspaceId { get; set; }

  public List<IManageFolderWrap> folderWrapsPath {
    get {
      if (pFolderWrapsPath != null) {
        return pFolderWrapsPath;
      }
      pFolderWrapsPath = new List<IManageFolderWrap>{ this };
      IManageFolderWrap pf = parentFolder;
      while (pf != null) {
        pFolderWrapsPath.add(pf);
        pf = pf.parentFolder;
      }

      // reverse
      List<IManageFolderWrap> reversed = new List<IManageFolderWrap>();

      for (Integer i = pFolderWrapsPath.size() - 1; i >= 0; i--) {
        reversed.add(pFolderWrapsPath[i]);
      }

      pFolderWrapsPath = reversed;
      //
      return pFolderWrapsPath;
    }
  }

  public String folderFullPath {
    get {
      List<String> folderNames = new List<String>();
      for (IManageFolderWrap item : folderWrapsPath) {
        IManageWFolder x = (IManageWFolder) item.wrapItem;
        folderNames.add(x.Name);
      }

      if (String.isEmpty(pFolderFullPath)) {
        pFolderFullPath = String.join(folderNames, '/');
      }

      return pFolderFullPath;
    }
  }

  public Boolean isMissing { get; set; }
}
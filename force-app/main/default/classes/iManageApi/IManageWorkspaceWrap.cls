public class IManageWorkspaceWrap extends IManageWrapBase {
    private List<IManageFolderWrap> allFoldersWrap;

    public IManageWorkspaceWrap(IManageWWorkspace workspace)
    {
      super(workspace);
    }

    private static List<IManageFolderWrap> getFoldersRecursively(IManageFolderWrap folder)
    {
        List<IManageFolderWrap> result = new List<IManageFolderWrap> {folder};
        if (folder.children.size() != 0) {
            for (Object item : folder.children) {
                IManageFolderWrap child = (IManageFolderWrap)item;
                result.addAll(getFoldersRecursively(child));
            }
        }
        return result;
    }

    public List<IManageFolderWrap> getFlatListAllFolders()
    {
        if(allFoldersWrap == null ) {
            allFoldersWrap = new List<IManageFolderWrap>();
            for (Object item : children) {
                IManageFolderWrap f = (IManageFolderWrap)item;
                allFoldersWrap.addAll(getFoldersRecursively(f));
            }
        }
        return allFoldersWrap;
    }

    public IManageFolderWrap addFolderAndResetMapping(IManageWFolder folder)
    {
        List<IManageFolderWrap> allFolders = getFlatListAllFolders();
        IManageFolderWrap parentFolder = null;

        // firstOrDefault
        for (IManageFolderWrap item : allFolders) {
            IManageWFolder wrapItem = (IManageWFolder)item.wrapItem;
            if (wrapItem.id.toLowerCase() == folder.parent_id.toLowerCase()) {
                parentFolder = item;
                break;
            }
        }

        IManageFolderWrap folderWrap = new IManageFolderWrap(folder);
        if (parentFolder != null)
        {
            folderWrap.parentFolder = parentFolder;
            parentFolder.children.add(folderWrap);
        }
        else
        {
            children.add(folderWrap);
        }
        allFoldersWrap = null;
        return folderWrap;
    }

    public Boolean folderIsExists(String folderPath)
    {
        if (String.isBlank(folderPath)){
            throw new IllegalArgumentException('Invalid folderPath: ' + folderPath);
        }

        for (Object item : children) {
            IManageFolderWrap fw = (IManageFolderWrap)item;
            if (fw.folderFullPath == folderPath) {
                return true;
            }
        }
        return false;
    }
  }
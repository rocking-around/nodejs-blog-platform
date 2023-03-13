trigger CheckParentObjectId on IManage_File_Link__c(
  before insert,
  before update
) {
  for (IManage_File_Link__c link : Trigger.new) {
    if (link.ParentId__c != null && link.ParentId__c.length() > 0) {
      try {
        Id parentId = link.ParentId__c;
        String parentIdSObjName = parentId.getSObjectType()
          .getDescribe()
          .getName();
      } catch (Exception ex) {
        link.adderror(
          'Field "ParentId" must contains Id from the current Salesforce instance\'s object'
        );
      }
    }
  }
}

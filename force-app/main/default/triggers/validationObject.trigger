trigger validationObject on IManageLink__c(before insert, before update) {
  for (IManageLink__c link : Trigger.new) {
    if (link.EntityId__c != null && link.EntityId__c.length() > 0) {
      try {
        Id entityId = link.EntityId__c;
        String entityIdSObjName = entityId.getSObjectType()
          .getDescribe()
          .getName();
      } catch (Exception ex) {
        link.adderror(
          'Field "EntityId" must contains Id from the current Salesforce instance\'s object'
        );
      }
    }
  }
}

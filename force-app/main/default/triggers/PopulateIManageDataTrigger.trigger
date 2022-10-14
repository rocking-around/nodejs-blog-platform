trigger PopulateIManageDataTrigger on litify_pm__Matter__c /*, after update*/(
  after insert
) {
  System.debug(
    LoggingLevel.DEBUG,
    'PopulateIManageDataTrigger. Trigger.New: ' + Trigger.New
  );
  IManageLinkHandler.createIManageLink(Trigger.New);
  // Map<Id,Opportunity> oppsWithAccs = new Map<Id,Opportunity>(
  //     [SELECT Id, Name, Account.Id, Account.Name FROM Opportunity WHERE Id IN :Trigger.New]);

  //     for(Opportunity o : Trigger.New) {
  //         Opportunity oppWithAcc = oppsWithAccs.get(o.Id);
  //         //Update iManage_Client__c
  //         o.iManage_Client__c = 'CL_' + oppWithAcc.Account.Id;
  //         //Update iManageMatter__c
  //         o.iManageMatter__c = 'M_' + o.Id;

  //         System.debug(o);
  //     }
}

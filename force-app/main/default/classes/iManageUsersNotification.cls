public class iManageUsersNotification {
  @InvocableMethod
  public static void notificationProcess() {
      // Send only once per month
      if(DateTime.now().day() > 8) 
          return;
      sendNotification(false);
  }
  
  public static void sendNotification(boolean isNew) {
      Integer countUsers = [SELECT count() FROM User WHERE IsActive = true  AND (NOT Username LIKE 'cloud@%') AND (NOT Username LIKE 'autoproc@%')]; 
      Organization org = [SELECT Id, Name, Phone, IsSandbox, ComplianceBccEmail, Country, City, PostalCode FROM Organization LIMIT 1];
      
      // First, reserve email capacity for the current Apex transaction to ensure
      // that we won't exceed our daily email limits when sending email after
      // the current transaction is committed.
      Messaging.reserveSingleEmailCapacity(2);
      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
      
      // Strings to hold the email addresses to which you are sending the email.
      String[] toAddresses = new String[] {'dgeller@gdsi.com'}; 
      mail.setToAddresses(toAddresses);
      
      if(org.IsSandbox) {
        String[] ccAddresses = new String[] {'dmitrii.shilov@wave-access.com'};
        mail.setCcAddresses(ccAddresses);
      }
      mail.setSenderDisplayName('iManage Litify Package');
      if(isNew)
        mail.setSubject('New Installation in organization: ' + org.Id);
      else
        mail.setSubject('Inforamtion about organization: ' + org.Id);
      mail.setBccSender(false);
      mail.setUseSignature(false);
      
      mail.setHtmlBody('Information about organization:<br />Id: <b>' + org.Id +
                       '</b><br/>Name: <b>'+ org.Name + 
                       '</b><br />Count of users: <b>' + countUsers + 
                       '</b><br />Phone: <b>' + org.Phone + 
                       '</b><br />IsSandbox: <b>' + org.IsSandbox + 
                       '</b><br />Emails: <b>' + org.ComplianceBccEmail + 
                       '</b><br />Country: <b>' + org.Country + 
                       '</b><br />City: <b>' + org.City + 
                       '</b><br />PostalCode: <b>' + org.PostalCode);
      
      // Send the email you have created.
      Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
  }
}
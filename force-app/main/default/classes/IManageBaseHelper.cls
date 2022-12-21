public with sharing class IManageBaseHelper {
  public class IManageError {
    @AuraEnabled
    public String Code;

    @AuraEnabled
    public String ErrorMessage;
  }

  private static AuraHandledException newMessageException(String message) {
    AuraHandledException e = new AuraHandledException(message);
    e.setMessage(message);
    return e;
  }

  public static AuraHandledException BuildException(
    IManageBaseHelper.IManageErrors type
  ) {
    switch on type {
      when EMPTY_CLIENT_OR_MATTER {
        return newMessageException(
          System.Label.imanage_message_codes_empty_client_or_matter
        );
      }
      when UNAUTHORIZED {
        return newMessageException(
          System.Label.imanage_message_codes_empty_custom_resource
        );
      }
      when EMPTY_CUSTOM_RESOURCE {
        return newMessageException(
          System.Label.imanage_message_codes_folder_not_found
        );
      }
      when FOLDER_NOT_FOUND {
        return newMessageException(
          System.Label.imanage_message_codes_unauthorized
        );
      }
      when LICENSE_NOT_FOUND {
        return newMessageException(
          System.Label.imanage_message_codes_license_not_found
        );
      }
      when LICENSE_EXPIRED {
        return newMessageException(
          System.Label.imanage_message_codes_license_expired
        );
      }
      when else {
        return newMessageException('Unexpected error');
      }
    }
  }

  public enum IManageErrors {
    EMPTY_CLIENT_OR_MATTER,
    UNAUTHORIZED,
    EMPTY_CUSTOM_RESOURCE,
    FOLDER_NOT_FOUND,
    LICENSE_NOT_FOUND,
    LICENSE_EXPIRED
  }
}

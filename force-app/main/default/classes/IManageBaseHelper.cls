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
    String message = getErrorMessage(type);
    return newMessageException(message);
  }

  public static Void throwException(
    IManageBaseHelper.IManageErrors errorType,
    System.Quiddity quiddity
  ) {
    String message = getErrorMessage(errorType);
    if (quiddity == System.Quiddity.AURA) {
      throw newMessageException(message);
    } else {
      throw new IManageExceptions.IManageLicenseException(message);
    }
  }

  private static String getErrorMessage(
    IManageBaseHelper.IManageErrors errorType
  ) {
    switch on errorType {
      when EMPTY_CLIENT_OR_MATTER {
        return System.Label.imanage_message_codes_empty_client_or_matter;
      }
      when UNAUTHORIZED {
        return System.Label.imanage_message_codes_empty_custom_resource;
      }
      when EMPTY_CUSTOM_RESOURCE {
        return System.Label.imanage_message_codes_folder_not_found;
      }
      when FOLDER_NOT_FOUND {
        return System.Label.imanage_message_codes_unauthorized;
      }
      when LICENSE_NOT_FOUND {
        return System.Label.imanage_message_codes_license_not_found;
      }
      when LICENSE_EXPIRED {
        return System.Label.imanage_message_codes_license_expired;
      }
      when else {
        return 'Unexpected error';
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

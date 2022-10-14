public with sharing class IManageBaseHelper {
    public class IManageError {
        public String Code;
        public String ErrorMessage;
    }

    public enum IManageErrors {
        EMPTY_CLIENT_OR_MATTER,
        UNAUTHORIZED,
        EMPTY_CUSTOM_RESOURCE,
        FOLDER_NOT_FOUND
    }
}
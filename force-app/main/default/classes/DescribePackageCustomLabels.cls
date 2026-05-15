// ISV PACKAGED
//
// In case custom labels are referenced only in lightning, plz add them here ( and respect alphabetical order) so they are taken during Package generation
global with sharing class DescribePackageCustomLabels {
  global static Boolean describeLabelLs() {
    String imanage_message_codes_empty_client_or_matter = Label.imanage_message_codes_empty_client_or_matter;
    String imanage_message_codes_empty_custom_resource = Label.imanage_message_codes_empty_custom_resource;
    String imanage_message_codes_folder_not_found = Label.imanage_message_codes_folder_not_found;
    String imanage_message_codes_unauthorized = Label.imanage_message_codes_unauthorized;
    String imanage_message_codes_license_not_found = Label.imanage_message_codes_license_not_found;
    String imanage_message_codes_license_expired = Label.imanage_message_codes_license_expired;
    String imanage_message_codes_incorrect_folder_name = Label.imanage_message_codes_incorrect_folder_name;

    return true;
  }
}
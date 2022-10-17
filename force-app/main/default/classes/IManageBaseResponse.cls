public class IManageBaseResponse {
  @AuraEnabled
  public String Data;

  @AuraEnabled
  public IManageBaseHelper.IManageError Error;

  public static IManageBaseResponse BuildError(
    String code,
    String errorMessage
  ) {
    IManageBaseResponse result = new IManageBaseResponse();
    result.Data = null;
    result.Error = new IManageBaseHelper.IManageError();
    result.Error.Code = code;
    result.Error.ErrorMessage = errorMessage;

    return result;
  }
}

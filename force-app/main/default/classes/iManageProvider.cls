global class iManageProvider extends Auth.AuthProviderPluginClass {
  private String clientId;
  private String clientSecret;
  private String accessTokenUrl;
  private String authorizationUrl;
  private String scope;
  private String userInfoUrl;
  private String redirectUri;
  private String PREFIX = 'gdsi_imanage__';

  // This method is responsible for returning the custom metadata storing the api credentials and other details
  global String getCustomMetadataType() {
    return PREFIX + 'iManageAuthSetting__mdt';
  }

  // This method is responsible to initiate the authorization code flow
  global PageReference initiate(
    Map<String, String> authProviderConfiguration,
    String stateToPropagate
  ) {
    Map<String, Object> params = new Map<String, Object>{
      'authProviderConfiguration' => authProviderConfiguration,
      'stateToPropagate' => stateToPropagate
    };

    // Logger.getInstance()
    //   .info(
    //     'iManageProvider::initiate, start method. Params: ' +
    //     JSON.serialize(params)
    //   );

    try {
      clientId = authProviderConfiguration.get(PREFIX + 'Consumer_Key__c');
      authorizationUrl = authProviderConfiguration.get(
        PREFIX + 'Authorize_Endpoint_URL__c'
      );
      scope = authProviderConfiguration.get(PREFIX + 'Scope__c');
      redirectUri = authProviderConfiguration.get(PREFIX + 'Redirect_URI__c');
      String url =
        authorizationUrl +
        '?response_type=code&client_id=' +
        clientId +
        '&scope=' +
        scope +
        '&state=' +
        stateToPropagate +
        '&redirect_uri=' +
        redirectUri;
      return new PageReference(url);
    } catch (Exception ex) {
      // Logger.getInstance().error(ex, 'iManageProvider::initiate');
      throw ex;
    } finally {
      // Logger.getInstance().Flush();
    }
  }

  /*   
      This method is responsible to handle the callback from authorization code flow
      set the access token, refresh token and other parameters
    */
  global Auth.AuthProviderTokenResponse handleCallback(
    Map<String, String> authProviderConfiguration,
    Auth.AuthProviderCallbackState state
  ) {
    Map<String, Object> params = new Map<String, Object>{
      'authProviderConfiguration' => authProviderConfiguration,
      'state' => state
    };

    // Logger.getInstance()
    //   .info(
    //     'iManageProvider::handleCallback, start method. Params: ' +
    //     JSON.serialize(params)
    //   );

    try {
      clientId = authProviderConfiguration.get(PREFIX + 'Consumer_Key__c');
      clientSecret = authProviderConfiguration.get(
        PREFIX + 'Consumer_Secret__c'
      );
      scope = authProviderConfiguration.get(PREFIX + 'Scope__c');
      redirectUri = authProviderConfiguration.get(PREFIX + 'Redirect_URI__c');
      accessTokenUrl = authProviderConfiguration.get(
        PREFIX + 'Token_Endpoint_URL__c'
      );

      Map<String, String> queryParams = state.queryParameters;
      String code = queryParams.get('code');
      String sfdcState = queryParams.get('state');

      HttpRequest req = new HttpRequest();
      req.setEndpoint(accessTokenUrl);
      req.setHeader('content-type', 'application/x-www-form-urlencoded');
      req.setMethod('POST');
      req.setBody(
        'client_id=' +
        EncodingUtil.urlEncode(clientId, 'UTF-8') +
        '&client_secret=' +
        EncodingUtil.urlEncode(clientSecret, 'UTF-8') +
        '&grant_type=authorization_code&code=' +
        EncodingUtil.urlEncode(code, 'UTF-8') +
        '&redirect_uri=' +
        EncodingUtil.urlEncode(redirectUri, 'UTF-8')
      );

      Http http = new Http();
      HTTPResponse res = http.send(req);
      String responseBody = res.getBody();

      IManageResponse response = (IManageResponse) JSON.deserialize(
        responseBody,
        IManageResponse.class
      );

      return new Auth.AuthProviderTokenResponse(
        'iManageProvider',
        response.access_token,
        response.refresh_token,
        sfdcState
      );
    } catch (Exception ex) {
      // Logger.getInstance().error(ex, 'iManageProvider::handleCallback');
      throw ex;
    } finally {
      // Logger.getInstance().Flush();
    }
  }

  // This method is responsible to get the user information used for authentication from the external api
  global Auth.UserData getUserInfo(
    Map<String, String> authProviderConfiguration,
    Auth.AuthProviderTokenResponse response
  ) {
    Map<String, Object> params = new Map<String, Object>{
      'authProviderConfiguration' => authProviderConfiguration,
      'state' => response
    };

    // Logger.getInstance()
    //   .info(
    //     'iManageProvider::getUserInfo, start method. Params: ' +
    //     JSON.serialize(params)
    //   );

    try {
      userInfoUrl = authProviderConfiguration.get(PREFIX + 'User_Info_URL__c');
      String token = response.oauthToken;

      HttpRequest req = new HttpRequest();
      req.setHeader('X-Auth-Token', token);
      req.setEndpoint(userInfoUrl);
      req.setMethod('GET');

      Http http = new Http();
      HTTPResponse res = http.send(req);
      String responseBody = res.getBody();

      IManageApiDataResponse infoApiResponse = (IManageApiDataResponse) JSON.deserialize(
        responseBody,
        IManageApiDataResponse.class
      );

      String[] names = infoApiResponse.data.user.name.split(' ');

      String userId, fullName, firstName, lastName, locale, loginURL, email;

      locale = 'en-us';
      loginURL = authProviderConfiguration.get(PREFIX + 'Login_URL__c');

      userId = infoApiResponse.data.user.id;
      fullName = infoApiResponse.data.user.name;
      email = infoApiResponse.data.user.email;
      if (names.size() >= 2) {
        firstName = names[0];
        lastName = names[1];
      }

      return new Auth.UserData(
        userId,
        firstName,
        lastName,
        fullName,
        email,
        null,
        userId,
        locale,
        'iManage',
        loginURL,
        null
      );
    } catch (Exception ex) {
      // Logger.getInstance().error(ex, 'iManageProvider::getUserInfo');
      throw ex;
    } finally {
      // Logger.getInstance().Flush();
    }
  }

  global override Auth.OAuthRefreshResult refresh(
    Map<String, String> authProviderConfiguration,
    String refreshToken
  ) {
    system.debug(authProviderConfiguration);
    clientId = authProviderConfiguration.get(PREFIX + 'Consumer_Key__c');
    clientSecret = authProviderConfiguration.get(PREFIX + 'Consumer_Secret__c');
    scope = authProviderConfiguration.get(PREFIX + 'Scope__c');
    redirectUri = authProviderConfiguration.get(PREFIX + 'Redirect_URI__c');
    accessTokenUrl = authProviderConfiguration.get(
      PREFIX + 'Token_Endpoint_URL__c'
    );

    HttpRequest req = new HttpRequest();
    req.setEndpoint(accessTokenUrl);
    req.setHeader('content-type', 'application/x-www-form-urlencoded');
    req.setMethod('POST');
    req.setBody(
      'client_id=' +
      EncodingUtil.urlEncode(clientId, 'UTF-8') +
      '&grant_type=refresh_token&refresh_token=' +
      EncodingUtil.urlEncode(refreshToken, 'UTF-8')
    );

    Http http = new Http();
    HTTPResponse res = http.send(req);
    String responseBody = res.getBody();
    system.debug(responseBody);
    IManageResponse response = (IManageResponse) JSON.deserialize(
      responseBody,
      IManageResponse.class
    );

    return new Auth.OAuthRefreshResult(
      response.access_token,
      response.refresh_token
    );
  }

  // Wrapper class to handle User Info API response
  public class IManageApiDataResponse {
    public IManageUserObjectResponse data;
  }

  public class IManageUserObjectResponse {
    public String auth_status;
    public IManageUserInfoResponse user;
    public IManageUserWorkInfoResponse work;
  }

  public class IManageUserInfoResponse {
    public String id;
    public String name;
    public String email;
    public String customer_id;
  }

  public class IManageUserWorkInfoResponse {
    public String preferred_library;
  }

  // Wrapper class to handle Access Token API response
  public class IManageResponse {
    public String access_token;
    public String token_type;
    public String scope;
    public Integer expires_in;
    public String refresh_token;
  }
}

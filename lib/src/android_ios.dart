part of openidconnect;

class OpenIdConnectAndroidiOS {
  static Future<String> authorizeInteractive({
    required BuildContext context,
    required String title,
    required String authorizationUrl,
    required String redirectUrl,
    required int popupWidth,
    required int popupHeight,
  }) async {
    //Create the url

    final result = await showDialog<String?>(
      context: context,
      barrierDismissible: true,
      useSafeArea: false,
      builder: (dialogContext) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.close,
                size: 25,
                color: Colors.black,
              ),
            ),
          ),
          body: flutterWebView.WebViewWidget(
              controller: flutterWebView.WebViewController()
                ..loadRequest(Uri.parse(authorizationUrl))
                ..setJavaScriptMode(flutterWebView.JavaScriptMode.unrestricted)
                ..setNavigationDelegate(flutterWebView.NavigationDelegate(
                  onPageFinished: (url) {
                    if (url.startsWith(redirectUrl)) {
                      Navigator.pop(dialogContext, url);
                    }
                  },
                ))),
        );
      },
    );

    if (result == null) throw AuthenticationException(ERROR_USER_CLOSED);

    return result;
  }

  static Future<void> authorizeInteractiveMobile(
      {required BuildContext context,
      required String authorizationUrl,
      required String redirectUrl,
      required InteractiveAuthorizationRequest request,
      required Future<void> Function(AuthorizationResponse? response)
          onPop}) async {
    //Create the url

    showDialog<String?>(
      context: context,
      barrierDismissible: true,
      useSafeArea: false,
      builder: (dialogContext) {
        return Scaffold(
          backgroundColor: Colors.white,
          // appBar: AppBar(
          //   backgroundColor: Colors.transparent,
          //   elevation: 0,
          //   leading: IconButton(
          //     onPressed: ()=> Navigator.of(context).pop(),
          //     icon: Icon(Icons.close, size: 25, color: Colors.black,),
          //   ),
          // ),
          body: flutterWebView.WebViewWidget(
              controller: flutterWebView.WebViewController()
                ..loadRequest(Uri.parse(authorizationUrl))
                ..setJavaScriptMode(flutterWebView.JavaScriptMode.unrestricted)
                ..setNavigationDelegate(flutterWebView.NavigationDelegate(
                    onPageFinished: (url) async {
                  print(url);
                  print(redirectUrl);
                  if (url.startsWith(redirectUrl)) {
                    var result =
                        await _completeCodeExchange(request: request, url: url);
                    await onPop(result);
                    Navigator.pop(dialogContext);
                  }
                }, onNavigationRequest:
                        (flutterWebView.NavigationRequest request) {
                  print(request.url);
                  return flutterWebView.NavigationDecision.navigate;
                }))),
        );
      },
    );
  }

  static Future<AuthorizationResponse> _completeCodeExchange({
    required InteractiveAuthorizationRequest request,
    required String url,
  }) async {
    final resultUri = Uri.parse(url);

    final error = resultUri.queryParameters['error'];

    if (error != null && error.isNotEmpty)
      throw ArgumentError(
        AUTHORIZE_ERROR_MESSAGE_FORMAT
            .replaceAll("%1", AUTHORIZE_ERROR_CODE)
            .replaceAll("%2", error),
      );

    var authCode = resultUri.queryParameters['code'];
    if (authCode == null || authCode.isEmpty)
      throw AuthenticationException(ERROR_INVALID_RESPONSE);

    var state = resultUri.queryParameters['state'] ??
        resultUri.queryParameters['session_state'];

    final body = {
      "client_id": request.clientId,
      "redirect_uri": request.redirectUrl,
      "grant_type": "authorization_code",
      "code_verifier": request.codeVerifier,
      "code": authCode,
    };

    if (request.clientSecret != null)
      body.addAll({"client_secret": request.clientSecret!});

    if (state != null && state.isNotEmpty) body.addAll({"state": state});

    final response = await httpRetry(
      () => http.post(
        Uri.parse(request.configuration.tokenEndpoint),
        body: body,
      ),
    );

    if (response == null) if (response == null)
      throw UnsupportedError('The response was null.');

    return AuthorizationResponse.fromJson(response);
  }
}

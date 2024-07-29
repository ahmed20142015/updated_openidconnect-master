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
      required Future<void> Function(AuthorizationResponse? response) onPop,
      required GenericBloc<bool> needRender,
      required GenericBloc<bool> isReloading,
      required WebViewController webViewController,
      }) async {
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
          body: BlocBuilder<GenericBloc<bool>,GenericState<bool>>(
            bloc: needRender,
            builder: (context,state){
              return Visibility(
                visible: !(state.data ?? true),
                replacement: SizedBox.shrink(),
                child: BlocBuilder<GenericBloc<bool>, GenericState<bool>>(
                  bloc: isReloading,
                  builder: (context,loadingState){
                    if (state.data ?? false) {
                      return Center(
                        child: CupertinoActivityIndicator(
                            radius: 20, color: Colors.black),
                      );
                    } else {
                      return flutterWebView.WebViewWidget(
                          controller: webViewController
                      );
                    }
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

}

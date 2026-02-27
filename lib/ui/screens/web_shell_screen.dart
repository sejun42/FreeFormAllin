import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../features/auth/native_auth_service.dart';
import '../../features/settings/application/settings_controller.dart';
import '../../core/logging/log.dart';

/// Global WebViewController provider so other screens can inject JS / navigate.
final webViewControllerProvider = StateProvider<WebViewController?>(
  (ref) => null,
);

/// WebView Shell Screen — loads FreeFormApp (React) UI.
/// Intercepts `freeform://` deep links for native BLE flows and
/// handles Google OAuth by routing through native sign-in.
class WebShellScreen extends ConsumerStatefulWidget {
  const WebShellScreen({super.key});

  @override
  ConsumerState<WebShellScreen> createState() => _WebShellScreenState();
}

class _WebShellScreenState extends ConsumerState<WebShellScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;
  bool _authInProgress = false; // Prevent re-entrant sign-in loops

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    final settings = ref.read(settingsProvider);
    final webAppUrl = settings.webAppUrl;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FreeFormNative',
        onMessageReceived: (message) {
          _handleJsMessage(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
            // Inject native environment flag + bridge
            _injectNativeBridge();
            log.i('WebView page loaded: $url');
          },
          onWebResourceError: (error) {
            final isMainFrame = error.isForMainFrame ?? true;
            final failingUrl = error.url ?? '(unknown)';

            // Subresource failures (e.g. analytics/ad host lookup) should not
            // replace a successfully loaded page with a full-screen error UI.
            if (!isMainFrame) {
              log.w(
                'Ignoring non-main-frame WebView error: ${error.description} '
                '(code: ${error.errorCode}, type: ${error.errorType}, url: $failingUrl)',
              );
              return;
            }

            log.e(
              'WebView main-frame error: ${error.description} '
              '(code: ${error.errorCode}, type: ${error.errorType}, url: $failingUrl)',
            );
            setState(() {
              _isLoading = false;
              _errorMessage = 'Failed to load page: ${error.description}';
            });
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri != null && uri.scheme == 'freeform') {
              _handleDeepLink(uri);
              return NavigationDecision.prevent;
            }
            // Block Google OAuth popup/redirect in WebView
            if (_isGoogleOAuthUrl(request.url)) {
              if (!_authInProgress) {
                log.i('Intercepted Google OAuth, using native sign-in');
                _handleNativeGoogleSignIn();
              } else {
                log.i(
                  'Auth already in progress, ignoring duplicate OAuth redirect',
                );
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    var initialUri = Uri.parse(webAppUrl);
    // Safely append query parameter
    initialUri = initialUri.replace(
      queryParameters: {...initialUri.queryParameters, 'native_shell': 'true'},
    );
    _controller.loadRequest(initialUri);

    // Store controller globally for other screens to access
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(webViewControllerProvider.notifier).state = _controller;
    });
  }

  bool _isGoogleOAuthUrl(String url) {
    return url.contains('accounts.google.com/o/oauth') ||
        url.contains('accounts.google.com/signin') ||
        url.contains('accounts.google.com/v3/signin');
  }

  /// Inject native bridge JS into the WebView page.
  void _injectNativeBridge() {
    _controller.runJavaScript('''
(function() {
  window.__FREEFORM_NATIVE__ = true;
  
  // Override to intercept Google sign-in attempts via JS channel
  window.__FREEFORM_REQUEST_NATIVE_AUTH__ = function(provider) {
    FreeFormNative.postMessage(JSON.stringify({
      type: 'auth_request',
      provider: provider || 'google'
    }));
  };
  
  console.log('[FreeForm] Native bridge injected');
})();
''');
  }

  /// Write auth tokens to WebView localStorage so the React app can read them on mount.
  Future<void> _writeAuthToLocalStorage(Map<String, String> tokens) async {
    final idToken = tokens['idToken'] ?? '';
    final accessToken = tokens['accessToken'] ?? '';

    log.i('Writing auth tokens to WebView localStorage');

    await _controller.runJavaScript('''
(function() {
  try {
    var data = JSON.stringify({
      idToken: '$idToken',
      accessToken: '$accessToken',
      provider: 'google',
      timestamp: Date.now()
    });
    localStorage.setItem('freeform_native_auth', data);
    console.log('[FreeForm Native Auth] Tokens written to localStorage');
  } catch(e) {
    console.error('[FreeForm Native Auth] localStorage write failed:', e);
  }
})();
''');
  }

  /// Handle messages from the WebView JavaScript channel.
  void _handleJsMessage(String message) {
    try {
      if (message.contains('auth_request')) {
        if (!_authInProgress) {
          _handleNativeGoogleSignIn();
        }
      }
    } catch (e) {
      log.e('Error handling JS message: $message', error: e);
    }
  }

  /// Perform native Google Sign-In and inject credentials back into WebView.
  Future<void> _handleNativeGoogleSignIn() async {
    if (_authInProgress) return; // Prevent re-entrant calls
    _authInProgress = true;

    final authService = ref.read(nativeAuthServiceProvider);

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Google 로그인 중...'),
            ],
          ),
          duration: Duration(seconds: 30),
          backgroundColor: Color(0xFF6C63FF),
        ),
      );
    }

    final tokens = await authService.signInWithGoogle();

    // Dismiss loading snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }

    if (tokens == null) {
      _authInProgress = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google 로그인이 취소되었습니다'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      // Go back to the web app (since current page may be blank)
      final settings = ref.read(settingsProvider);
      var fallbackUri = Uri.parse(settings.webAppUrl);
      fallbackUri = fallbackUri.replace(
        queryParameters: {
          ...fallbackUri.queryParameters,
          'native_shell': 'true',
        },
      );
      _controller.loadRequest(fallbackUri);
      return;
    }

    // Write tokens to localStorage BEFORE navigating — so the web app
    // can read them immediately when the page mounts.
    await _writeAuthToLocalStorage(tokens);

    // Small delay to ensure localStorage write completes
    await Future.delayed(const Duration(milliseconds: 300));

    // Navigate to the home page
    final settings = ref.read(settingsProvider);
    var homeUri = Uri.parse('${settings.webAppUrl}/home');
    homeUri = homeUri.replace(
      queryParameters: {...homeUri.queryParameters, 'native_shell': 'true'},
    );

    log.i('Auth success, navigating WebView to: $homeUri');
    await _controller.loadRequest(homeUri);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google 로그인 성공!'),
          backgroundColor: Color(0xFF4CAF50),
          duration: Duration(seconds: 2),
        ),
      );
    }

    // Reset auth flag after a delay
    Future.delayed(const Duration(seconds: 5), () {
      _authInProgress = false;
    });
  }

  void _handleDeepLink(Uri uri) {
    final path = uri.host + uri.path;
    final params = uri.queryParameters;

    log.i('Deep link intercepted: $uri -> path=$path, params=$params');

    switch (path) {
      case 'ble/devices':
        Navigator.of(context).pushNamed('/devices');
        break;
      case 'ble/start':
        final workoutType = params['type'] ?? 'squat';
        Navigator.of(
          context,
        ).pushNamed('/live_session', arguments: {'workoutType': workoutType});
        break;
      case 'ble/sessions':
        Navigator.of(context).pushNamed('/sessions');
        break;
      default:
        log.w('Unknown deep link path: $path');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Stack(
          children: [
            if (_errorMessage != null)
              _buildErrorView()
            else
              WebViewWidget(controller: _controller),

            // Loading indicator
            if (_isLoading)
              Container(
                color: const Color(0xFF0D0D1A),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Color(0xFF6C63FF)),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading FreeForm...',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      // Floating action button for native BLE access
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6C63FF),
        onPressed: () => Navigator.of(context).pushNamed('/devices'),
        child: const Icon(Icons.bluetooth, color: Colors.white),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Unknown error',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                final webAppUrl = ref.read(settingsProvider).webAppUrl;
                var retryUri = Uri.parse(webAppUrl);
                retryUri = retryUri.replace(
                  queryParameters: {
                    ...retryUri.queryParameters,
                    'native_shell': 'true',
                  },
                );
                setState(() {
                  _errorMessage = null;
                  _isLoading = true;
                });
                _controller.loadRequest(retryUri);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pushNamed('/settings'),
              child: const Text(
                'Open Settings',
                style: TextStyle(color: Colors.white38),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

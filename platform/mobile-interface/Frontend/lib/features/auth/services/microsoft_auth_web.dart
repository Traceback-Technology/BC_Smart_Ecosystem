import 'dart:js_interop';

import 'package:flutter_openid_web/flutter_openid_web.dart';

// Browser `window.location`, used to send admins to the admin portal.
@JS('location')
external _Location get _browserLocation;

extension type _Location(JSObject _) implements JSObject {
  external void replace(JSString url);
}

/// Leaves this app and opens [url]. `replace` (not `assign`) keeps the
/// URL carrying the token out of this tab's back-button history.
void redirectBrowserTo(String url) => _browserLocation.replace(url.toJS);

const _allowedOrigins = <String>{
  'http://localhost:7357',
  'https://bc-smart-ecosystem.tetelo702.workers.dev',
};

Future<void> initializeMicrosoftWebAuth() async {
  await FlutterOpenidWeb.initialize();
}

String? currentMicrosoftWebIdToken() {
  final state = FlutterOpenidWeb.instance.currentState;

  if (!state.isAuthenticated) {
    return null;
  }

  final token = state.tokens?.idToken;
  return token == null || token.isEmpty ? null : token;
}

Future<void> startMicrosoftWebSignIn({
  required String clientId,
  required String discoveryUrl,
}) async {
  final origin = Uri.base.origin;

  if (!_allowedOrigins.contains(origin)) {
    throw StateError(
      'Microsoft sign-in is not registered for this website address: $origin',
    );
  }

  final request = await AuthRequest.fromDiscoveryUrl(
    discoveryUrl: discoveryUrl,
    clientId: clientId,
    redirectUri: '$origin/auth',
    scopes: const <String>['openid', 'profile', 'email'],
  );

  FlutterOpenidWeb.instance.authenticateAndExchangeCode(request);
}

Future<void> endMicrosoftWebSession({
  required String clientId,
  required String discoveryUrl,
}) async {
  final idToken = FlutterOpenidWeb.instance.currentState.tokens?.idToken;
  if (idToken == null || idToken.isEmpty) {
    return;
  }

  final origin = Uri.base.origin;
  if (!_allowedOrigins.contains(origin)) {
    throw StateError('Sign-out is not configured for this website address.');
  }

  final request = await EndSessionRequest.fromDiscoveryUrl(
    discoveryUrl: discoveryUrl,
    idToken: idToken,
    clientId: clientId,
    redirectUri: '$origin/auth',
  );

  await FlutterOpenidWeb.instance.endSession(request);
}

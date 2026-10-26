import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

import '../../../core/bc_api_client.dart';
import '../models/app_session.dart';
import 'microsoft_auth_web_stub.dart'
    if (dart.library.js_interop) 'microsoft_auth_web.dart'
    as web;

class MicrosoftAuthService {
  static const clientId = '12e05e9b-2a75-43c3-8a5c-83a87969f0f9';
  static const tenantId = 'ea1a909b-6600-4a25-82a5-0c6ed7d0513b';
  static const redirectUri = 'com.example.frontend://oauthredirect';

  /// Admin portal (separate Cloudflare Pages app). Set at build time:
  /// --dart-define=ADMIN_PORTAL_URL=https://<admin-portal>.pages.dev
  /// When empty, admins simply continue into this app.
  static const adminPortalUrl = String.fromEnvironment('ADMIN_PORTAL_URL');

  /// Database roles that are sent to the admin portal instead of this app.
  static const _adminPortalRoles = {'admin', 'restaurant'};

  static const discoveryUrl =
      'https://login.microsoftonline.com/$tenantId/v2.0/'
      '.well-known/openid-configuration';

  final FlutterAppAuth _appAuth = FlutterAppAuth();

  Future<void> signOut() async {
    if (kIsWeb) {
      await web.endMicrosoftWebSession(
        clientId: clientId,
        discoveryUrl: discoveryUrl,
      );
    }
  }

  /// Called at web startup to process Microsoft's redirect.
  Future<AppSession?> restoreWebSession() async {
    if (!kIsWeb) {
      return null;
    }

    await web.initializeMicrosoftWebAuth();
    final idToken = web.currentMicrosoftWebIdToken();

    if (idToken == null) {
      return null;
    }

    return _exchangeWithBackend(idToken);
  }

  /// Web redirects to Microsoft; Android returns the completed session.
  Future<AppSession?> signIn() async {
    if (kIsWeb) {
      await web.startMicrosoftWebSignIn(
        clientId: clientId,
        discoveryUrl: discoveryUrl,
      );
      return null;
    }

    if (defaultTargetPlatform != TargetPlatform.android) {
      throw const BcApiException(
        'Microsoft sign-in is currently available on Android and Web.',
      );
    }

    var stage = 'Microsoft authorization and token exchange';
    try {
      debugPrint('Microsoft login: opening Android sign-in.');
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          clientId,
          redirectUri,
          discoveryUrl: discoveryUrl,
          scopes: const ['openid', 'profile', 'email'],
          promptValues: const ['select_account'],
        ),
      );

      stage = 'checking Microsoft response';
      debugPrint('Microsoft login: Android authentication returned.');
      final idToken = result.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const BcApiException(
          'Microsoft did not return the required sign-in information.',
        );
      }

      stage = 'backend login';
      debugPrint('Microsoft login: contacting backend.');
      return await _exchangeWithBackend(idToken);
    } on FlutterAppAuthUserCancelledException {
      debugPrint('Microsoft login: cancelled.');
      return null;
    } catch (error) {
      debugPrint('Microsoft login failed at: $stage');
      debugPrint('Error type: ${error.runtimeType}');
      if (error is PlatformException) {
        debugPrint('Platform error code: ${error.code}');
        final aadCode = RegExp(r'AADSTS\d+').firstMatch(error.message ?? '');
        if (aadCode != null) {
          debugPrint('Microsoft error code: ${aadCode.group(0)}');
        }
      }
      rethrow;
    }
  }

  Future<AppSession?> _exchangeWithBackend(String idToken) async {
    final response = await BcApiClient.instance.postJson(
      '/api/users/microsoft-login',
      <String, dynamic>{},
      token: idToken,
    );

    final token = response['token'];
    final user = response['data'];

    if (token is! String || token.isEmpty || user is! Map<String, dynamic>) {
      throw const BcApiException(
        'The server returned an incomplete login response.',
      );
    }

    final fullName = (user['fullName'] ?? user['name'] ?? '').toString().trim();
    final email = user['email']?.toString().trim();

    if (fullName.isEmpty) {
      throw const BcApiException(
        'The server did not return your profile name.',
      );
    }

    // Role-based redirect: the backend has verified the Microsoft token and
    // read this user's role from the database. Admin/restaurant users are
    // handed to the admin portal with the backend token in the URL fragment
    // (#...), which browsers never send to any server. The portal stores the
    // token and re-checks the role with GET /api/users/me before showing
    // anything; the backend checks the role again on every admin request.
    final role = user['role']?.toString().toLowerCase();
    if (kIsWeb &&
        adminPortalUrl.isNotEmpty &&
        _adminPortalRoles.contains(role)) {
      final base = adminPortalUrl.endsWith('/')
          ? adminPortalUrl
          : '$adminPortalUrl/';
      web.redirectBrowserTo('$base#token=${Uri.encodeComponent(token)}');
      return null; // the page is being replaced; don't open this app
    }

    return AppSession.microsoft(
      accountType: user['accountType']?.toString() ?? 'unclassified',
      fullName: fullName,
      email: email,
      accessToken: token,
    );
  }
}

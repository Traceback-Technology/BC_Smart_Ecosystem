Future<void> initializeMicrosoftWebAuth() async {}

String? currentMicrosoftWebIdToken() => null;

Future<void> startMicrosoftWebSignIn({
  required String clientId,
  required String discoveryUrl,
}) async {
  throw UnsupportedError(
    'Microsoft web authentication is unavailable on this platform.',
  );
}

Future<void> endMicrosoftWebSession({
  required String clientId,
  required String discoveryUrl,
}) async {}

/// Admin-portal redirect only exists on web; other platforms ignore it.
void redirectBrowserTo(String url) {}

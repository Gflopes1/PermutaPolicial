/// Stub — plataformas não-web.
String getWebNotificationPermission() => 'unsupported';

Future<String> requestWebNotificationPermission() async => 'unsupported';

bool get isMobileWebBrowser => false;

bool get isSamsungBrowser => false;

bool get isIosWebBrowser => false;

void showWebForegroundNotification({
  required String title,
  String? body,
  Map<String, String>? data,
}) {}

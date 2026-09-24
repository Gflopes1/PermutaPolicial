import 'web_notification_utils_stub.dart'
    if (dart.library.js_interop) 'web_notification_utils_web.dart' as impl;

/// `granted`, `denied`, `default` ou `unsupported`.
String getWebNotificationPermission() => impl.getWebNotificationPermission();

Future<String> requestWebNotificationPermission() =>
    impl.requestWebNotificationPermission();

bool get isMobileWebBrowser => impl.isMobileWebBrowser;

bool get isSamsungBrowser => impl.isSamsungBrowser;

bool get isIosWebBrowser => impl.isIosWebBrowser;

void showWebForegroundNotification({
  required String title,
  String? body,
  Map<String, String>? data,
}) =>
    impl.showWebForegroundNotification(
      title: title,
      body: body,
      data: data,
    );

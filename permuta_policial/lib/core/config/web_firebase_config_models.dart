class WebFirebaseRuntimeConfig {
  final String apiKey;
  final String appId;
  final String projectId;
  final String messagingSenderId;
  final String authDomain;
  final String storageBucket;
  final String vapidKey;

  const WebFirebaseRuntimeConfig({
    required this.apiKey,
    required this.appId,
    required this.projectId,
    required this.messagingSenderId,
    required this.authDomain,
    required this.storageBucket,
    required this.vapidKey,
  });

  bool get isValid =>
      apiKey.isNotEmpty &&
      appId.isNotEmpty &&
      projectId.isNotEmpty &&
      messagingSenderId.isNotEmpty &&
      vapidKey.isNotEmpty;
}

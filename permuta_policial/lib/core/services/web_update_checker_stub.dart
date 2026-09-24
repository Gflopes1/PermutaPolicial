typedef WebUpdateAvailableCallback = void Function(String buildId);

void registerWebUpdateListener(WebUpdateAvailableCallback callback) {}

void registerWebUpdateClearedListener(void Function() callback) {}

void triggerWebUpdateCheck() {}

Future<void> applyWebUpdate() async {}

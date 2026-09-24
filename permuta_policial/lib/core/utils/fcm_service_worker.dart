import 'fcm_service_worker_stub.dart'
    if (dart.library.js_interop) 'fcm_service_worker_web.dart' as impl;

Future<void> ensureFcmServiceWorkerReady() => impl.ensureFcmServiceWorkerReady();

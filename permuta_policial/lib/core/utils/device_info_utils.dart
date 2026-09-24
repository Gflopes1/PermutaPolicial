import 'device_info_models.dart';
import 'device_info_utils_stub.dart'
    if (dart.library.js_interop) 'device_info_utils_web.dart' as impl;

export 'device_info_models.dart' show DeviceInfoSnapshot;

DeviceInfoSnapshot getDeviceInfo() => impl.getDeviceInfo();

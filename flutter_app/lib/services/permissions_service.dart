import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsService {
  Future<bool> ensureBlePermissions() async {
    if (kIsWeb || !Platform.isAndroid) {
      return true;
    }

    final Map<Permission, PermissionStatus> results = await <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    return results.values.every((PermissionStatus status) => status.isGranted);
  }
}

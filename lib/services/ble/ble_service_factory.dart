import 'dart:io';
import 'ble_service.dart';
import 'ble_service_mobile.dart';
import 'ble_service_windows.dart';

class BleServiceFactory {
  static BleService create() {
    if (Platform.isWindows) {
      return BleServiceWindows();
    } else {
      // Android, iOS, and other platforms use flutter_blue_plus
      return BleServiceMobile();
    }
  }
}

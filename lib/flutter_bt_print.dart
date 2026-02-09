// You have generated a new plugin project without specifying the `--platforms`
// flag. A plugin project with no platform support was generated. To add a
// platform, run `flutter create -t plugin --platforms <platforms> .` under the
// same directory. You can also find a detailed instruction on how to add
// platforms in the `pubspec.yaml` at
// https://flutter.dev/to/pubspec-plugin-platforms.

import 'dart:typed_data';
export 'package:flutter_bt_print/device/bluetooth_device.dart';
import 'flutter_bt_print_platform_interface.dart';

class FlutterBtPrint {

  Future<String?> getPlatformVersion() {
    return FlutterBtPrintPlatform.instance.getPlatformVersion();
  }

  // 🔵 Bluetooth
  Future<bool> isConnected() {
    return FlutterBtPrintPlatform.instance.isConnected();
  }

  Future<List<Map<String, dynamic>>> getBondedDevices() {
    return FlutterBtPrintPlatform.instance.getBondedDevices();
  }

  Future<bool> connect(String address) {
    return FlutterBtPrintPlatform.instance.connect(address);
  }

  Future<void> disconnect() {
    return FlutterBtPrintPlatform.instance.disconnect();
  }

  // 🖨 Printing
  Future<void> printText(String text) {
    return FlutterBtPrintPlatform.instance.printText(text);
  }

  Future<void> printFile(Uint8List bytes) {
    return FlutterBtPrintPlatform.instance.printFile(bytes);
  }
}

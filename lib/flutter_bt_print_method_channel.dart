import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_bt_print_platform_interface.dart';

/// An implementation of [FlutterBtPrintPlatform] that uses method channels.
class MethodChannelFlutterBtPrint extends FlutterBtPrintPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_bt_print');

  static final FlutterBtPrintPlatform _instance = MethodChannelFlutterBtPrint();

  static FlutterBtPrintPlatform get instance => _instance;

  @override
  Future<bool> isConnected() async {
    final result = await methodChannel.invokeMethod<bool>('isConnected');
    return result ?? false;
  }

  @override
  Future<List<Map<String, dynamic>>> getBondedDevices() async {
    final List list = await methodChannel.invokeMethod('getBondedDevices');
    return list.cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  @override
  Future<bool> connect(String address) async {
    final result = await methodChannel.invokeMethod<bool>('connect', {
      'address': address,
    });
    return result ?? false;
  }

  @override
  Future<void> disconnect() async {
    await methodChannel.invokeMethod('disconnect');
  }

  @override
  Future<void> printText(String text) async {
    await methodChannel.invokeMethod('printText', {'text': text});
  }

  @override
  Future<void> printImage(Uint8List bytes) async {
    await methodChannel.invokeMethod('printImage', {'bytes': bytes});
  }

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}

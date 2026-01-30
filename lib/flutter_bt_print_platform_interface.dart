import 'dart:typed_data';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'flutter_bt_print_method_channel.dart';

abstract class FlutterBtPrintPlatform extends PlatformInterface {
  /// Constructs a FlutterBtPrintPlatform.
  FlutterBtPrintPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterBtPrintPlatform _instance = MethodChannelFlutterBtPrint();

  /// The default instance of [FlutterBtPrintPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterBtPrint].
  static FlutterBtPrintPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterBtPrintPlatform] when
  /// they register themselves.
  static set instance(FlutterBtPrintPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// 🔵 Bluetooth
  Future<bool> isConnected();

  Future<List<Map<String, dynamic>>> getBondedDevices();

  Future<bool> connect(String address);

  Future<void> disconnect();

  // 🖨 Printing
  Future<void> printText(String text);

  Future<void> printImage(Uint8List bytes);
}

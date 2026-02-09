import 'dart:typed_data';
import '../flutter_bt_print.dart';

class Printer {
  final FlutterBtPrint _plugin = FlutterBtPrint();

  Future<bool> connect(String address) {
    return _plugin.connect(address);
  }

  Future<void> disconnect() {
    return _plugin.disconnect();
  }

  Future<bool> get isConnected async {
    return _plugin.isConnected();
  }

  /// RAW BYTES PRINT (most important)
  Future<void> printBytes(Uint8List bytes) async {
    if (!await isConnected) {
      throw Exception('Printer not connected');
    }
    await _plugin.printFile(bytes);
  }
}

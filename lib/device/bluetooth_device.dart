export 'package:flutter_bt_print/device/bluetooth_device.dart';

class BluetoothDevice {
  final String name;
  final String address;
  final bool isConnected;

  BluetoothDevice({
    required this.name,
    required this.address,
    this.isConnected = false,
  });

  factory BluetoothDevice.fromMap(Map<String, dynamic> map) {
    return BluetoothDevice(
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      isConnected: map['isConnected'] ?? false,
    );
  }
}

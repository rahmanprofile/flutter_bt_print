import 'dart:core';

import 'package:rxdart/rxdart.dart';
import 'package:flutter_bt_print/flutter_bt_print.dart';

enum BTStatus { idle, connecting, connected, disconnected, error, printing }

class BluetoothController {
  final FlutterBtPrint _plugin = FlutterBtPrint();

  // Status Stream for premium UI triggers
  final BehaviorSubject<BTStatus> _status$ = BehaviorSubject<BTStatus>.seeded(BTStatus.idle);
  Stream<BTStatus> get status$ => _status$.stream;

  final BehaviorSubject<bool> _connection$ = BehaviorSubject<bool>.seeded(false);
  final BehaviorSubject<List<BluetoothDevice>> _devices$ = BehaviorSubject<List<BluetoothDevice>>.seeded([]);

  Stream<bool> get isConnected$ => _connection$.stream;
  Stream<List<BluetoothDevice>> get devices$ => _devices$.stream;
  bool get isConnected => _connection$.value;

  Future<void> loadDevices() async {
    try {
      final list = await _plugin.getBondedDevices();
      final devices = list.map(BluetoothDevice.fromMap).toList();
      _devices$.add(devices);
      _connection$.add(devices.any((e) => e.isConnected));
    } catch (e) {
      _status$.add(BTStatus.error);
    }
  }

  /// Print
  Future<void> printText(String text) async {
    if (!isConnected) return;

    _status$.add(BTStatus.printing);
    try {
      // The plugin typically uses printReceipt which takes a list of Map/JSON
      // or a raw string with specific alignment.
      // If your plugin version uses 'print', use this:
      await _plugin.printText(text);

      // If it requires a list of items, you'd use:
      // await _plugin.printReceipt([{"type": "text", "content": text}]);

      _status$.add(BTStatus.idle);
    } catch (e) {
      _status$.add(BTStatus.error);
      print("Printing error: $e");
    }
  }


  /// Sync actual connection from native hardware
  Future<void> syncConnection() async {
    try {
      final connected = await _plugin.isConnected();
      _connection$.add(connected);

      // Update status to idle or connected based on hardware state
      if (connected) {
        _status$.add(BTStatus.connected);
      } else {
        _status$.add(BTStatus.idle);
      }
    } catch (e) {
      _connection$.add(false);
      _status$.add(BTStatus.error);
    }
  }

  Future<void> connect(String address) async {
    // 1. Tell UI immediately to show "Establishing connection..."
    _status$.add(BTStatus.connecting);

    try {
      // This is the heavy part that's causing your 5197ms lag
      final ok = await _plugin.connect(address);

      if (ok) {
        _connection$.add(true);
        _status$.add(BTStatus.connected);
      } else {
        _connection$.add(false);
        _status$.add(BTStatus.error);
      }
    } catch (e) {
      // This catches the java.io.IOException from your logs
      _connection$.add(false);
      _status$.add(BTStatus.error);
    } finally {
      await loadDevices();
    }
  }

  Future<void> disconnect() async {
    await _plugin.disconnect();
    _connection$.add(false);
    _status$.add(BTStatus.disconnected);
    await loadDevices();
  }

  void dispose() {
    _status$.close();
    _connection$.close();
    _devices$.close();
  }
}

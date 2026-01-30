// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_bt_print/flutter_bt_print.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// class Home extends StatefulWidget {
//   const Home({super.key});
//
//   @override
//   State<Home> createState() => _HomeState();
// }
//
// class _HomeState extends State<Home> {
//
//   var isConnected = false;
//
//   /// -------------------------------------
//
//   String _platformVersion = 'Unknown';
//   final _flutterBtPrintPlugin = FlutterBtPrint();
//
//   List<BluetoothDevice> _devices = [];
//   BluetoothDevice? _selectedDevice;
//   bool _connected = false;
//
//   @override
//   void initState() {
//     super.initState();
//     requestPermissions().then((granted) {
//       if (granted) fetchDevices();
//     });
//   }
//
//   /// Request required permissions
//   Future<bool> requestPermissions() async {
//     Map<Permission, PermissionStatus> statuses = await [
//       Permission.bluetooth,
//       Permission.bluetoothConnect,
//       Permission.bluetoothScan,
//       Permission.location,
//     ].request();
//     return statuses.values.every((status) => status.isGranted);
//   }
//
//   /// Fetch bonded (paired) devices
//   Future<void> fetchDevices() async {
//     try {
//       List<Map<String, dynamic>> bonded = await _flutterBtPrintPlugin
//           .getBondedDevices();
//       setState(() {
//         _devices = bonded.map((e) => BluetoothDevice.fromMap(e)).toList();
//         print("view devices: ${_devices.map((e) => e.name).toList()}");
//       });
//       // Get platform version just for demo
//       String version =
//           await _flutterBtPrintPlugin.getPlatformVersion() ?? 'Unknown';
//       setState(() => _platformVersion = version);
//     } on PlatformException {
//       setState(() => _platformVersion = 'Failed to get devices');
//     }
//   }
//
//   /// Connect to selected device
//   // Future<void> connect() async {
//   //   if (_selectedDevice == null) return;
//   //   bool success = await _flutterBtPrintPlugin.connect(_selectedDevice!.address);
//   //   setState(() => _connected = success);
//   // }
//
//   Future<void> connect() async {
//     if (_selectedDevice == null) return;
//
//     final success = await _flutterBtPrintPlugin.connect(
//       _selectedDevice!.address,
//     );
//
//     print("view connected device: $success");
//
//     // double-check actual state
//     final actuallyConnected = await _flutterBtPrintPlugin.isConnected();
//
//     setState(() {
//       _connected = success && actuallyConnected;
//     });
//   }
//
//   /// Disconnect
//   Future<void> disconnect() async {
//     await _flutterBtPrintPlugin.disconnect();
//     setState(() => _connected = false);
//   }
//
//   /// Print demo text
//   Future<void> printDemo() async {
//     if (_connected) {
//       await _flutterBtPrintPlugin.printText("Hello from Flutter BT Print!");
//     }
//   }
//
//   /// Print text
//   Future<void> printText() async {
//     if (!_connected) return;
//     await _flutterBtPrintPlugin.printText(
//       "Hello Printer!\nFlutter BT Print\n----------------\n",
//     );
//   }
//
//   /// Print image (asset example)
//   Future<void> printImage() async {
//     if (!_connected) return;
//
//     final bytes = await rootBundle.load('assets/logo.png');
//     await _flutterBtPrintPlugin.printImage(bytes.buffer.asUint8List());
//   }
//
//   /// Print PDF (asset example)
//   Future<void> printPdf() async {
//     if (!_connected) return;
//
//     final pdfBytes = await rootBundle.load('assets/sample.pdf');
//     await _flutterBtPrintPlugin.printImage(pdfBytes.buffer.asUint8List());
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         centerTitle: true,
//         title: Text(
//           "flutter_bt_print",
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Text('Running on: $_platformVersion\n'),
//             DropdownButton<BluetoothDevice>(
//               hint: Text('Select a device'),
//               value: _selectedDevice,
//               isExpanded: true,
//               items: _devices.map((device) {
//                 return DropdownMenuItem(
//                   value: device,
//                   child: Text(device.name),
//                 );
//               }).toList(),
//               onChanged: (device) => setState(() => _selectedDevice = device),
//             ),
//             const SizedBox(height: 20),
//             Row(
//               children: [
//                 ElevatedButton(
//                   onPressed: _connected ? null : connect,
//                   child: Text(_connected ? 'Connected' : 'Connect'),
//                 ),
//                 const SizedBox(width: 10),
//                 ElevatedButton(
//                   onPressed: _connected ? disconnect : null,
//                   child: Text('Disconnect'),
//                 ),
//               ],
//             ),
//
//             Divider(),
//
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 ElevatedButton.icon(
//                   onPressed: printDemo,
//                   icon: Icon(Icons.text_fields),
//                   label: Text("Text"),
//                 ),
//                 ElevatedButton.icon(
//                   onPressed: _connected ? printImage : null,
//                   icon: Icon(Icons.image),
//                   label: Text("Image"),
//                 ),
//                 ElevatedButton.icon(
//                   onPressed: _connected ? printPdf : null,
//                   icon: Icon(Icons.picture_as_pdf),
//                   label: Text("PDF"),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

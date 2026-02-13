import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bt_print/flutter_bt_print.dart';
import 'package:permission_handler/permission_handler.dart';
import '../helper/bluetooth_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final BluetoothController bt = BluetoothController();
  BluetoothDevice? _selected;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
    bt.status$.listen((status) {
      if (!mounted) return;
      String msg = "";
      if (status == BTStatus.connecting) msg = "Establishing connection...";
      if (status == BTStatus.connected) msg = "Printer connected successfully!";
      if (status == BTStatus.disconnected) msg = "Printer disconnected.";
      if (status == BTStatus.error) msg = "Connection failed. Check printer.";
      if (msg.isNotEmpty) {
        PremiumToast.show(context, msg, status);
      }
    });
  }

  Future<void> _initBluetooth() async {
    final granted = await _requestPermissions();
    if (!granted) return;
    await bt.loadDevices();
    await bt.syncConnection();
  }

  Future<bool> _requestPermissions() async {
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
    return statuses.values.every((e) => e.isGranted);
  }

  @override
  void dispose() {
    bt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        toolbarHeight: 65,
        title: Column(
          children: [
            const Text("flutter_bt_print",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            Text(bt.systemOS, style: TextStyle(fontSize: 12)),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("Available Printers", Icons.bluetooth),
                const SizedBox(height: 12),
                _buildDeviceSelector(),
                const SizedBox(height: 24),
                _buildSectionHeader("Connection Status", Icons.settings_input_component),
                const SizedBox(height: 12),
                _buildConnectionCard(),
                const SizedBox(height: 24),
                _buildSectionHeader("Actions", Icons.print_rounded),
                const SizedBox(height: 12),
                _buildPrintActionCard(),
              ],
            ),
          ),
          StreamBuilder<BTStatus>(
            stream: bt.status$,
            builder: (context, snapshot) {
              final status = snapshot.data;
              if (status == BTStatus.connecting) {
                return Center(
                  child: CupertinoActivityIndicator(color: CupertinoColors.activeBlue),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.blueGrey,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: StreamBuilder<List<BluetoothDevice>>(
        stream: bt.devices$,
        builder: (context, snapshot) {
          final devices = snapshot.data ?? [];
          BluetoothDevice? currentSelection;
          try {
            currentSelection = devices.firstWhere(
              (d) => d.address == _selected?.address,
            );
          } catch (_) {
            currentSelection = null;
          }
          return DropdownButtonHideUnderline(
            child: DropdownButton<BluetoothDevice>(
              isExpanded: true,
              value: currentSelection,
              hint: const Text("Select a paired printer"),
              items: devices.map((data) {
                return DropdownMenuItem<BluetoothDevice>(
                  value: data,
                  child: Row(
                    children: [
                      Icon(Icons.print_rounded, size: 18,
                        color: data.isConnected ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 10),
                      Text(data.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (d) {
                setState(() => _selected = d);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectionCard() {
    return StreamBuilder<bool>(
      stream: bt.isConnected$,
      builder: (context, snapshot) {
        final connected = snapshot.data ?? false;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: connected
                ? LinearGradient(
                    colors: [Colors.green.shade600, Colors.green.shade400],
                  )
                : const LinearGradient(colors: [Colors.white, Colors.white]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    connected ? "Connected" : "Disconnected",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: connected ? Colors.white : Colors.black87,
                    ),
                  ),
                  Icon(
                    connected ? Icons.check_circle : Icons.error_outline,
                    color: connected ? Colors.white : Colors.redAccent,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildButton(
                      label: "Connect",
                      icon: Icons.link,
                      color: connected
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.blue,
                      textColor: connected ? Colors.white : Colors.white,
                      onPressed: connected
                          ? null
                          : () {
                              if (_selected == null) {
                                PremiumToast.show(
                                  context,
                                  "Select a printer first",
                                  BTStatus.error,
                                );
                                return;
                              }
                              bt.connect(_selected!.address);
                            },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildButton(
                      label: "Disconnect",
                      icon: Icons.link_off,
                      color: connected
                          ? Colors.white.withValues(alpha: 0.3)
                          : Colors.grey.shade200,
                      textColor: connected ? Colors.white : Colors.black54,
                      onPressed: connected ? bt.disconnect : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrintActionCard() {
    return StreamBuilder<bool>(
      stream: bt.isConnected$,
      builder: (context, snapshot) {
        final connected = snapshot.data ?? false;
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  "Ready to print receipts and labels using thermal technology.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: connected
                          ? Colors.black87
                          : Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: connected ? () => bt.selectPdfAndPrint() : null,
                    icon: const Icon(Icons.print, color: Colors.white),
                    label: const Text(
                      "PRINT TEST RECEIPT",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 50,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon, color: textColor, size: 20),
        label: Text(
          label,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class PremiumToast {
  static void show(BuildContext context, String message, BTStatus status) {
    Color bgColor;
    IconData icon;

    switch (status) {
      case BTStatus.connected:
        bgColor = const Color(0xFF2E7D32); // Deep Emerald
        icon = Icons.check_circle_outline;
        break;
      case BTStatus.disconnected:
        bgColor = const Color(0xFFC62828); // Premium Crimson
        icon = Icons.link_off;
        break;
      case BTStatus.connecting:
        bgColor = const Color(0xFF1565C0);
        icon = Icons.sync;
        break;
      case BTStatus.error:
        bgColor = Colors.orange.shade900;
        icon = Icons.warning_amber_rounded;
        break;
      default:
        bgColor = Colors.black87;
        icon = Icons.info_outline;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        // We use a Container for styling
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: bgColor.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

/*
* bt.printText(
                            "================================\n"
                            "        MY PROFILE\n"
                            "================================\n\n"
                            "Name   : Rahman\n"
                            "Role   : Full Stack Developer\n"
                            "Phone  : +91 8052399848\n"
                            "Email  : rahman.infodev@gmail.com\n\n"
                            "--------------------------------\n"
                            "SKILLS\n"
                            "--------------------------------\n"
                            "• Flutter / Dart\n"
                            "• Android (Java / Kotlin)\n"
                            "• REST APIs\n"
                            "• Firebase / AWS\n\n"
                            "--------------------------------\n"
                            "EXPERIENCE\n"
                            "--------------------------------\n"
                            "• 4+ Years Mobile Development\n"
                            "• Production Apps Published\n\n"
                            "--------------------------------\n"
                            "PRINT INFO\n"
                            "--------------------------------\n"
                            "Date : 30 Jan 2026\n"
                            "Time : 10:55 AM\n\n"
                            "================================\n"
                            "        THANK YOU 🙏\n"
                            "================================\n\n\n",
                          )
* */

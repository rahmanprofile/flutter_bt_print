import 'dart:core';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:printing/printing.dart';
import 'package:rxdart/rxdart.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_bt_print/flutter_bt_print.dart';

enum BTStatus { idle, connecting, connected, disconnected, error, printing }

class BluetoothController {
  final FlutterBtPrint _plugin = FlutterBtPrint();

  // Streams
  final BehaviorSubject<BTStatus> _status$ = BehaviorSubject<BTStatus>.seeded(
    BTStatus.idle,
  );

  Stream<BTStatus> get status$ => _status$.stream;

  final BehaviorSubject<bool> _connection$ = BehaviorSubject<bool>.seeded(
    false,
  );

  Stream<bool> get isConnected$ => _connection$.stream;

  final BehaviorSubject<List<BluetoothDevice>> _devices$ = BehaviorSubject<List<BluetoothDevice>>.seeded([]);

  Stream<List<BluetoothDevice>> get devices$ => _devices$.stream;

  bool get isConnected => _connection$.value;
  String systemOS = "";

  static const int printableWidthPx = 864;

  Future<void> loadDevices() async {
    try {
      await fetchDevice();
      final list = await _plugin.getBondedDevices();
      final devices = list.map(BluetoothDevice.fromMap).toList();
      _devices$.add(devices);
      _connection$.add(devices.any((e) => e.isConnected));
    } catch (e) {
      _status$.add(BTStatus.error);
      debugPrint("Error loading devices: $e");
    }
  }

  Future<void> fetchDevice() async {
    try {
      String? osPhone = await _plugin.getPlatformVersion();
      if (osPhone != null) systemOS = osPhone;
    } catch (e) {
      debugPrint("Error fetching device info: $e");
    }
  }

  Future<void> connect(String address) async {
    _status$.add(BTStatus.connecting);
    try {
      final ok = await _plugin.connect(address);
      if (ok) {
        _connection$.add(true);
        _status$.add(BTStatus.connected);
      } else {
        _connection$.add(false);
        _status$.add(BTStatus.error);
      }
    } catch (e) {
      _connection$.add(false);
      _status$.add(BTStatus.error);
      debugPrint("Error connecting: $e");
    } finally {
      await loadDevices();
    }
  }

  Future<void> disconnect() async {
    try {
      await _plugin.disconnect();
      _connection$.add(false);
      _status$.add(BTStatus.disconnected);
    } catch (e) {
      debugPrint("Error disconnecting: $e");
    } finally {
      await loadDevices();
    }
  }

  Future<void> syncConnection() async {
    try {
      final connected = await _plugin.isConnected();
      _connection$.add(connected);
      _status$.add(connected ? BTStatus.connected : BTStatus.idle);
    } catch (e) {
      _connection$.add(false);
      _status$.add(BTStatus.error);
      debugPrint("Error syncing connection: $e");
    }
  }

  // ==================== FILE PICKING ====================
  Future<File?> pickPdfFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.single.path == null) return null;

    final file = File(result.files.single.path!);
    if (file.path.split('.').last.toLowerCase() != 'pdf') {
      throw Exception('Invalid file type selected');
    }
    return file;
  }

  Future<Uint8List> renderPdfPageToImage(
    File pdf, {
    int pageIndex = 0,
    int dpi = 203,
  }) async {
    final pdfBytes = await pdf.readAsBytes();
    final pages = await Printing.raster(pdfBytes, dpi: 203).toList();
    if (pages.isEmpty) throw Exception('PDF has no pages');
    final pageImage = pages[pageIndex];
    return await pageImage.toPng();
  }

  Future<void> selectPdfAndPrint() async {
    final file = await pickPdfFile();
    if (file == null) return;
    final pdfBytes = await file.readAsBytes();
    await printPdf(pdfBytes);
  }

  // ==================== PRINTING ====================
  Future<void> printText(String text) async {
    if (!isConnected) throw Exception('Printer not connected');
    _status$.add(BTStatus.printing);
    try {
      await _plugin.printText(text);
      _status$.add(BTStatus.idle);
    } catch (e) {
      _status$.add(BTStatus.error);
      debugPrint("Error printing text: $e");
    }
  }

  Future<void> printFile({required Uint8List bytes}) async {
    if (!isConnected) throw Exception('Printer not connected');
    if (bytes.isEmpty) {
      _status$.add(BTStatus.error);
      return;
    }
    await _plugin.printFile(bytes);
  }


  Future<void> printPdf(Uint8List pdfBytes) async {
    if (!isConnected) throw Exception('Printer not connected');
    _status$.add(BTStatus.printing);
    try {
      final pages = await Printing.raster(pdfBytes, dpi: 300).toList();
      for (final page in pages) {
        final pngBytes = await page.toPng();
        img.Image? image = img.decodeImage(pngBytes);
        if (image == null) continue;
        final processed = _processForThermal(image);
        final finalBytes = Uint8List.fromList(img.encodePng(processed));
        await _plugin.printFile(finalBytes);
      }
      _status$.add(BTStatus.idle);
    } catch (e) {
      _status$.add(BTStatus.error);
    }
  }

  img.Image _applyThreshold(img.Image src, {int threshold = 165}) {
    final width = src.width;
    final height = src.height;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = src.getPixel(x, y);
        final luminance = img.getLuminance(pixel);

        final value = luminance < threshold ? 0 : 255;
        src.setPixelRgb(x, y, value, value, value);
      }
    }

    return src;
  }


  img.Image _processForThermal(img.Image src) {
    final bg = _forceWhiteBackground(src);
    final gray = img.grayscale(bg);
    return _applyThreshold(gray, threshold: 140);
  }

  img.Image _forceWhiteBackground(img.Image src) {
    final bg = img.Image(width: src.width, height: src.height);
    img.fill(bg, color: img.ColorRgb8(255, 255, 255));
    img.compositeImage(bg, src);
    return bg;
  }

  void dispose() {
    _status$.close();
    _connection$.close();
    _devices$.close();
  }
}

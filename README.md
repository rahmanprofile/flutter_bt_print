# flutter_bt_print

<p align="center">
  <img
    src="https://raw.githubusercontent.com/rahmanprofile/flutter_bt_print/main/assets/flutter_bt_print.png"
    width="300"
    alt="flutter_bt_print demo"
  />
</p>

A lightweight Flutter plugin for **Bluetooth thermal printing** using ESC/POS compatible printers.

This plugin allows Flutter applications to:

* Connect to Bluetooth thermal printers
* Print text
* Print images and files
* Print PDF content after raster conversion
* Manage printer connection state
* Work with most 58mm and 80mm thermal printers

---

## ✨ Features

* Bluetooth device discovery
* Connect / Disconnect printer
* Print text
* Print image / bitmap
* Print PDF files
* Stream-based connection status
* Optimized for thermal printers (203 DPI)
* Android & iOS support

---

## 🚀 Getting Started

Add the dependency in your `pubspec.yaml`:

```yaml
dependencies:
  flutter_bt_print:
```

Then run:

```bash
flutter pub get
```

---

## ⚠️ Important

Before using this package, **please check the example project** included in this repository.

The example demonstrates:

* Proper permission handling
* Bluetooth connection flow
* PDF to image conversion
* Thermal image processing
* Printing workflow

This is strongly recommended before integrating into production apps.

---

## 📦 Required Dependencies

This plugin internally or externally works together with:

```yaml
permission_handler:
rxdart:
file_picker:
printing:
image:
```

Make sure these packages are added when required in your project.

---

## 🔐 Permissions Required

Bluetooth printing requires runtime permissions.

---

### ✅ Android Permissions

Add the following permissions inside:

```
android/app/src/main/AndroidManifest.xml
```

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

#### Android Notes

* Required for Android 8.0+
* Android 12+ requires `BLUETOOTH_CONNECT` and `BLUETOOTH_SCAN`
* Location permission is required for Bluetooth device discovery

Make sure permissions are requested at runtime using `permission_handler`.

---

### ✅ iOS Permissions

Add the following keys inside:

```
ios/Runner/Info.plist
```

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app uses Bluetooth to connect and print to thermal printers.</string>

<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app uses Bluetooth to communicate with printers.</string>
```

#### iOS Notes

* Bluetooth permission prompt appears automatically
* Ensure Bluetooth capability is enabled

---

## 🖨️ Supported Printers

* ESC/POS compatible Bluetooth printers
* 58mm thermal printers
* 80mm (4-inch) thermal printers
* Common POS thermal printers

---

## 📄 Printing Workflow (Recommended)

For best results:

```
PDF → Raster Image (203 DPI)
      → Resize to printer width
      → Grayscale
      → Threshold / Dithering
      → Print
```

Thermal printers do not support direct PDF rendering.

---

## ✅ Example Usage

```dart
await printer.connect(address);
await printer.printText("Hello World");
```

For complete implementation, see the example project.

---

## ⚠️ Notes

* Thermal printers use heat, not ink.
* Paper quality directly affects print darkness.
* Use good quality thermal paper for best results.
* Image-based printing should be optimized before sending to printer.

---

## 📜 License

MIT License — Free for personal and commercial use.

See the LICENSE file for details.

---

## 🤝 Contributions

Pull requests and improvements are welcome.
Please open an issue before submitting major changes.

---

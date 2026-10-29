import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

export 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart' show BluetoothInfo;

enum PrinterError { permission, bluetoothOff, connect, failed, saleNotFound }

/// [code] lets the UI show the message in the user's language.
class PrinterException implements Exception {
  PrinterException(this.code);
  final PrinterError code;
  @override
  String toString() => 'PrinterException(${code.name})';
}

/// Bluetooth thermal printer. Only paired printers are used, so no location
/// permission or device scanning is needed: pair the printer in Android settings first.
class ThermalPrinter {
  static String? _connectedTo;

  static Future<void> _ready() async {
    if (Platform.isAndroid) {
      if (!(await Permission.bluetoothConnect.request()).isGranted) {
        throw PrinterException(PrinterError.permission);
      }
    }
    if (!await PrintBluetoothThermal.bluetoothEnabled) {
      throw PrinterException(PrinterError.bluetoothOff);
    }
  }

  static Future<List<BluetoothInfo>> paired() async {
    await _ready();
    return PrintBluetoothThermal.pairedBluetooths;
  }

  static Future<void> printBytes(String address, List<int> bytes) async {
    await _ready();
    if (_connectedTo != address || !await PrintBluetoothThermal.connectionStatus) {
      await PrintBluetoothThermal.disconnect;
      _connectedTo = null;
      if (!await PrintBluetoothThermal.connect(macPrinterAddress: address)) {
        throw PrinterException(PrinterError.connect);
      }
      _connectedTo = address;
    }
    if (!await PrintBluetoothThermal.writeBytes(bytes)) {
      _connectedTo = null;
      throw PrinterException(PrinterError.failed);
    }
  }
}

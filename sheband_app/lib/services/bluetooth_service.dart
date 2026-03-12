import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothIoTService {
  static Future<void> scanAndConnect() async {
    if (await FlutterBluePlus.isSupported == false) {
      print("Bluetooth not supported by this device");
      return;
    }

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

    FlutterBluePlus.onScanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.platformName == "SheBand") {
          _connectToDevice(r.device);
          FlutterBluePlus.stopScan();
          break;
        }
      }
    });
  }

  static Future<void> _connectToDevice(BluetoothDevice device) async {
    await device.connect();
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.notify) {
          await characteristic.setNotifyValue(true);
          characteristic.onValueReceived.listen((value) {
            if (value.isNotEmpty && value[0] == 1) {
              // Trigger SOS logic here
            }
          });
        }
      }
    }
  }
}
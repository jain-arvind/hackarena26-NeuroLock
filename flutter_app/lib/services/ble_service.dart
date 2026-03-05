import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/log_model.dart';
import '../utils/constants.dart';

class BleService extends ChangeNotifier {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _commandCharacteristic;

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;

  final List<LogModel> _logs = <LogModel>[];

  String _status = 'Disconnected';
  bool _isScanning = false;

  String get status => _status;
  bool get isConnected => _device != null && _commandCharacteristic != null;
  bool get isScanning => _isScanning;
  List<LogModel> get logs => List<LogModel>.unmodifiable(_logs);

  void _addLog(String message) {
    _logs.insert(0, LogModel(message: message));
    notifyListeners();
  }

  Future<void> scanAndConnect() async {
    if (isConnected || _isScanning) return;

    _isScanning = true;
    _status = 'Scanning...';
    notifyListeners();

    final Guid serviceGuid = Guid(BleConstants.serviceUuid);
    final Completer<BluetoothDevice?> found = Completer<BluetoothDevice?>();

    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
      for (final ScanResult result in results) {
        final String advName = result.advertisementData.advName;
        final String platformName = result.device.platformName;
        final bool nameMatch = advName == BleConstants.deviceName ||
            platformName == BleConstants.deviceName;

        if (nameMatch && !found.isCompleted) {
          found.complete(result.device);
          return;
        }
      }
    });

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 8),
        withServices: <Guid>[serviceGuid],
      );

      final BluetoothDevice? device = await found.future.timeout(
        const Duration(seconds: 9),
        onTimeout: () => null,
      );

      await FlutterBluePlus.stopScan();
      _scanSub?.cancel();
      _scanSub = null;
      _isScanning = false;

      if (device == null) {
        _status = 'Device not found';
        _addLog('Scan ended: no matching ESP32 found.');
        notifyListeners();
        return;
      }

      _addLog('Found ${device.platformName}. Connecting...');
      await _connect(device);
    } catch (e) {
      _isScanning = false;
      _status = 'Scan/connect failed';
      _addLog('Error: $e');
      notifyListeners();
    }
  }

  Future<void> _connect(BluetoothDevice device) async {
    await device.connect(timeout: const Duration(seconds: 10));

    _device = device;

    _connSub?.cancel();
    _connSub = device.connectionState.listen((BluetoothConnectionState state) {
      if (state == BluetoothConnectionState.disconnected) {
        _status = 'Disconnected';
        _commandCharacteristic = null;
        _device = null;
        _addLog('Device disconnected.');
      }
      notifyListeners();
    });

    final List<BluetoothService> services = await device.discoverServices();
    final String serviceUuid = BleConstants.serviceUuid;
    final String charUuid = BleConstants.commandCharacteristicUuid;

    for (final BluetoothService service in services) {
      if (service.uuid.str128.toLowerCase() == serviceUuid) {
        for (final BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.uuid.str128.toLowerCase() == charUuid) {
            _commandCharacteristic = characteristic;
            break;
          }
        }
      }
    }

    if (_commandCharacteristic == null) {
      _status = 'Characteristic not found';
      _addLog('Connected but command characteristic is missing.');
      notifyListeners();
      return;
    }

    _status = 'Connected';
    _addLog('Connected to ESP32 BLE service.');
    notifyListeners();
  }

  Future<void> sendCommand(String command) async {
    final BluetoothCharacteristic? ch = _commandCharacteristic;
    if (ch == null) {
      _addLog('Cannot send command; not connected.');
      return;
    }

    final List<int> payload = utf8.encode(command);
    await ch.write(payload, withoutResponse: false);
    _addLog('Sent: $command');
  }

  Future<void> disconnect() async {
    try {
      await _device?.disconnect();
    } catch (_) {}

    _connSub?.cancel();
    _scanSub?.cancel();
    _connSub = null;
    _scanSub = null;

    _commandCharacteristic = null;
    _device = null;
    _status = 'Disconnected';
    notifyListeners();
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _scanSub?.cancel();
    super.dispose();
  }
}

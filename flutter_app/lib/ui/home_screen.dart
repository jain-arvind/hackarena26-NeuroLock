import 'package:flutter/material.dart';

import '../services/ble_service.dart';
import '../utils/constants.dart';
import 'logs_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final BleService _bleService;

  @override
  void initState() {
    super.initState();
    _bleService = BleService();
  }

  @override
  void dispose() {
    _bleService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bleService,
      builder: (BuildContext context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('NeuroLock BLE Control'),
            actions: <Widget>[
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => LogsScreen(service: _bleService),
                    ),
                  );
                },
                icon: const Icon(Icons.history),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Status: ${_bleService.status}'),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: <Widget>[
                            ElevatedButton(
                              onPressed: _bleService.isScanning
                                  ? null
                                  : _bleService.scanAndConnect,
                              child: const Text('Scan & Connect'),
                            ),
                            OutlinedButton(
                              onPressed: _bleService.disconnect,
                              child: const Text('Disconnect'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _bleService.isConnected
                      ? () => _bleService.sendCommand(BleCommands.unlock)
                      : null,
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Unlock Door'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _bleService.isConnected
                      ? () => _bleService.sendCommand(BleCommands.lock)
                      : null,
                  icon: const Icon(Icons.lock),
                  label: const Text('Lock Door'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _bleService.isConnected
                      ? () => _bleService.sendCommand(BleCommands.alarmOn)
                      : null,
                  icon: const Icon(Icons.warning_amber),
                  label: const Text('Alarm ON'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _bleService.isConnected
                      ? () => _bleService.sendCommand(BleCommands.alarmOff)
                      : null,
                  icon: const Icon(Icons.notifications_off),
                  label: const Text('Alarm OFF'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

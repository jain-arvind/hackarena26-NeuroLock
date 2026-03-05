import 'package:flutter/material.dart';

import '../services/ble_service.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key, required this.service});

  final BleService service;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: service,
      builder: (BuildContext context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('BLE Logs')),
          body: ListView.separated(
            itemCount: service.logs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int index) {
              final log = service.logs[index];
              return ListTile(
                dense: true,
                title: Text(log.pretty),
              );
            },
          ),
        );
      },
    );
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';

class WifiService extends ChangeNotifier {
  String _status = 'Disconnected';
  String _baseUrl = '';

  String get status => _status;
  String get baseUrl => _baseUrl;
  bool get isConfigured => _baseUrl.isNotEmpty;

  void configureBaseUrl(String hostOrUrl) {
    final String raw = hostOrUrl.trim();
    if (raw.isEmpty) {
      _baseUrl = '';
      _status = 'Disconnected';
      notifyListeners();
      return;
    }

    _baseUrl = raw.startsWith('http://') || raw.startsWith('https://')
        ? raw
        : 'http://$raw';
    _status = 'Configured';
    notifyListeners();
  }

  Future<bool> _isReachable(String baseUrl) async {
    try {
      final http.Response ping = await http
          .get(Uri.parse('$baseUrl/ping'))
          .timeout(const Duration(milliseconds: 650));
      return ping.statusCode >= 200 && ping.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<String?> autoDiscoverHost() async {
    _status = 'Discovering ESP32...';
    notifyListeners();

    const List<String> mdnsHosts = <String>[
      'http://neurolock.local',
      'http://esp32.local',
    ];

    for (final String host in mdnsHosts) {
      if (await _isReachable(host)) {
        _baseUrl = host;
        _status = 'Connected';
        notifyListeners();
        return _baseUrl;
      }
    }

    final String? wifiIp = await NetworkInfo().getWifiIP();
    if (wifiIp == null || !wifiIp.contains('.')) {
      _status = 'Wi-Fi IP unavailable';
      notifyListeners();
      return null;
    }

    final List<String> parts = wifiIp.split('.');
    if (parts.length != 4) {
      _status = 'Invalid phone IP';
      notifyListeners();
      return null;
    }

    final String subnet = '${parts[0]}.${parts[1]}.${parts[2]}';

    const int batchSize = 24;
    int host = 2;
    while (host <= 254) {
      final List<Future<String?>> probes = <Future<String?>>[];
      for (int i = 0; i < batchSize && host <= 254; i++, host++) {
        final String candidate = 'http://$subnet.$host';
        probes.add(() async {
          if (await _isReachable(candidate)) {
            return candidate;
          }
          return null;
        }());
      }

      final List<String?> results = await Future.wait(probes);
      for (final String? match in results) {
        if (match != null) {
          _baseUrl = match;
          _status = 'Connected';
          notifyListeners();
          return _baseUrl;
        }
      }
    }

    _status = 'ESP32 not found';
    notifyListeners();
    return null;
  }

  Future<void> testConnection() async {
    if (!isConfigured) {
      _status = 'Missing host/IP';
      notifyListeners();
      return;
    }

    _status = 'Testing...';
    notifyListeners();

    final bool ok = await _isReachable(_baseUrl);
    _status = ok ? 'Connected' : 'Not reachable';
    notifyListeners();
  }

  Future<void> sendCommand(String command) async {
    if (!isConfigured) {
      throw Exception('Set ESP32 host/IP first.');
    }

    final String cmd = command.trim().toUpperCase();

    try {
      final http.Response response = await http
          .post(
            Uri.parse('$_baseUrl/command'),
            headers: <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(<String, String>{'command': cmd}),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _status = 'Connected';
        notifyListeners();
        return;
      }
    } catch (_) {}

    final String endpoint = cmd.toLowerCase().replaceAll('_', '-');
    final http.Response fallback = await http
        .get(Uri.parse('$_baseUrl/$endpoint'))
        .timeout(const Duration(seconds: 4));

    if (fallback.statusCode < 200 || fallback.statusCode >= 300) {
      throw Exception('Wi-Fi command failed (${fallback.statusCode}).');
    }

    _status = 'Connected';
    notifyListeners();
  }
}

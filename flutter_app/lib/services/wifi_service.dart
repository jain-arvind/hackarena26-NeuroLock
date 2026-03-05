import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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

  Future<void> testConnection() async {
    if (!isConfigured) {
      _status = 'Missing host/IP';
      notifyListeners();
      return;
    }

    try {
      final http.Response response = await http
          .get(Uri.parse('$_baseUrl/ping'))
          .timeout(const Duration(seconds: 3));
      _status = response.statusCode >= 200 && response.statusCode < 300
          ? 'Connected'
          : 'Not reachable (${response.statusCode})';
    } catch (_) {
      _status = 'Not reachable';
    }
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

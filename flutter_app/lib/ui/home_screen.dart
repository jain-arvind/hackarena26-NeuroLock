import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/ble_service.dart';
import '../services/wifi_service.dart';
import '../utils/constants.dart';
import 'logs_screen.dart';

enum ConnectionMode { ble, wifi }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final BleService _bleService;
  late final WifiService _wifiService;
  late final AuthService _authService;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _wifiHostController = TextEditingController();

  String? _authError;
  String? _actionError;
  bool _isSigningIn = false;
  bool _isSending = false;
  ConnectionMode _mode = ConnectionMode.ble;

  @override
  void initState() {
    super.initState();
    _bleService = BleService();
    _wifiService = WifiService();
    _authService = AuthService();
  }

  @override
  void dispose() {
    _bleService.dispose();
    _wifiService.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _wifiHostController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _isSigningIn = true;
      _authError = null;
    });

    try {
      await _authService.signInWithEduEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted) setState(() {});
    } on FirebaseAuthException catch (e) {
      setState(() => _authError = e.message ?? e.code);
    } catch (_) {
      setState(() => _authError = 'Sign-in failed.');
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isSigningIn = true;
      _authError = null;
    });

    try {
      await _authService.signInWithGoogleEdu();
      if (mounted) setState(() {});
    } on FirebaseAuthException catch (e) {
      setState(() => _authError = e.message ?? e.code);
    } catch (_) {
      setState(() => _authError = 'Google sign-in failed.');
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  Future<void> _sendCommand(String command) async {
    setState(() {
      _isSending = true;
      _actionError = null;
    });

    try {
      if (_mode == ConnectionMode.ble) {
        await _bleService.sendCommand(command);
      } else {
        await _wifiService.sendCommand(command);
      }
    } catch (e) {
      setState(() => _actionError = '$e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  bool _canControl(User? user) {
    if (user == null || _isSending) return false;
    if (_mode == ConnectionMode.ble) return _bleService.isConnected;
    return _wifiService.isConfigured;
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _authService.currentUser;

    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[_bleService, _wifiService]),
      builder: (BuildContext context, _) {
        final String status = _mode == ConnectionMode.ble
            ? _bleService.status
            : _wifiService.status;

        return Scaffold(
          appBar: AppBar(
            title: const Text('NeuroLock Control'),
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (user == null) ...<Widget>[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const Text('Sign in with your .edu email'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(labelText: 'Email'),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration:
                                const InputDecoration(labelText: 'Password'),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _isSigningIn ? null : _signIn,
                            child: Text(_isSigningIn ? 'Signing in...' : 'Sign In'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: _isSigningIn ? null : _signInWithGoogle,
                            child: const Text('Continue with Google'),
                          ),
                          if (_authError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _authError!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...<Widget>[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: <Widget>[
                          Expanded(child: Text('Signed in: ${user.email ?? 'unknown'}')),
                          TextButton(
                            onPressed: () async {
                              await _authService.signOut();
                              if (mounted) setState(() {});
                            },
                            child: const Text('Sign out'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('Connection mode'),
                        const SizedBox(height: 8),
                        SegmentedButton<ConnectionMode>(
                          segments: const <ButtonSegment<ConnectionMode>>[
                            ButtonSegment<ConnectionMode>(
                              value: ConnectionMode.ble,
                              label: Text('BLE'),
                              icon: Icon(Icons.bluetooth),
                            ),
                            ButtonSegment<ConnectionMode>(
                              value: ConnectionMode.wifi,
                              label: Text('Wi-Fi'),
                              icon: Icon(Icons.wifi),
                            ),
                          ],
                          selected: <ConnectionMode>{_mode},
                          onSelectionChanged: (Set<ConnectionMode> selection) {
                            setState(() => _mode = selection.first);
                          },
                        ),
                        const SizedBox(height: 12),
                        Text('Status: $status'),
                        const SizedBox(height: 12),
                        if (_mode == ConnectionMode.ble)
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: <Widget>[
                              ElevatedButton(
                                onPressed: user == null || _bleService.isScanning
                                    ? null
                                    : _bleService.scanAndConnect,
                                child: const Text('Scan & Connect'),
                              ),
                              OutlinedButton(
                                onPressed: _bleService.disconnect,
                                child: const Text('Disconnect'),
                              ),
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              TextField(
                                controller: _wifiHostController,
                                decoration: const InputDecoration(
                                  labelText: 'ESP32 host/IP (e.g. 192.168.1.50:80)',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: <Widget>[
                                  ElevatedButton(
                                    onPressed: user == null
                                        ? null
                                        : () {
                                            _wifiService.configureBaseUrl(
                                              _wifiHostController.text,
                                            );
                                          },
                                    child: const Text('Set Host'),
                                  ),
                                  OutlinedButton(
                                    onPressed: user == null
                                        ? null
                                        : _wifiService.testConnection,
                                    child: const Text('Test Wi-Fi'),
                                  ),
                                  OutlinedButton(
                                    onPressed: user == null
                                        ? null
                                        : () async {
                                            final String? found =
                                                await _wifiService
                                                    .autoDiscoverHost();
                                            if (found != null && mounted) {
                                              _wifiHostController.text = found
                                                  .replaceFirst('http://', '');
                                            }
                                          },
                                    child: const Text('Auto Detect'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _canControl(user)
                      ? () => _sendCommand(BleCommands.unlock)
                      : null,
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Unlock Door'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _canControl(user)
                      ? () => _sendCommand(BleCommands.lock)
                      : null,
                  icon: const Icon(Icons.lock),
                  label: const Text('Lock Door'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _canControl(user)
                      ? () => _sendCommand(BleCommands.alarmOn)
                      : null,
                  icon: const Icon(Icons.warning_amber),
                  label: const Text('Alarm ON'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _canControl(user)
                      ? () => _sendCommand(BleCommands.alarmOff)
                      : null,
                  icon: const Icon(Icons.notifications_off),
                  label: const Text('Alarm OFF'),
                ),
                if (_actionError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _actionError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

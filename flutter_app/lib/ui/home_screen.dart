import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
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
  late final AuthService _authService;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _authError;
  bool _isSigningIn = false;

  @override
  void initState() {
    super.initState();
    _bleService = BleService();
    _authService = AuthService();
  }

  @override
  void dispose() {
    _bleService.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
    } on FirebaseAuthException catch (e) {
      setState(() => _authError = e.message ?? e.code);
    } catch (_) {
      setState(() => _authError = 'Sign-in failed.');
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _authService.currentUser;

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
                        Text('Status: ${_bleService.status}'),
                        const SizedBox(height: 12),
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
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: user != null && _bleService.isConnected
                      ? () => _bleService.sendCommand(BleCommands.unlock)
                      : null,
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Unlock Door'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: user != null && _bleService.isConnected
                      ? () => _bleService.sendCommand(BleCommands.lock)
                      : null,
                  icon: const Icon(Icons.lock),
                  label: const Text('Lock Door'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: user != null && _bleService.isConnected
                      ? () => _bleService.sendCommand(BleCommands.alarmOn)
                      : null,
                  icon: const Icon(Icons.warning_amber),
                  label: const Text('Alarm ON'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: user != null && _bleService.isConnected
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

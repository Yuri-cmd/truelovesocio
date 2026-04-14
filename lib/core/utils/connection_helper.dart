import 'package:flutter/material.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectionHelper extends StatefulWidget {
  const ConnectionHelper({super.key});

  @override
  State<ConnectionHelper> createState() => _ConnectionHelperState();
}

class _ConnectionHelperState extends State<ConnectionHelper> {
  bool _isConnected = true;
  late final Connectivity _connectivity;
  late final Stream<List<ConnectivityResult>> _connectivityStream;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _connectivityStream = _connectivity.onConnectivityChanged;

    _subscription = _connectivityStream.listen((List<ConnectivityResult> results) {
      final result =
          results.isNotEmpty
              ? results.first
              : ConnectivityResult.none;
      if (mounted) {
        setState(() {
          _isConnected = result != ConnectivityResult.none;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _isConnected ? Colors.green : Colors.red,
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      child: Center(
        child: Text(
          _isConnected ? 'Conexión estable' : 'Sin conexión a Internet',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
}

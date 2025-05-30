import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectionHelper extends StatefulWidget {
  const ConnectionHelper({super.key});

  @override
  State<ConnectionHelper> createState() => _ConnectionHelperState();
}

class _ConnectionHelperState extends State<ConnectionHelper> {
  bool _isConnected = true;
  late final Connectivity _connectivity;
  late final Stream<List<ConnectivityResult>>
  _connectivityStream; // <-- corregido

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _connectivityStream = _connectivity.onConnectivityChanged;

    _connectivityStream.listen((List<ConnectivityResult> results) {
      final result =
          results.isNotEmpty
              ? results.first
              : ConnectivityResult.none; // <- obtener el primer resultado
      setState(() {
        _isConnected = result != ConnectivityResult.none;
      });
    });
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

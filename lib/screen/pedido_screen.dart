import 'dart:async';
import 'package:flutter/material.dart';
import 'package:truelovesocio/components/pedido_card.dart';
import 'package:truelovesocio/model/pedido_model.dart';
import 'package:truelovesocio/model/socio_model.dart';
import 'package:truelovesocio/service/api_service.dart';
import 'package:truelovesocio/utils/pedidos_helper.dart';
// Importa el themeNotifier y setThemeMode si los usas globalmente
import 'package:truelovesocio/main.dart';

class PedidosView extends StatefulWidget {
  const PedidosView({super.key});

  @override
  State<PedidosView> createState() => _PedidosViewState();
}

class _PedidosViewState extends State<PedidosView> {
  List<Pedido> pedidos = [];
  final ApiService apiService = ApiService();
  Timer? timer;
  final Map<int, bool> _bloqueoBotones = {};
  int activo = 0;

  @override
  void initState() {
    super.initState();
    loadPedidos();
    timer = Timer.periodic(
      const Duration(seconds: 5),
      (Timer t) => loadPedidos(),
    );
    _loadEstado();
  }

  Future<void> _loadEstado() async {
    Socio? user = await ApiService.getLoggedUser();
    setState(() {
      activo = user!.activo;
    });
  }

  Future<void> loadPedidos() async {
    try {
      final data = await apiService.fetchPedidos();
      setState(() {
        pedidos = data;
      });
    } catch (e) {
      throw ('Error cargando pedidos: $e');
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pedidos Pendientes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          // Switch para dark/light theme
          Row(
            children: [
              Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: colorScheme.onPrimary),
              Switch(
                value: isDark,
                onChanged: (val) {
                  // setThemeMode es la función global que persiste y cambia theme
                  setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                },
              ),
              const SizedBox(width: 8),
              Text(
                activo == 1 ? "Activo" : "Inactivo",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimary,
                ),
              ),
              Switch(
                value: activo == 1,
                activeTrackColor: Colors.green,
                inactiveThumbColor: Colors.grey,
                onChanged: (value) {
                  PedidosHelper.cambiarEstadoRepartidor(
                    context,
                    activo,
                    (nuevo) => setState(() => activo = nuevo),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadPedidos,
        child: pedidos.isEmpty
            ? ListView(
                children: [
                  SizedBox(
                    height: 400,
                    child: Center(
                      child: Text(
                        '📭 Sin pedidos pendientes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                itemCount: pedidos.length,
                padding: const EdgeInsets.all(10),
                itemBuilder: (context, index) {
                  final pedido = pedidos[index];
                  return PedidoCard(
                    pedido: pedido,
                    apiService: apiService,
                    bloqueoBotones: _bloqueoBotones,
                    onUpdate: loadPedidos,
                    bloquearBoton: (bloqueado) {
                      setState(() {
                        _bloqueoBotones[pedido.id] = bloqueado;
                      });
                    },
                  );
                },
              ),
      ),
      backgroundColor: colorScheme.surface,
    );
  }
}
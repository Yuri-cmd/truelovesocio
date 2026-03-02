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

  Widget _buildTabContent(List<Pedido> tabPedidos, ColorScheme colorScheme) {
    return RefreshIndicator(
      onRefresh: loadPedidos,
      child: tabPedidos.isEmpty
          ? ListView(
              children: [
                SizedBox(
                  height: 400,
                  child: Center(
                    child: Text(
                      '📭 Sin pedidos en esta lista',
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
              itemCount: tabPedidos.length,
              padding: const EdgeInsets.all(10),
              itemBuilder: (context, index) {
                final pedido = tabPedidos[index];
                return GestureDetector(
                  onTap: () async {
                    final result = await PedidosHelper.navegarASeguimiento(
                      context,
                      pedido,
                    );
                    if (result == true) {
                      loadPedidos();
                    }
                  },
                  child: PedidoCard(
                    pedido: pedido,
                    apiService: apiService,
                    bloqueoBotones: _bloqueoBotones,
                    onUpdate: loadPedidos,
                    bloquearBoton: (bloqueado) {
                      setState(() {
                        _bloqueoBotones[pedido.id] = bloqueado;
                      });
                    },
                  ),
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final porAceptar = pedidos.where((p) => p.estado == '1').toList();
    final enPreparacion = pedidos.where((p) => p.estado == '2').toList();
    final porEntregar = pedidos.where((p) => p.estado != '1' && p.estado != '2').toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Órdenes activas',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Por Aceptar"),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${porAceptar.length}',
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              Tab(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("En Preparación"),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${enPreparacion.length}',
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              Tab(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Por Entregar"),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${porEntregar.length}',
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            // Switch para dark/light theme
            Row(
              children: [
                Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: colorScheme.onPrimary,
                ),
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
        body: TabBarView(
          children: [
            _buildTabContent(porAceptar, colorScheme),
            _buildTabContent(enPreparacion, colorScheme),
            _buildTabContent(porEntregar, colorScheme),
          ],
        ),
        backgroundColor: colorScheme.surface,
      ),
    );
  }
}

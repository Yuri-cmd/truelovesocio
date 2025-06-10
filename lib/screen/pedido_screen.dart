import 'dart:async';
import 'package:flutter/material.dart';
import 'package:truelovesocio/components/pedido_card.dart';
import 'package:truelovesocio/model/pedido_model.dart';
import 'package:truelovesocio/model/socio_model.dart';
import 'package:truelovesocio/service/api_service.dart';
import 'package:truelovesocio/theme/app_theme.dart';
import 'package:truelovesocio/utils/pedidos_helper.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pedidos Pendientes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                activo == 1 ? "Activo" : "Inactivo",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: activo == 1 ? Colors.white : Colors.white,
                ),
              ),
              Switch(
                value: activo == 1,
                activeThumbColor: Colors.white,
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
        child:
            pedidos.isEmpty
                ? ListView(
                  // Necesario para que RefreshIndicator funcione también cuando está vacío
                  children: const [
                    SizedBox(
                      height: 400, // Para permitir el scroll cuando está vacío
                      child: Center(
                        child: Text(
                          '📭 Sin pedidos pendientes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
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
      backgroundColor: Colors.grey[200],
    );
  }
}

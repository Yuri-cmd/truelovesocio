import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truelovesocio/core/components/pedido_card.dart';
import 'package:truelovesocio/features/auth/controllers/auth_controller.dart';
import 'package:truelovesocio/features/orders/controllers/orders_controller.dart';
import 'package:truelovesocio/main.dart';
import 'package:truelovesocio/data/models/pedido_model.dart';
import 'package:truelovesocio/core/utils/pedidos_helper.dart';

class PedidosView extends StatefulWidget {
  const PedidosView({super.key});

  @override
  State<PedidosView> createState() => _PedidosViewState();
}

class _PedidosViewState extends State<PedidosView> {
  final OrdersController controller = Get.put(OrdersController());
  final AuthController authController = Get.find<AuthController>();
  final Map<int, bool> _bloqueoBotones = {};
  final RxInt activo = 0.obs;

  @override
  void initState() {
    super.initState();
    _loadEstado();
  }

  void _loadEstado() {
    if (authController.socio.value != null) {
      activo.value = authController.socio.value!.activo;
    }
  }

  Widget _buildTabContent(List<Pedido> tabPedidos, ColorScheme colorScheme) {
    return RefreshIndicator(
      onRefresh: () => controller.loadActiveOrders(),
      child: Obx(() {
        if (tabPedidos.isEmpty) {
          return ListView(
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
          );
        }
        return ListView.builder(
          itemCount: tabPedidos.length,
          padding: const EdgeInsets.all(10),
          itemBuilder: (context, index) {
            final pedido = tabPedidos[index];
            return GestureDetector(
              onTap: () async {
                await PedidosHelper.navegarASeguimiento(pedido);
                controller.loadActiveOrders();
              },
              child: PedidoCard(
                pedido: pedido,
                bloqueoBotones: _bloqueoBotones,
                onUpdate: () => controller.loadActiveOrders(),
                bloquearBoton: (bloqueado) {
                  setState(() {
                    _bloqueoBotones[pedido.id] = bloqueado;
                  });
                },
              ),
            );
          },
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Órdenes activas', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(child: _buildTabLabel("Por Aceptar", controller.porAceptar)),
              Tab(child: _buildTabLabel("En Preparación", controller.enPreparacion)),
              Tab(child: _buildTabLabel("Por Entregar", controller.porEntregar)),
            ],
          ),
          actions: [
            Row(
              children: [
                Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: colorScheme.onPrimary),
                Switch(
                  value: isDark,
                  onChanged: (val) => themeNotifier.setTheme(val ? ThemeMode.dark : ThemeMode.light),
                ),
                const SizedBox(width: 8),
                Obx(() => Text(
                  activo.value == 1 ? "Activo" : "Inactivo",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.onPrimary),
                )),
                Obx(() => Switch(
                  value: activo.value == 1,
                  activeTrackColor: Colors.green,
                  inactiveThumbColor: Colors.grey,
                  onChanged: (value) {
                    PedidosHelper.cambiarEstadoRepartidor(
                      context,
                      activo.value,
                      (nuevo) => activo.value = nuevo,
                    );
                  },
                )),
              ],
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildTabContent(controller.porAceptar, colorScheme),
            _buildTabContent(controller.enPreparacion, colorScheme),
            _buildTabContent(controller.porEntregar, colorScheme),
          ],
        ),
        backgroundColor: colorScheme.surface,
      ),
    );
  }

  Widget _buildTabLabel(String text, RxList<Pedido> list) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(text),
        const SizedBox(height: 4),
        Obx(() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12)),
          child: Text('${list.length}', style: const TextStyle(fontSize: 12, color: Colors.white)),
        )),
      ],
    );
  }
}

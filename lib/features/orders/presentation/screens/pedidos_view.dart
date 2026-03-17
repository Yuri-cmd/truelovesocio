import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truelovesocio/core/components/pedido_card.dart';
import 'package:truelovesocio/features/auth/controllers/auth_controller.dart';
import 'package:truelovesocio/features/orders/controllers/orders_controller.dart';
import 'package:truelovesocio/data/models/pedido_model.dart';
import 'package:truelovesocio/core/utils/pedidos_helper.dart';
import 'package:truelovesocio/main.dart';

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
        backgroundColor: isDark ? null : const Color(0xFFF8F9FD),
        appBar: AppBar(
          title: const Text('Órdenes Activas', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          backgroundColor: Colors.red[700],
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.center,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.red[700],
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                tabs: [
                  _buildTabLabel("POR ACEPTAR", controller.porAceptar),
                  _buildTabLabel("PROCESO", controller.enPreparacion),
                  _buildTabLabel("ENTREGA", controller.porEntregar),
                ],
              ),
            ),
          ),
          actions: [
            Obx(() => Container(
              margin: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => themeNotifier.setTheme(isDark ? ThemeMode.light : ThemeMode.dark),
                    icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: Colors.white),
                    tooltip: 'Cambiar Tema',
                  ),
                  const VerticalDivider(color: Colors.white24, indent: 12, endIndent: 12, width: 8),
                  const SizedBox(width: 4),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        activo.value == 1 ? "RECIBIENDO" : "APAGADO",
                        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 0.5),
                      ),
                      Text(
                        activo.value == 1 ? "ACTIVO" : "INACTIVO",
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Transform.scale(
                    scale: 0.7,
                    child: Switch(
                      value: activo.value == 1,
                      activeThumbColor: Colors.greenAccent[400],
                      activeTrackColor: Colors.green[900],
                      inactiveThumbColor: Colors.grey[400],
                      inactiveTrackColor: Colors.black26,
                      onChanged: (value) {
                        PedidosHelper.cambiarEstadoRepartidor(
                          context,
                          activo.value,
                          (nuevo) => activo.value = nuevo,
                        );
                      },
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
        body: TabBarView(
          children: [
            _buildTabContent(controller.porAceptar, colorScheme),
            _buildTabContent(controller.enPreparacion, colorScheme),
            _buildTabContent(controller.porEntregar, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildTabLabel(String text, RxList<Pedido> list) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(text),
          const SizedBox(width: 6),
          Obx(() => Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: list.isNotEmpty ? Colors.black.withAlpha(40) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${list.length}',
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
            ),
          )),
        ],
      ),
    );
  }
}

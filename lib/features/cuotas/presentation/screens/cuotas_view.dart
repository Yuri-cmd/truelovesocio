import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:truelovesocio/features/cuotas/controllers/cuotas_controller.dart';
import 'package:truelovesocio/features/auth/controllers/auth_controller.dart';
import 'package:truelovesocio/data/models/cuota_model.dart';

class CuotasView extends GetView<CuotasController> {
  const CuotasView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(CuotasController());

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? null : Colors.grey[100],
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: controller.loadAllData,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!Get.find<AuthController>().puedeAcceder.value)
                        _buildAccesoRestringidoBanner(context),
                      const SizedBox(height: 16),
                      _buildPeriodoActualBanner(context),
                      const SizedBox(height: 24),
                      _buildSectionHeader(context, 'Configuración de mi Plan', Icons.settings_suggest),
                      const SizedBox(height: 12),
                      _buildCuotaPremiumCard(context),
                      const SizedBox(height: 24),
                      _buildPaymentInfoSection(context),
                      const SizedBox(height: 24),
                      _buildSectionHeader(context, 'Historial Mensual', Icons.history),
                      const SizedBox(height: 12),
                      _buildPeriodosGrid(context),
                      const SizedBox(height: 24),
                      _buildSectionHeader(context, 'Últimos Comprobantes', Icons.receipt_long),
                      const SizedBox(height: 12),
                      _buildPagosModernList(context),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Comisiones y Pagos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red, Color(0xFFD32F2F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.red),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 13, 
            fontWeight: FontWeight.w800, 
            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600], 
            letterSpacing: 1.1
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodoActualBanner(BuildContext context) {
    final data = controller.periodoActualData.value;
    if (data == null) return const SizedBox.shrink();

    final periodo = PeriodoCuota.fromJson(data['periodo']);
    final puedePagar = data['puede_pagar'] ?? false;
    final diasParaVencer = periodo.diasParaVencer ?? 99;
    final mostrarBoton = puedePagar && (diasParaVencer <= 3 || periodo.estaVencido);
    final color = periodo.estaVencido ? Colors.red : Colors.redAccent;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Theme.of(context).brightness == Brightness.dark ? Border.all(color: Colors.white12, width: 0.5) : null,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.black45 : color.withAlpha(25), 
            blurRadius: 20, 
            offset: const Offset(0, 10)
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(color: color.withAlpha(12), borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('PERÍODO ACTUAL', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                _buildStatusBadge(periodo.estado),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('S/ ${periodo.montoEsperado}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
                      Text(
                        periodo.estaVencido ? 'PAGO VENCIDO' : 'Vence en $diasParaVencer días',
                        style: TextStyle(
                          color: periodo.estaVencido ? Colors.red : (Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600]), 
                          fontSize: 12, 
                          fontWeight: FontWeight.w600
                        ),
                      ),
                    ],
                  ),
                ),
                if (mostrarBoton)
                  ElevatedButton(
                    onPressed: () => _showPagoDialog(context, periodo),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('PAGAR AHORA', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCuotaPremiumCard(BuildContext context) {
    final cuota = controller.cuotaActiva.value;
    if (cuota == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.grey[900]!, Colors.black], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mi Plan Truelove', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Icon(Icons.verified, color: Colors.blue[400], size: 24),
            ],
          ),
          const SizedBox(height: 20),
          _buildPremiumRow('Modalidad', cuota.tipoCuota == 'porcentaje' ? 'Porcentaje de ventas' : 'Monto Fijo'),
          const Divider(color: Colors.white10),
          _buildPremiumRow('Comisión', cuota.tipoCuota == 'porcentaje' ? '${cuota.porcentajeComision}%' : 'S/ ${cuota.montoCuota}'),
          const Divider(color: Colors.white10),
          _buildPremiumRow('Facturación', (cuota.diaPago == 0) ? 'Fin de periodo' : 'Cada día ${cuota.diaPago}'),
        ],
      ),
    );
  }

  Widget _buildPremiumRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPaymentInfoSection(BuildContext context) {
    final cuota = controller.cuotaActiva.value;
    if (cuota == null) return const SizedBox.shrink();

    return Column(
      children: [
        _buildInfoCard(context, 'Datos de Cuenta', Icons.account_balance, [
          {'label': 'Banco', 'value': cuota.banco ?? 'N/A'},
          {'label': 'Cuenta', 'value': cuota.numeroCuenta ?? 'N/A'},
          {'label': 'Tipo', 'value': cuota.tipoCuenta ?? 'N/A'},
        ]),
        const SizedBox(height: 16),
        if (cuota.numeroYape != null)
          _buildInfoCard(context, 'Yape/Plin', Icons.qr_code_scanner, [
            {'label': 'Número', 'value': cuota.numeroYape ?? 'N/A'},
            {'label': 'Titular', 'value': cuota.titularYape ?? 'N/A'},
          ], color: Theme.of(context).brightness == Brightness.dark ? Colors.purple.withAlpha(30) : Colors.purple[50]!, accentColor: Colors.purple),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, IconData icon, List<Map<String, String>> rows, {Color? color, Color accentColor = Colors.grey}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).cardColor, 
        borderRadius: BorderRadius.circular(20), 
        border: isDark ? Border.all(color: Colors.white12, width: 0.5) : null,
        boxShadow: [BoxShadow(color: isDark ? Colors.black45 : Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 5))]
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, color: accentColor == Colors.grey ? (isDark ? Colors.white70 : Colors.black87) : accentColor),
            title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: accentColor == Colors.grey ? (isDark ? Colors.white70 : Colors.black87) : accentColor)),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: rows.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(r['label']!, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  Text(r['value']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ]),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodosGrid(BuildContext context) {
    if (controller.periodos.isEmpty) return const Text('Sin registros');

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.5),
      itemCount: controller.periodos.length > 4 ? 4 : controller.periodos.length,
      itemBuilder: (context, index) {
        final p = controller.periodos[index];
        return InkWell(
          onTap: () => _showPedidosDetail(context, p),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor, 
              borderRadius: BorderRadius.circular(16),
              border: Theme.of(context).brightness == Brightness.dark ? Border.all(color: Colors.white12, width: 0.5) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Periodo #${p.numeroPeriodo}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                Text('S/ ${p.montoEsperado}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                _buildStatusBadge(p.estado, mini: true),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPagosModernList(BuildContext context) {
    if (controller.pagos.isEmpty) return const Text('Sin movimientos');

    return Column(
      children: controller.pagos.take(5).map((pago) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          color: Theme.of(context).cardColor,
          elevation: Theme.of(context).brightness == Brightness.dark ? 2 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: Theme.of(context).brightness == Brightness.dark ? const BorderSide(color: Colors.white12, width: 0.5) : BorderSide.none,
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.receipt_long, color: Colors.red),
                title: Text('S/ ${pago.montoPagado}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(DateFormat('dd MMM, yyyy').format(pago.fechaPago)),
                trailing: _buildStatusBadge(pago.estadoPago),
              ),
              TextButton.icon(
                onPressed: () => _showComprobante(context, pago.comprobantePago),
                icon: const Icon(Icons.visibility),
                label: const Text('Ver comprobante'),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusBadge(String estado, {bool mini = false}) {
    Color color = Colors.grey;
    if (estado == 'pagado' || estado == 'aprobado') color = Colors.green;
    if (estado == 'pendiente') color = Colors.orange;
    if (estado == 'en_revision') color = Colors.blue;
    if (estado == 'rechazado' || estado == 'vencido') color = Colors.red;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: mini ? 6 : 10, vertical: 2),
      decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(20)),
      child: Text(estado.toUpperCase(), style: TextStyle(color: color, fontSize: mini ? 8 : 10, fontWeight: FontWeight.bold)),
    );
  }

  void _showPedidosDetail(BuildContext context, PeriodoCuota periodo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(25))),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          expand: false,
          builder: (context, scrollController) => FutureBuilder<List<PedidoPeriodo>>(
            future: controller.getPedidosPeriodo(periodo.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final pedidos = snapshot.data ?? [];
              return Column(
                children: [
                  const SizedBox(height: 12),
                  const Text('Detalle de Comisiones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: pedidos.length,
                      itemBuilder: (context, index) {
                        final ped = pedidos[index];
                        return ListTile(
                          title: Text('Ref: ${ped.codigo ?? '---'}'),
                          subtitle: Text(ped.cliente),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('S/ ${ped.subtotal}'),
                              Text('Com: S/ ${ped.comision}', style: const TextStyle(color: Colors.red, fontSize: 10)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showPagoDialog(BuildContext context, PeriodoCuota periodo) {
    final montoCtrl = TextEditingController(text: periodo.montoEsperado);
    final operacionCtrl = TextEditingController();
    String metodo = 'yape';
    XFile? image;

    Get.bottomSheet(
      StatefulBuilder(builder: (context, setState) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(25))),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Registrar Pago', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: metodo,
                items: ['yape', 'transferencia', 'plin'].map((m) => DropdownMenuItem(value: m, child: Text(m.toUpperCase()))).toList(),
                onChanged: (val) => setState(() => metodo = val!),
                decoration: const InputDecoration(labelText: 'Método de Pago'),
              ),
              const SizedBox(height: 15),
              TextField(controller: montoCtrl, decoration: const InputDecoration(labelText: 'Monto depositado'), keyboardType: TextInputType.number),
              const SizedBox(height: 15),
              TextField(controller: operacionCtrl, decoration: const InputDecoration(labelText: 'Nro de Operación')),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      setState(() => image = picked);
                    }
                  } catch (e) {
                    Get.snackbar("Error", "No se pudo acceder a la galería: $e");
                  }
                },
                icon: Icon(image == null ? Icons.camera_alt : Icons.check_circle, color: image == null ? null : Colors.green),
                label: Text(image == null ? 'Subir Comprobante' : 'Imagen Seleccionada'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: image == null ? null : Colors.green.shade50,
                  foregroundColor: image == null ? null : Colors.green,
                ),
              ),
              const SizedBox(height: 30),
              Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isSubmitting.value ? null : () async {
                    if (image == null || operacionCtrl.text.isEmpty) {
                      Get.snackbar("Error", "Completa todos los datos (Imagen y Nro Operación)", snackPosition: SnackPosition.BOTTOM);
                      return;
                    }
                    await controller.registrarPago(
                      periodoId: periodo.id,
                      monto: montoCtrl.text,
                      operacion: operacionCtrl.text,
                      metodo: metodo,
                      image: image!,
                    );
                    // El controlador cierra el modal y muestra la alerta de confirmación
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, 
                    padding: const EdgeInsets.all(16),
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: controller.isSubmitting.value 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('ENVIAR REVISIÓN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )),
            ],
          ),
        ),
      )),
      isScrollControlled: true,
    );
  }

  Widget _buildAccesoRestringidoBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[700],
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACCESO RESTRINGIDO',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'Tu acceso a otras secciones está suspendido por falta de pago. Regulariza tu situación aquí.',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showComprobante(BuildContext context, String path) {
    final fullUrl = "https://magusemail.com/truelove-back/public/storage/$path";
    Get.dialog(Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.network(fullUrl),
          TextButton(onPressed: () => Get.back(), child: const Text('Cerrar')),
        ],
      ),
    ));
  }
}

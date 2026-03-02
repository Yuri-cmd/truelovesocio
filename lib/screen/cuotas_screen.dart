import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:truelovesocio/model/cuota_model.dart';
import 'package:truelovesocio/model/socio_model.dart';
import 'package:truelovesocio/service/api_service.dart';
import 'package:truelovesocio/theme/app_theme.dart';
import 'package:intl/intl.dart';

class CuotasScreen extends StatefulWidget {
  const CuotasScreen({super.key});

  @override
  State<CuotasScreen> createState() => _CuotasScreenState();
}

class _CuotasScreenState extends State<CuotasScreen> {
  bool _isLoading = true;
  Socio? _socio;
  CuotaActiva? _cuotaActiva;
  Map<String, dynamic>? _periodoActualData;
  List<PeriodoCuota> _periodos = [];
  List<PagoCuota> _pagos = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      _socio = await ApiService.getLoggedUser();
      if (_socio != null) {
        final results = await Future.wait([
          ApiService.getCuotaActiva(_socio!.id),
          ApiService.getMiPeriodoActual(_socio!.id),
          ApiService.getMisPeriodos(_socio!.id),
          ApiService.getMisPagos(_socio!.id),
        ]);

        setState(() {
          _cuotaActiva = results[0] as CuotaActiva?;
          _periodoActualData = results[1] as Map<String, dynamic>?;
          _periodos = results[2] as List<PeriodoCuota>;
          _pagos = results[3] as List<PagoCuota>;
        });
      }
    } catch (e) {
      debugPrint("Error loading cuotas data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text('Comisiones y Pagos',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    )),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primary, Color(0xFFD32F2F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodoActualBanner(),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Configuración de mi Plan', Icons.settings_suggest),
                    const SizedBox(height: 12),
                    _buildCuotaPremiumCard(),
                    const SizedBox(height: 24),
                    _buildPaymentInfoSection(),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Historial Mensual', Icons.history),
                    const SizedBox(height: 12),
                    _buildPeriodosGrid(),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Últimos Comprobantes', Icons.receipt_long),
                    const SizedBox(height: 12),
                    _buildPagosModernList(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.grey[600],
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodoActualBanner() {
    if (_periodoActualData == null) return const SizedBox.shrink();

    final periodo = PeriodoCuota.fromJson(_periodoActualData!['periodo']);
    final puedePagar = _periodoActualData!['puede_pagar'] ?? false;
    final diasParaVencer = periodo.diasParaVencer ?? 99;
    // Solo permitir pagar si faltan 3 días o menos, o si ya venció
    final mostrarBoton = puedePagar && (diasParaVencer <= 3 || periodo.estaVencido);
    final color = periodo.estaVencido ? Colors.red : AppTheme.primary;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PERÍODO ACTUAL',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                _buildModernStatusBadge(periodo.estado),
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
                      Text(
                        'S/ ${periodo.montoEsperado}',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1),
                      ),
                      Text(
                        periodo.estaVencido ? 'PAGO VENCIDO' : 'Vence en $diasParaVencer días',
                        style: TextStyle(
                          color: periodo.estaVencido ? Colors.red : Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (mostrarBoton)
                  ElevatedButton(
                    onPressed: () => _showPagoDialog(periodo),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('PAGAR AHORA', style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                else if (puedePagar && diasParaVencer > 3)
                  const Text(
                    'Disponible 3 días antes',
                    style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCuotaPremiumCard() {
    if (_cuotaActiva == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[900]!, Colors.black],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
          _buildPremiumRow(
            label: 'Modalidad de pago',
            value: _cuotaActiva!.tipoCuota == 'porcentaje' ? 'Porcentaje de ventas' : 'Monto Fijo mensual',
          ),
          const Divider(color: Colors.white10),
          _buildPremiumRow(
            label: 'Tasa/Comisión',
            value: _cuotaActiva!.tipoCuota == 'porcentaje' ? '${_cuotaActiva!.porcentajeComision}%' : 'S/ ${_cuotaActiva!.montoCuota}',
          ),
          const Divider(color: Colors.white10),
          _buildPremiumRow(
            label: 'Día de Facturación',
            value: 'Cada día ${_cuotaActiva!.diaPago}',
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance, color: Colors.white54, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Depósitos a: ${_cuotaActiva!.banco ?? 'No especificado'}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPaymentInfoSection() {
    if (_cuotaActiva == null) return const SizedBox.shrink();

    return Column(
      children: [
        _buildPaymentInfoCard(
          title: 'Datos de la Cuenta',
          icon: Icons.account_balance,
          rows: [
            {'label': 'Banco', 'value': _cuotaActiva!.banco ?? 'N/A'},
            {'label': 'Cuenta', 'value': _cuotaActiva!.numeroCuenta ?? 'N/A'},
            {'label': 'Tipo', 'value': _cuotaActiva!.tipoCuenta ?? 'N/A'},
          ],
        ),
        const SizedBox(height: 16),
        _buildPaymentMethodsCard(),
        const SizedBox(height: 16),
        if (_cuotaActiva!.numeroYape != null)
          _buildPaymentInfoCard(
            title: 'Datos de Yape',
            icon: Icons.qr_code_scanner,
            color: Colors.purple[50]!,
            accentColor: Colors.purple,
            rows: [
              {'label': 'Número', 'value': _cuotaActiva!.numeroYape ?? 'N/A'},
              {'label': 'Titular', 'value': _cuotaActiva!.titularYape ?? 'N/A'},
            ],
          ),
      ],
    );
  }

  Widget _buildPaymentInfoCard({
    required String title,
    required IconData icon,
    required List<Map<String, String>> rows,
    Color color = Colors.white,
    Color accentColor = Colors.grey,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 18, color: accentColor == Colors.grey ? Colors.grey[800] : accentColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: accentColor == Colors.grey ? Colors.grey[800] : accentColor,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: rows.map((row) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(row['label']!, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                      Text(row['value']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, size: 18, color: Colors.grey[800]),
              const SizedBox(width: 8),
              Text('Métodos de Pago', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[800])),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _cuotaActiva!.metodosPagoDisponibles.map((m) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  m.toUpperCase(),
                  style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumRow({required String label, required String value}) {
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

  Widget _buildPeriodosGrid() {
    if (_periodos.isEmpty) return const Center(child: Text('No hay registros'));

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: _periodos.length > 4 ? 4 : _periodos.length, // Mostrar los últimos 4
      itemBuilder: (context, index) {
        final p = _periodos[index];
        bool isCurrent = index == 0;
        return InkWell(
          onTap: _cuotaActiva?.tipoCuota == 'porcentaje' ? () => _showPedidosDetail(p) : null,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isCurrent ? Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 1.5) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Período #${p.numeroPeriodo}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'S/ ${p.montoEsperado}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                _buildModernStatusBadge(p.estado, mini: true),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPagosModernList() {
    if (_pagos.isEmpty) return const Text('Sin movimientos recientes');

    return Column(
      children: _pagos.take(5).map((pago) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getStatusColor(pago.estadoPago).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.receipt_long, color: _getStatusColor(pago.estadoPago), size: 20),
                ),
                title: Text('S/ ${pago.montoPagado}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: Text(DateFormat('dd MMM, yyyy').format(pago.fechaPago), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                trailing: _buildModernStatusBadge(pago.estadoPago),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 12),
                child: Row(
                  children: [
                    Icon(Icons.payment, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(pago.metodoPago.toUpperCase(), style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                    if (pago.numeroOperacion != null && pago.numeroOperacion!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text('Op: ${pago.numeroOperacion}', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),
              InkWell(
                onTap: () {
                  final baseUrl = "https://magusemail.com/truelove-back/public/storage/";
                  final fullUrl = "$baseUrl${pago.comprobantePago}";
                  
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: const EdgeInsets.all(10),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: InteractiveViewer(
                                minScale: 1.0,
                                maxScale: 4.0,
                                child: Image.network(
                                  fullUrl,
                                  fit: BoxFit.contain,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(40.0),
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) => const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(40.0),
                                      child: Text("No se pudo cargar la imagen"),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.black, size: 30),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.visibility_outlined, size: 16, color: Colors.red),
                      const SizedBox(width: 6),
                      const Text(
                        'Ver comprobante',
                        style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModernStatusBadge(String estado, {bool mini = false}) {
    Color color = _getStatusColor(estado);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: mini ? 6 : 10, vertical: mini ? 2 : 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(color: color, fontSize: mini ? 8 : 10, fontWeight: FontWeight.w800),
      ),
    );
  }

  Color _getStatusColor(String estado) {
    switch (estado) {
      case 'pagado':
      case 'aprobado':
        return const Color(0xFF4CAF50);
      case 'pendiente':
        return const Color(0xFFFF9800);
      case 'en_revision':
        return const Color(0xFF2196F3);
      case 'vencido':
      case 'rechazado':
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  void _showPedidosDetail(PeriodoCuota periodo) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => FutureBuilder<List<PedidoPeriodo>>(
            future: ApiService.getPedidosPeriodo(periodo.id, _socio!.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final pedidos = snapshot.data ?? [];
              return Column(
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                  ),
                  const Text('Detealle de Comisiones', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(DateFormat('MMMM yyyy').format(periodo.periodoInicio).toUpperCase(), 
                    style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold)),
                  const Divider(),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: pedidos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final ped = pedidos[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                                child: const Icon(Icons.shopping_basket, color: AppTheme.primary, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('REF: ${ped.codigo ?? '---'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text(ped.cliente, style: TextStyle(fontSize: 11, color: Colors.grey[600]), maxLines: 1),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('S/ ${ped.subtotal}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('Com: S/ ${ped.comision}', style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
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

  void _showPagoDialog(PeriodoCuota periodo) {
    TextEditingController montoCtrl = TextEditingController(text: periodo.montoEsperado);
    TextEditingController operacionCtrl = TextEditingController();
    TextEditingController obsCtrl = TextEditingController();
    String metodoSelected = _cuotaActiva?.metodosPagoDisponibles.first ?? 'yape';
    XFile? imageFile;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Declarar Pago', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('Sube tu comprobante de S/ ${periodo.montoEsperado}', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 24),
                
                // Form Fields
                DropdownButtonFormField<String>(
                  value: metodoSelected,
                  items: _cuotaActiva?.metodosPagoDisponibles.map((m) => DropdownMenuItem(value: m, child: Text(m.toUpperCase()))).toList(),
                  onChanged: (val) => setDialogState(() => metodoSelected = val!),
                  decoration: InputDecoration(
                    labelText: 'Método de Pago',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: montoCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Monto total depositado',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: operacionCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nro de Operación / Referencia',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Image Picker
                InkWell(
                  onTap: () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) setDialogState(() => imageFile = image);
                  },
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2), style: BorderStyle.solid),
                    ),
                    child: imageFile == null 
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, color: AppTheme.primary, size: 30),
                            SizedBox(height: 8),
                            Text('Toca para adjuntar foto', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        )
                      : const Center(child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 8), Text('IMAGEN CARGADA')],
                        )),
                  ),
                ),
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (imageFile == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adjunta la foto del voucher')));
                        return;
                      }
                      
                      bool success;
                      if (_cuotaActiva!.tipoCuota == 'porcentaje') {
                        success = await ApiService.subirComprobantePeriodo(
                          socioId: _socio!.id,
                          periodoId: periodo.id,
                          file: imageFile!,
                          fechaPago: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                          montoPagado: montoCtrl.text,
                          metodoPago: metodoSelected,
                          numeroOperacion: operacionCtrl.text,
                          observaciones: obsCtrl.text,
                        );
                      } else {
                        success = await ApiService.subirComprobante(
                          socioId: _socio!.id,
                          cuotaSocioId: _cuotaActiva!.id,
                          file: imageFile!,
                          fechaPago: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                          montoPagado: montoCtrl.text,
                          metodoPago: metodoSelected,
                          numeroOperacion: operacionCtrl.text,
                          observaciones: obsCtrl.text,
                        );
                      }

                      if (success && mounted) {
                        if(!context.mounted) return;
                        Navigator.pop(context);
                        _loadAllData();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Pago enviado a revisión')));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('ENVIAR COMPROBANTE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

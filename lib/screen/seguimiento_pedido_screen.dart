import 'package:flutter/material.dart';
import 'package:truelovesocio/model/pedido_model.dart';
import 'package:truelovesocio/service/api_service.dart';
import 'package:truelovesocio/theme/app_theme.dart';
import 'package:truelovesocio/utils/connection_helper.dart';
import 'package:url_launcher/url_launcher.dart'; // <- AGREGA ESTO

class SeguimientoPedidoView extends StatefulWidget {
  final Pedido pedido;

  const SeguimientoPedidoView({super.key, required this.pedido});

  @override
  State<SeguimientoPedidoView> createState() => _SeguimientoPedidoViewState();
}

class _SeguimientoPedidoViewState extends State<SeguimientoPedidoView> {
  double total = 0.0;
  final ApiService apiService = ApiService();
  @override
  void initState() {
    super.initState();
    _calcularTotal();
  }

  void _calcularTotal() {
    double tempTotal = 0.0;
    for (var detalle in widget.pedido.detalleArray) {
      double detalleTotal = double.parse(detalle.precio) * detalle.cantidad;
      tempTotal += detalleTotal;
    }
    total = tempTotal;
  }

  Future<void> _llamar(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    await launchUrl(launchUri);
  }

  Future<void> actualizarEstadoPedido(int id, int estado) async {
    bool confirmar = await mostrarAlertaConfirmacion(estado);
    if (!confirmar) return;
    try {
      await apiService.actualizarEstado(id, estado);
    } catch (e) {
      throw ('Error actualizando pedido: $e');
    }
  }

  // Método para mostrar la alerta de confirmación
  Future<bool> mostrarAlertaConfirmacion(int estado) async {
    return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirmación'),
              content: Text(
                estado == 0
                    ? '¿Estás seguro de cancelar este pedido?'
                    : '¿Marcar pedido como listo?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Sí'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: const Text(
          'Órdenes activas',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const ConnectionHelper(),
            const SizedBox(height: 10),
            _buildEstadoPedidoSection(),
            const SizedBox(height: 10),
            _buildDatosPedidoSection(),
            const SizedBox(height: 10),
            _buildButtonsActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonsActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildTimelineButton(
            'Aceptada\nTiempo Estimado Prep: ${(widget.pedido.tiempo).toString()} min',
            false,
            false,
          ),
          ['3', '4', '5', '6', '7', '8'].contains(widget.pedido.estado)
              ? _buildTimelineButton(
                'Indicar orden como preparada',
                false,
                true,
              )
              : _buildTimelineButton(
                'Indicar orden como preparada',
                true,
                false,
              ),
        ],
      ),
    );
  }

  Widget _buildEstadoPedidoSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('ACEPTADA', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildTimelineButtons(),
        ],
      ),
    );
  }

  Widget _buildTimelineButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ['3', '4', '5', '6', '7', '8'].contains(widget.pedido.estado)
            ? _buildTimelineButton('Indicar orden como preparada', false, true)
            : _buildTimelineButton('Indicar orden como preparada', true, false),
        Icon(Icons.keyboard_arrow_down_sharp, color: Colors.grey),
        ['5', '6', '7', '8'].contains(widget.pedido.estado)
            ? _buildTimelineButton('Motorizado llegó al negocio', false, true)
            : _buildTimelineButton('Motorizado llegó al negocio', true, false),
        Icon(Icons.keyboard_arrow_down_sharp, color: Colors.grey),
        ['6', '7', '8'].contains(widget.pedido.estado)
            ? _buildTimelineButton('Motorizado está en camino', false, true)
            : _buildTimelineButton('Motorizado está en camino', true, false),
      ],
    );
  }

  Widget _buildTimelineButton(String label, bool isLast, bool isBlack) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isBlack ? Colors.black : Colors.white,
        side: const BorderSide(color: Colors.grey),
        minimumSize: const Size(double.infinity, 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () {
        if (isLast) {
          if (widget.pedido.estado == '2') {
            actualizarEstadoPedido(widget.pedido.id, 3);
          }

          if (widget.pedido.estado == '4') {
            actualizarEstadoPedido(widget.pedido.id, 5);
          }
        }
      },
      child: Text(
        label,
        style: TextStyle(color: isBlack ? Colors.white : Colors.black),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDatosPedidoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildClienteCard(),
          const SizedBox(height: 10),
          if (widget.pedido.estado == '4') ...[_buildMotorizadoCard()],
          const SizedBox(height: 10),
          const Divider(),
          _buildProductosList(),
          const Divider(),
          _buildTotalRow(),
        ],
      ),
    );
  }

  Widget _buildClienteCard() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 5,
      child: ListTile(
        leading: const CircleAvatar(
          radius: 20,
          backgroundColor: Colors.blue,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(widget.pedido.cliente),
        trailing: ElevatedButton(
          onPressed: () {
            _llamar(widget.pedido.celular); // <- Asegúrate de tener este campo
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            minimumSize: const Size(30, 30),
          ),
          child: const Icon(Icons.call, color: Colors.white, size: 16),
        ),
      ),
    );
  }

  Widget _buildMotorizadoCard() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 5,
      child: ListTile(
        leading: const CircleAvatar(
          radius: 20,
          backgroundColor: Colors.orange,
          child: Icon(Icons.delivery_dining, color: Colors.white),
        ),
        title: Text(widget.pedido.motorizado),
        trailing: ElevatedButton(
          onPressed: () {
            _llamar(
              widget.pedido.celularMotorizado,
            ); // Aquí puedes pasar el número real del motorizado
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            minimumSize: const Size(30, 30),
          ),
          child: const Icon(Icons.call, color: Colors.white, size: 16),
        ),
      ),
    );
  }

  Widget _buildProductosList() {
    return Column(
      children:
          widget.pedido.detalleArray.map((detalle) {
            double detalleTotal =
                double.parse(detalle.precio) * detalle.cantidad;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '(${detalle.cantidad}) ${detalle.nombre}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    detalleTotal.toStringAsFixed(2),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildTotalRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text(
          'Total a cobrar: ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          total.toStringAsFixed(2),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }
}

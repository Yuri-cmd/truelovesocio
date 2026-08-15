import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truelovesocio/data/models/menu_model.dart';
import 'package:truelovesocio/data/services/adicional_service.dart';
import 'package:truelovesocio/features/agotados/presentation/widgets/agotar_hasta_sheet.dart';
import 'package:truelovesocio/features/menu/controllers/socio_menu_controller.dart';

class MarcarProductosAgotadosView extends StatefulWidget {
  const MarcarProductosAgotadosView({super.key});

  @override
  State<MarcarProductosAgotadosView> createState() => _MarcarProductosAgotadosViewState();
}

class _MarcarProductosAgotadosViewState extends State<MarcarProductosAgotadosView> {
  late final SocioMenuController _menuController;
  final AdicionalService _service = Get.find<AdicionalService>();

  final Set<int> _selectedIds = {};
  String _searchQuery = '';
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _menuController = Get.isRegistered<SocioMenuController>() ? Get.find<SocioMenuController>() : Get.put(SocioMenuController());
  }

  List<Menu> get _filteredDishes {
    final query = _searchQuery.toLowerCase();
    if (query.isEmpty) return _menuController.dishes;
    return _menuController.dishes.where((d) => d.titulo.toLowerCase().contains(query)).toList();
  }

  void _toggle(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _marcarAgotados() async {
    if (_selectedIds.isEmpty) return;
    final duracion = await showAgotarHastaSheet(context, titulo: 'Agotar estos productos hasta:');
    if (duracion == null) return;

    setState(() => _processing = true);
    try {
      await _service.marcarProductosAgotados(_selectedIds.toList(), duracion);
      for (final dish in _menuController.dishes) {
        if (_selectedIds.contains(dish.id)) dish.status = 'out-of-stock';
      }
      _menuController.dishes.refresh();
      setState(() => _selectedIds.clear());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Productos marcados como agotados')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al marcar como agotado: $e')));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _marcarDisponibles() async {
    if (_selectedIds.isEmpty) return;

    setState(() => _processing = true);
    try {
      await _service.marcarProductosDisponibles(_selectedIds.toList());
      for (final dish in _menuController.dishes) {
        if (_selectedIds.contains(dish.id)) dish.status = 'active';
      }
      _menuController.dishes.refresh();
      setState(() => _selectedIds.clear());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Productos marcados como disponibles')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al marcar como disponible: $e')));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('Marcar productos como agotados', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        final dishes = _filteredDishes;
        final count = _selectedIds.length;

        return Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Los productos seleccionados serán marcados como agotados durante el tiempo que reste del día o indique.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Buscar producto...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: (count == 0 || _processing) ? null : _marcarAgotados,
                          icon: const Icon(Icons.remove_shopping_cart_outlined, size: 16),
                          label: Text('Marcar $count producto${count == 1 ? '' : 's'} como agotado', textAlign: TextAlign.center),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.deepOrange, side: const BorderSide(color: Colors.deepOrange)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: (count == 0 || _processing) ? null : _marcarDisponibles,
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                          label: Text('Marcar $count producto${count == 1 ? '' : 's'} como desagotado', textAlign: TextAlign.center),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.green[700], side: BorderSide(color: Colors.green[700]!)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _processing
                  ? const Center(child: CircularProgressIndicator(color: Colors.red))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: dishes.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final dish = dishes[index];
                        final isAgotado = dish.status == 'out-of-stock';
                        return CheckboxListTile(
                          value: _selectedIds.contains(dish.id),
                          onChanged: (_) => _toggle(dish.id),
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(dish.titulo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text('S/ ${dish.precio}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          secondary: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isAgotado ? Colors.amber[100] : Colors.green[50],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isAgotado ? 'Agotado' : 'Ilimitado',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isAgotado ? Colors.amber[800] : Colors.green[700]),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }
}

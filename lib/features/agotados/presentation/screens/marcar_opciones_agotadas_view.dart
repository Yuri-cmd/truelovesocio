import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truelovesocio/data/services/adicional_service.dart';
import 'package:truelovesocio/features/adicionales/controllers/adicionales_controller.dart';
import 'package:truelovesocio/features/agotados/presentation/widgets/agotar_hasta_sheet.dart';

class MarcarOpcionesAgotadasView extends StatefulWidget {
  const MarcarOpcionesAgotadasView({super.key});

  @override
  State<MarcarOpcionesAgotadasView> createState() => _MarcarOpcionesAgotadasViewState();
}

class _MarcarOpcionesAgotadasViewState extends State<MarcarOpcionesAgotadasView> {
  late final AdicionalesController _adicionalesController;
  final AdicionalService _service = Get.find<AdicionalService>();

  final Set<int> _selectedIds = {};
  String _searchQuery = '';
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _adicionalesController = Get.isRegistered<AdicionalesController>() ? Get.find<AdicionalesController>() : Get.put(AdicionalesController());
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

  Future<void> _marcarAgotadas() async {
    if (_selectedIds.isEmpty) return;
    final duracion = await showAgotarHastaSheet(context, titulo: 'Agotar esta opción hasta:');
    if (duracion == null) return;

    setState(() => _processing = true);
    try {
      await _service.marcarOpcionesAgotadas(_selectedIds.toList(), duracion);
      await _adicionalesController.loadGrupos();
      setState(() => _selectedIds.clear());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opciones marcadas como agotadas')));
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
      await _service.marcarOpcionesDisponibles(_selectedIds.toList());
      await _adicionalesController.loadGrupos();
      setState(() => _selectedIds.clear());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opciones marcadas como disponibles')));
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
        title: const Text('Marcar opciones como agotadas', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (_adicionalesController.isLoading.value && _adicionalesController.grupos.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Colors.red));
        }

        final query = _searchQuery.toLowerCase();
        final grupos = _adicionalesController.grupos.where((g) => g.items.isNotEmpty).toList();
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
                  TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Buscar opción...',
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
                          onPressed: (count == 0 || _processing) ? null : _marcarAgotadas,
                          icon: const Icon(Icons.remove_shopping_cart_outlined, size: 16),
                          label: Text('Marcar $count como agotada', textAlign: TextAlign.center),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.deepOrange, side: const BorderSide(color: Colors.deepOrange)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: (count == 0 || _processing) ? null : _marcarDisponibles,
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                          label: Text('Marcar $count como disponible', textAlign: TextAlign.center),
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
                  : grupos.isEmpty
                      ? Center(
                          child: Text('No hay opciones/adicionales configurados aún', style: TextStyle(color: Colors.grey[500])),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: grupos.length,
                          itemBuilder: (context, index) {
                            final grupo = grupos[index];
                            final items = grupo.items.where((i) => query.isEmpty || i.titulo.toLowerCase().contains(query)).toList();
                            if (items.isEmpty) return const SizedBox.shrink();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  color: Colors.grey[200],
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  child: Text(
                                    grupo.nombre.toUpperCase(),
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey[700], letterSpacing: 0.5),
                                  ),
                                ),
                                ...items.map((item) {
                                  final isAgotado = item.status == 'out-of-stock';
                                  return CheckboxListTile(
                                    value: _selectedIds.contains(item.id),
                                    onChanged: (_) => _toggle(item.id),
                                    controlAffinity: ListTileControlAffinity.leading,
                                    title: Text(item.titulo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                    subtitle: Text('S/ ${item.precioGrupo.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
                                }),
                              ],
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

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truelovesocio/data/models/adicional_model.dart';
import 'package:truelovesocio/features/adicionales/controllers/adicionales_controller.dart';
import 'package:truelovesocio/features/adicionales/presentation/widgets/create_edit_adicional_dialog.dart';

class BibliotecaAdicionalesView extends GetView<AdicionalesController> {
  const BibliotecaAdicionalesView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AdicionalesController>()) {
      Get.put(AdicionalesController());
    }
    final searchQuery = ''.obs;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('Biblioteca de Adicionales', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: () => controller.loadAdicionales(), icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  onChanged: (v) => searchQuery.value = v,
                  decoration: InputDecoration(
                    hintText: 'Buscar adicionales...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: const Text(
                    'Crea aquí tus adicionales (ingredientes extras, salsas, etc). Luego agrégalos a un Grupo de Adicionales para asignarlo a tus productos.',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.adicionales.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: Colors.red));
              }
              final query = searchQuery.value.toLowerCase();
              final list = controller.adicionales.where((a) {
                if (query.isEmpty) return true;
                return a.titulo.toLowerCase().contains(query) || a.descripcion.toLowerCase().contains(query);
              }).toList();

              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 70, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('No hay adicionales', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _AdicionalCard(adicional: list[index]),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateEdit(context),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _openCreateEdit(BuildContext context, {Adicional? adicional}) {
    showDialog(
      context: context,
      builder: (_) => CreateEditAdicionalDialog(
        adicional: adicional,
        onSave: (titulo, descripcion, precio) {
          if (adicional == null) {
            return controller.createAdicional(titulo, descripcion, precio);
          }
          return controller.updateAdicional(adicional, titulo: titulo, descripcion: descripcion, precio: precio);
        },
      ),
    );
  }
}

class _AdicionalCard extends StatelessWidget {
  final Adicional adicional;
  const _AdicionalCard({required this.adicional});

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'out-of-stock':
        return Colors.amber[700]!;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Activo';
      case 'out-of-stock':
        return 'Agotado';
      default:
        return 'Inactivo';
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdicionalesController>();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withAlpha(10)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        adicional.titulo,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: _statusColor(adicional.status), borderRadius: BorderRadius.circular(20)),
                      child: Text(_statusLabel(adicional.status), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                if (adicional.descripcion.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(adicional.descripcion, style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 6),
                Text('S/ ${adicional.precio}', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.red[700])),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'active':
                case 'out-of-stock':
                case 'inactive':
                  controller.updateAdicional(adicional, status: value);
                  break;
                case 'edit':
                  Get.find<AdicionalesController>();
                  showDialog(
                    context: context,
                    builder: (_) => CreateEditAdicionalDialog(
                      adicional: adicional,
                      onSave: (titulo, descripcion, precio) =>
                          controller.updateAdicional(adicional, titulo: titulo, descripcion: descripcion, precio: precio),
                    ),
                  );
                  break;
                case 'delete':
                  _confirmDelete(context, controller, adicional);
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'active', child: Text('Activar')),
              PopupMenuItem(value: 'out-of-stock', child: Text('Marcar agotado')),
              PopupMenuItem(value: 'inactive', child: Text('Desactivar')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'edit', child: Text('Editar')),
              PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AdicionalesController controller, Adicional adicional) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar adicional?'),
        content: Text('Se eliminará "${adicional.titulo}" de todos los grupos.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.deleteAdicional(adicional.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

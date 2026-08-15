import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truelovesocio/data/models/adicional_model.dart';
import 'package:truelovesocio/features/adicionales/controllers/adicionales_controller.dart';
import 'package:truelovesocio/features/adicionales/presentation/widgets/create_edit_adicional_dialog.dart';

class GruposAdicionalesView extends GetView<AdicionalesController> {
  const GruposAdicionalesView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AdicionalesController>()) {
      Get.put(AdicionalesController());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('Grupos de Adicionales', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: () => controller.loadGrupos(), icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.grupos.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Colors.red));
        }
        if (controller.grupos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.layers_outlined, size: 70, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text('No hay grupos de adicionales', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Crea tu primer grupo para organizar tus adicionales', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ],
            ),
          );
        }

        return ReorderableListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          itemCount: controller.grupos.length,
          onReorder: (oldIndex, newIndex) {
            if (newIndex > oldIndex) newIndex--;
            final nuevoOrden = List<GrupoAdicional>.from(controller.grupos);
            final item = nuevoOrden.removeAt(oldIndex);
            nuevoOrden.insert(newIndex, item);
            controller.reordenarGrupos(nuevoOrden);
          },
          itemBuilder: (context, index) {
            final grupo = controller.grupos[index];
            return Padding(
              key: ValueKey(grupo.id),
              padding: const EdgeInsets.only(bottom: 10),
              child: _GrupoCard(grupo: grupo),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateGrupoDialog(context),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showCreateGrupoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _GrupoFormDialog(
        onSave: (nombre, minimo, maximo) => controller.createGrupo(nombre, minimo, maximo),
      ),
    );
  }
}

class _GrupoFormDialog extends StatefulWidget {
  final GrupoAdicional? grupo;
  final Future<bool> Function(String nombre, int minimo, int maximo) onSave;

  const _GrupoFormDialog({this.grupo, required this.onSave});

  @override
  State<_GrupoFormDialog> createState() => _GrupoFormDialogState();
}

class _GrupoFormDialogState extends State<_GrupoFormDialog> {
  late final TextEditingController _nombreController;
  late final TextEditingController _minimoController;
  late final TextEditingController _maximoController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.grupo?.nombre ?? '');
    _minimoController = TextEditingController(text: (widget.grupo?.minimo ?? 0).toString());
    _maximoController = TextEditingController(text: (widget.grupo?.maximo ?? 1).toString());
  }

  Future<void> _submit() async {
    final nombre = _nombreController.text.trim();
    final minimo = int.tryParse(_minimoController.text) ?? 0;
    final maximo = int.tryParse(_maximoController.text) ?? 1;

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El nombre es requerido')));
      return;
    }

    setState(() => _saving = true);
    final ok = await widget.onSave(nombre, minimo, maximo);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.grupo == null ? 'Crear Nuevo Grupo' : 'Editar Grupo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nombreController,
            decoration: const InputDecoration(labelText: 'Nombre del grupo *', hintText: 'Ej: Elige tu salsa'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minimoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Mínimo', helperText: '0 = opcional'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _maximoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Máximo'),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], foregroundColor: Colors.white),
          child: _saving
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(widget.grupo == null ? 'Crear Grupo' : 'Guardar'),
        ),
      ],
    );
  }
}

class _GrupoCard extends StatefulWidget {
  final GrupoAdicional grupo;
  const _GrupoCard({required this.grupo});

  @override
  State<_GrupoCard> createState() => _GrupoCardState();
}

class _GrupoCardState extends State<_GrupoCard> {
  bool _expanded = false;
  bool _addingExisting = false;
  bool _creatingNew = false;
  bool _loadingAvailable = false;
  List<GrupoAdicionalItem> _availableItems = [];
  int? _selectedItemId;
  final TextEditingController _precioController = TextEditingController();

  final controller = Get.find<AdicionalesController>();

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

  Future<void> _startAddExisting() async {
    setState(() {
      _addingExisting = true;
      _creatingNew = false;
      _loadingAvailable = true;
      _selectedItemId = null;
      _precioController.clear();
    });
    final items = await controller.getAvailableItems(widget.grupo.id);
    if (!mounted) return;
    setState(() {
      _availableItems = items;
      _loadingAvailable = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final grupo = widget.grupo;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withAlpha(10)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(_expanded ? Icons.expand_more_rounded : Icons.chevron_right_rounded, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(child: Text(grupo.nombre, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15), overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                              child: Text('${grupo.items.length} items', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${grupo.minimo == 0 ? 'Opcional' : 'Mínimo: ${grupo.minimo}'} | Máximo: ${grupo.maximo}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => _GrupoFormDialog(
                        grupo: grupo,
                        onSave: (nombre, minimo, maximo) => controller.updateGrupo(grupo, nombre: nombre, minimo: minimo, maximo: maximo),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                    onPressed: () => _confirmDeleteGrupo(context),
                  ),
                  const Icon(Icons.drag_handle_rounded, color: Colors.grey),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  if (grupo.items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('Este grupo no tiene adicionales', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                    )
                  else
                    ...grupo.items.map((item) => _buildItemRow(item)),
                  const SizedBox(height: 8),
                  if (_addingExisting)
                    _buildAddExistingForm()
                  else if (_creatingNew)
                    _buildCreateNewForm()
                  else
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _startAddExisting,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Agregar existente'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => setState(() {
                            _creatingNew = true;
                            _addingExisting = false;
                          }),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.green[700]),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Crear nuevo'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemRow(GrupoAdicionalItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(item.titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: _statusColor(item.status), borderRadius: BorderRadius.circular(20)),
                      child: Text(_statusLabel(item.status), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                Text('S/ ${item.precioGrupo.toStringAsFixed(2)}', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w700, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: Colors.red),
            onPressed: () => controller.removeItemFromGrupo(widget.grupo.id, item.id),
          ),
        ],
      ),
    );
  }

  Widget _buildAddExistingForm() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Seleccionar adicional existente', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 8),
          if (_loadingAvailable)
            const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2)))
          else if (_availableItems.isEmpty)
            const Text('No hay adicionales disponibles. Crea uno nuevo.', style: TextStyle(fontSize: 12, color: Colors.grey))
          else ...[
            DropdownButtonFormField<int>(
              initialValue: _selectedItemId,
              isExpanded: true,
              hint: const Text('Selecciona un adicional'),
              items: _availableItems
                  .map((i) => DropdownMenuItem(value: i.id, child: Text('${i.titulo} - S/ ${i.precio}', overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (val) {
                final item = _availableItems.firstWhereOrNull((i) => i.id == val);
                setState(() {
                  _selectedItemId = val;
                  _precioController.text = item?.precio ?? '';
                });
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _precioController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Precio en este grupo', isDense: true),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _selectedItemId == null
                      ? null
                      : () async {
                          final precio = double.tryParse(_precioController.text.replaceAll(',', '.')) ?? 0;
                          final ok = await controller.addItemToGrupo(widget.grupo.id, _selectedItemId!, precio);
                          if (ok && mounted) setState(() => _addingExisting = false);
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[600], foregroundColor: Colors.white),
                  child: const Text('Agregar'),
                ),
                const SizedBox(width: 8),
                TextButton(onPressed: () => setState(() => _addingExisting = false), child: const Text('Cancelar')),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCreateNewForm() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Crear nuevo adicional', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (_) => CreateEditAdicionalDialog(
                  onSave: (titulo, descripcion, precio) async {
                    final ok = await controller.createAdicional(titulo, descripcion, precio);
                    if (ok) {
                      final creado = controller.adicionales.firstWhereOrNull((a) => a.titulo == titulo);
                      if (creado != null) {
                        await controller.addItemToGrupo(widget.grupo.id, creado.id, precio);
                      }
                    }
                    return ok;
                  },
                ),
              );
              if (result == true && mounted) setState(() => _creatingNew = false);
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Abrir formulario'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white),
          ),
          TextButton(onPressed: () => setState(() => _creatingNew = false), child: const Text('Cancelar')),
        ],
      ),
    );
  }

  void _confirmDeleteGrupo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar grupo?'),
        content: Text('Se eliminará el grupo "${widget.grupo.nombre}" y todas sus relaciones con productos.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.deleteGrupo(widget.grupo.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

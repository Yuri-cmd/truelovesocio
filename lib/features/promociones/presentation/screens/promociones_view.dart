import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truelovesocio/data/models/promocion_model.dart';
import 'package:truelovesocio/features/promociones/controllers/promociones_controller.dart';
import 'package:truelovesocio/features/promociones/presentation/screens/create_edit_promocion_view.dart';

class PromocionesView extends GetView<PromocionesController> {
  const PromocionesView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? null : const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('Promociones', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => controller.loadPromociones(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const CreateEditPromocionView()),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.promociones.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Colors.red));
        }
        if (controller.promociones.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.campaign_outlined, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Todavía no tienes promociones',
                  style: TextStyle(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Crea la primera con el botón +',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: Colors.red,
          onRefresh: () => controller.loadPromociones(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            itemCount: controller.promociones.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final promocion = controller.promociones[index];
              return _PromocionItem(promocion: promocion, controller: controller);
            },
          ),
        );
      }),
    );
  }
}

class _PromocionItem extends StatelessWidget {
  final Promocion promocion;
  final PromocionesController controller;

  const _PromocionItem({required this.promocion, required this.controller});

  void _confirmDelete(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('¿Eliminar promoción?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.eliminarPromocion(promocion.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = promocion.estado;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: isDark
            ? Border.all(color: isActive ? Colors.red.withAlpha(40) : Colors.white12, width: 0.5)
            : Border.all(color: isActive ? Colors.red.withAlpha(20) : Colors.black.withAlpha(8)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.black.withAlpha(isActive ? 15 : 8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => Get.to(() => CreateEditPromocionView(promocion: promocion)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: promocion.imagen.isNotEmpty
                        ? Image.network(
                            promocion.imagen,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image_outlined, color: Colors.grey),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promocion.titulo,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isActive ? (isDark ? Colors.white : Colors.black87) : Colors.grey[500],
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        promocion.subtitulo,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isActive ? 'ACTIVA' : 'INACTIVA',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: isActive ? Colors.red[700] : Colors.grey[500],
                        letterSpacing: 0.5,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.grey),
                      onPressed: () => _confirmDelete(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

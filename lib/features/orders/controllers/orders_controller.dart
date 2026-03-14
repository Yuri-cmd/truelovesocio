import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truelovesocio/model/pedido_model.dart';
import 'package:truelovesocio/data/services/order_service.dart';
import 'package:truelovesocio/features/auth/controllers/auth_controller.dart';

class OrdersController extends GetxController {
  final OrderService _orderService = Get.find<OrderService>();
  final AuthController _authController = Get.find<AuthController>();
  
  final pedidos = <Pedido>[].obs;
  final isLoading = true.obs;
  final selectedFecha = 'todas'.obs;
  final selectedTipo = 'todos'.obs;
  
  final porAceptar = <Pedido>[].obs;
  final enPreparacion = <Pedido>[].obs;
  final porEntregar = <Pedido>[].obs;
  
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    loadActiveOrders();
    _startTimer();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => loadActiveOrders());
  }

  Future<void> loadActiveOrders() async {
    final socioId = _authController.socio.value?.id;
    if (socioId == null) return;

    try {
      final response = await _orderService.fetchPedidos(socioId, fecha: 'hoy');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final List<Pedido> loadedPedidos = data.map((p) => Pedido.fromJson(p)).toList();
        
        pedidos.assignAll(loadedPedidos);
        
        porAceptar.assignAll(loadedPedidos.where((p) => p.estado == '1').toList());
        enPreparacion.assignAll(loadedPedidos.where((p) => p.estado == '2').toList());
        porEntregar.assignAll(loadedPedidos.where((p) => p.estado != '1' && p.estado != '2').toList());
      }
    } catch (e) {
      debugPrint('Error en loadActiveOrders: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadFilteredOrders() async {
    final socioId = _authController.socio.value?.id;
    if (socioId == null) return;

    try {
      isLoading.value = true;
      final response = await _orderService.fetchPedidos(
        socioId,
        fecha: selectedFecha.value,
        tipo: selectedTipo.value,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        pedidos.assignAll(data.map((p) => Pedido.fromJson(p)).toList());
      }
    } catch (e) {
      Get.snackbar("Error", "No se pudieron cargar los pedidos: $e");
    } finally {
      isLoading.value = false;
    }
  }
}

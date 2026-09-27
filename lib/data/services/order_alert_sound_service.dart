import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Timbre en bucle para pedidos "por aceptar": suena sin parar mientras haya
/// al menos un pedido pendiente de aceptar, y se detiene en cuanto el socio
/// lo acepta (o lo rechaza). Antes el sonido solo se reproducía una vez, con
/// la notificación del sistema, y era fácil no notarlo con el celular guardado.
class OrderAlertSoundService {
  static final OrderAlertSoundService _instance = OrderAlertSoundService._internal();
  factory OrderAlertSoundService() => _instance;
  OrderAlertSoundService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _sonando = false;

  Future<void> start() async {
    if (_sonando) return;
    _sonando = true;
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('sounds/nuevo_pedido.wav'));
    } catch (e) {
      debugPrint('Error al reproducir el timbre de pedido: $e');
      _sonando = false;
    }
  }

  Future<void> stop() async {
    if (!_sonando) return;
    _sonando = false;
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('Error al detener el timbre de pedido: $e');
    }
  }

  void dispose() {
    _player.dispose();
  }
}

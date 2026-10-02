import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:truelovesocio/data/services/firebase_api.dart';

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
  StreamSubscription<void>? _onCompleteSub;

  Future<void> start() async {
    if (_sonando) return;
    _sonando = true;
    try {
      // La app ya está abierta y suena el timbre propio: se apaga el de la
      // notificación para que no suenen los dos a la vez.
      await FlutterLocalNotificationsPlugin().cancel(kNewOrderNotificationId);
    } catch (_) {}
    try {
      await _player.setReleaseMode(ReleaseMode.loop);

      // Salvavidas: en algunos dispositivos/versiones, ReleaseMode.loop no
      // reinicia la reproducción de forma nativa al terminar el clip (el
      // audio termina de sonar una sola vez y se queda callado). Si eso pasa,
      // este listener lo vuelve a poner desde el inicio manualmente. Si el
      // loop nativo sí funciona, este evento nunca llega y no hace nada.
      _onCompleteSub ??= _player.onPlayerComplete.listen((_) {
        if (_sonando) {
          _player.seek(Duration.zero);
          _player.resume();
        }
      });

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
      // Si había una notificación de pedido sonando en bucle, se apaga también.
      await FlutterLocalNotificationsPlugin().cancel(kNewOrderNotificationId);
    } catch (_) {}
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('Error al detener el timbre de pedido: $e');
    }
  }

  void dispose() {
    _onCompleteSub?.cancel();
    _player.dispose();
  }
}

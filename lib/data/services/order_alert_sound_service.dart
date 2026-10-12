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
  bool _reiniciando = false;
  StreamSubscription<void>? _onCompleteSub;
  StreamSubscription<AudioEvent>? _onErrorSub;

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
      _onCompleteSub ??= _player.onPlayerComplete.listen(
        (_) {
          if (_sonando) _reiniciar();
        },
        // Los errores nativos del reproductor (p. ej. Android MEDIA_ERROR_UNKNOWN -38) llegan por
        // este mismo flujo: sin manejador quedaban como errores sin capturar y se reportaban.
        onError: (Object e, [StackTrace? _]) => debugPrint('Error de audio del timbre: $e'),
      );

      // Si el reproductor nativo falla mientras debe sonar, se reinicia en vez de quedarse callado.
      _onErrorSub ??= _player.eventStream.listen(
        (_) {},
        onError: (Object e, [StackTrace? _]) {
          debugPrint('Error de audio del timbre: $e');
          if (_sonando) _reiniciar();
        },
      );

      await _player.play(AssetSource('sounds/nuevo_pedido.wav'));
    } catch (e) {
      debugPrint('Error al reproducir el timbre de pedido: $e');
      _sonando = false;
    }
  }

  /// Vuelve a poner el timbre desde cero. Usa play() y no seek()+resume(): sobre un
  /// reproductor ya terminado o liberado esas llamadas provocan el error nativo -38.
  Future<void> _reiniciar() async {
    if (_reiniciando) return;
    _reiniciando = true;
    try {
      await _player.stop();
      await Future.delayed(const Duration(milliseconds: 300));
      if (_sonando) {
        await _player.setReleaseMode(ReleaseMode.loop);
        await _player.play(AssetSource('sounds/nuevo_pedido.wav'));
      }
    } catch (e) {
      debugPrint('No se pudo reiniciar el timbre de pedido: $e');
    } finally {
      _reiniciando = false;
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
    _onErrorSub?.cancel();
    _player.dispose();
  }
}

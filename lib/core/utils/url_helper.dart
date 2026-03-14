import 'package:truelovesocio/core/constants/constants.dart';

class UrlHelper {
  static String fixUrl(String? url) {
    if (url == null || url.isEmpty || url == 'null' || url == '(Null)') return '';
    if (url.startsWith('http') || url.contains('magusemail.com')) return url;
    
    // Si empieza con /storage/, lo reemplazamos por el baseStorageUrl
    if (url.startsWith('/storage/')) {
      return url.replaceFirst('/storage/', Constants.baseStorageUrl);
    }
    
    // Si no empieza con http pero tiene storage en la ruta
    if (url.contains('storage/')) {
      final parts = url.split('storage/');
      return Constants.baseStorageUrl + parts.last;
    }

    // Caso genérico: si no es URL completa, asumimos que cuelga de la base de archivos
    // Eliminamos cualquier barra inicial para evitar duplicación
    String cleanUrl = url.startsWith('/') ? url.substring(1) : url;
    return Constants.baseStorageUrl + cleanUrl;
  }
}

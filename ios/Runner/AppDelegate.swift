import Flutter
import UIKit
import Photos
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Permite que la notificación se muestre mientras la app está abierta
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       willPresent notification: UNNotification,
                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    completionHandler([.alert, .badge, .sound])
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    if let messenger = engineBridge.pluginRegistry.registrar(forPlugin: "AppChannelDocuments")?.messenger() {
      let channel = FlutterMethodChannel(name: "app.channel.documents",
                                         binaryMessenger: messenger)

      channel.setMethodCallHandler({ [weak self]
        (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        if call.method == "saveFileToDownloads" {
          guard let args = call.arguments as? [String: Any],
                let path = args["path"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Argumentos inválidos", details: nil))
            return
          }

          self?.saveImageToGallery(path: path, result: result)
        } else {
          result(FlutterMethodNotImplemented)
        }
      })
    }
  }

  private func saveImageToGallery(path: String, result: @escaping FlutterResult) {
    let fileURL = URL(fileURLWithPath: path)
    guard let image = UIImage(contentsOfFile: path) else {
      result(FlutterError(code: "INVALID_IMAGE", message: "No se pudo cargar la imagen desde la ruta proporcionada", details: nil))
      return
    }

    PHPhotoLibrary.requestAuthorization { status in
      var isAuthorized = status == .authorized
      if #available(iOS 14, *) {
        isAuthorized = isAuthorized || (status == .limited)
      }
      
      if isAuthorized {
        PHPhotoLibrary.shared().performChanges({
          PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { success, error in
          DispatchQueue.main.async {
            if success {
              result("Galería de Fotos")
            } else {
              result(FlutterError(code: "SAVE_FAILED", message: error?.localizedDescription ?? "Error desconocido al guardar", details: nil))
            }
          }
        }
      } else {
        DispatchQueue.main.async {
          result(FlutterError(code: "PERMISSION_DENIED", message: "Permiso denegado para acceder a la galería", details: nil))
        }
      }
    }
  }
}

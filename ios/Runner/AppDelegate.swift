import Flutter
import UIKit
import Photos

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "app.channel.documents",
                                              binaryMessenger: controller.binaryMessenger)
    
    channel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "saveFileToDownloads" {
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Argumentos inválidos", details: nil))
          return
        }
        
        self.saveImageToGallery(path: path, result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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

import Flutter
import UIKit
import Vision
import CryptoKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      setupOcrChannel(controller: controller)
      setupSecurityChannel(controller: controller)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func setupOcrChannel(controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "bureaucracy_agent/ocr",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "recognizeText" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let args = call.arguments as? [String: Any],
        let path = args["path"] as? String,
        let image = UIImage(contentsOfFile: path)
      else {
        result(FlutterError(code: "bad_args", message: "Missing/invalid image path", details: nil))
        return
      }

      self.recognizeText(in: image) { text, error in
        if let error = error {
          result(FlutterError(code: "ocr_failed", message: error.localizedDescription, details: nil))
          return
        }
        result(text ?? "")
      }
    }
  }

  private func setupSecurityChannel(controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "bureaucracy_agent/security",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let strongSelf = self else {
        result(FlutterMethodNotImplemented)
        return
      }
      switch call.method {
      case "getSigningFingerprint":
        result(strongSelf.signingFingerprint())
      case "isDeviceCompromised":
        result(strongSelf.isDeviceCompromised())
      case "isAppStoreOrTestFlight":
        result(strongSelf.isAppStoreOrTestFlight())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func signingFingerprint() -> String? {
    let bundle = Bundle.main
    let identifier = bundle.bundleIdentifier ?? ""
    let version = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
    let data = "\(identifier)#\(version)".data(using: .utf8) ?? Data()
    let digest = SHA256.hash(data: data)
    return Data(digest).base64EncodedString()
  }
  private func isDeviceCompromised() -> Bool {
    #if targetEnvironment(simulator)
    return false
    #else
    let paths = [
      "/Applications/Cydia.app",
      "/Library/MobileSubstrate/MobileSubstrate.dylib",
      "/bin/bash",
      "/usr/sbin/sshd",
      "/etc/apt",
      "/private/var/lib/apt/"
    ]
    let isJailbroken =
      paths.contains(where: { FileManager.default.fileExists(atPath: $0) }) ||
      canOpen(cydia: true)
    return isJailbroken
    #endif
  }

  private func isAppStoreOrTestFlight() -> Bool {
    #if targetEnvironment(simulator)
    return false
    #else
    // Check if running from TestFlight or App Store
    // TestFlight receipts are in sandboxReceipt, App Store in StoreKit/receipt
    if let receiptURL = Bundle.main.appStoreReceiptURL {
      let receiptPath = receiptURL.path
      // TestFlight uses sandboxReceipt
      if receiptPath.contains("sandboxReceipt") {
        return true
      }
      // App Store receipt exists and is not sandbox
      if FileManager.default.fileExists(atPath: receiptPath) {
        return true
      }
    }
    return false
    #endif
  }

  private func canOpen(cydia: Bool) -> Bool {
    guard let url = URL(string: "cydia://package/com.example.package") else {
      return false
    }
    return UIApplication.shared.canOpenURL(url)
  }

  private func recognizeText(in image: UIImage, completion: @escaping (String?, Error?) -> Void) {
    guard let cgImage = image.cgImage else {
      completion(nil, NSError(domain: "ocr", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image"]))
      return
    }

    let request = VNRecognizeTextRequest { request, error in
      if let error = error {
        completion(nil, error)
        return
      }
      let observations = request.results as? [VNRecognizedTextObservation] ?? []
      let lines: [String] = observations.compactMap { obs in
        obs.topCandidates(1).first?.string
      }
      completion(lines.joined(separator: "\n"), nil)
    }

    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    request.recognitionLanguages = ["it-IT", "en-US"]

    DispatchQueue.global(qos: .userInitiated).async {
      let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
      do {
        try handler.perform([request])
      } catch {
        completion(nil, error)
      }
    }
  }
}

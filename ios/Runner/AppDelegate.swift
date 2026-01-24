import Flutter
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // On-device OCR via Apple's Vision framework.
    //
    // Flutter side calls MethodChannel('bureaucracy_agent/ocr') with method 'recognizeText'
    // and argument { path: <file path> }.
    if let controller = window?.rootViewController as? FlutterViewController {
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

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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
    // Italian-first, but allow English content as well.
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

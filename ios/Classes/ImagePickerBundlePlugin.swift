import Flutter
import UIKit
import PhotosUI

public class ImagePickerBundlePlugin: NSObject, FlutterPlugin, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
    
    var flutterResult: FlutterResult?
    var viewController: UIViewController?
    var multiImageLimit: Int = 1
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "image_picker_bundle", binaryMessenger: registrar.messenger())
        let instance = ImagePickerBundlePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        instance.viewController = UIApplication.shared.delegate?.window??.rootViewController
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        flutterResult = result
        switch call.method {
        case "pickFromGallery":
            pickSingleFromGallery()
        case "pickFromCamera":
            pickFromCamera()
        case "pickMultiFromGallery":
            if let args = call.arguments as? [String: Any],
               let limit = args["limit"] as? Int {
                multiImageLimit = limit
            }
            pickMultiFromGallery()
        case "recordVideo":
            recordVideo()
        case "pickVideoFromGallery":
            pickVideoFromGallery()
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Single Image from Gallery
    private func pickSingleFromGallery() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        picker.allowsEditing = false
        viewController?.present(picker, animated: true, completion: nil)
    }

    // MARK: - Camera
    private func pickFromCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            flutterResult?(nil)
            return
        }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.allowsEditing = false
        viewController?.present(picker, animated: true, completion: nil)
    }

    // MARK: - Multiple Images (iOS14+)
    private func pickMultiFromGallery() {
        if #available(iOS 14, *) {
            var config = PHPickerConfiguration()
            config.filter = .images
            config.selectionLimit = multiImageLimit
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = self
            viewController?.present(picker, animated: true, completion: nil)
        } else {
            pickSingleFromGallery()
        }
    }

    // MARK: - Record Video
    private func recordVideo() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            flutterResult?(nil)
            return
        }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = ["public.movie"]
        picker.videoQuality = .typeHigh
        picker.delegate = self
        viewController?.present(picker, animated: true, completion: nil)
    }

    // MARK: - Pick Video from Gallery
    private func pickVideoFromGallery() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = ["public.movie"]
        picker.videoQuality = .typeHigh
        picker.delegate = self
        viewController?.present(picker, animated: true, completion: nil)
    }

    // MARK: - UIImagePickerController Delegate
    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)

        if let image = info[.originalImage] as? UIImage {
            if let path = saveImageToTemp(image) {
                flutterResult?(path)
            } else {
                flutterResult?(nil)
            }
        } else if let videoURL = info[.mediaURL] as? URL {
            flutterResult?(videoURL.path)
        } else {
            flutterResult?(nil)
        }
    }

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        flutterResult?(nil)
    }

    // MARK: - PHPicker Delegate (iOS 14+)
    @available(iOS 14, *)
    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)

        if results.isEmpty {
            flutterResult?(nil)
            return
        }

        var filePaths: [String] = []
        let group = DispatchGroup()

        for item in results.prefix(multiImageLimit) {
            if item.itemProvider.canLoadObject(ofClass: UIImage.self) {
                group.enter()
                item.itemProvider.loadObject(ofClass: UIImage.self) { (reading, error) in
                    if let image = reading as? UIImage,
                       let path = self.saveImageToTemp(image) {
                        filePaths.append(path)
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            self.flutterResult?(filePaths)
        }
    }

    // MARK: - Save image to temp dir and return file path
    private func saveImageToTemp(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 1.0) else { return nil }
        let tempDir = NSTemporaryDirectory()
        let fileName = "IMG_\(Int(Date().timeIntervalSince1970)).jpg"
        let filePath = (tempDir as NSString).appendingPathComponent(fileName)
        do {
            try data.write(to: URL(fileURLWithPath: filePath))
            return filePath
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
}

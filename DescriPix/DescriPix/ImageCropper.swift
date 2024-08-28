import Mantis
import SwiftUI

struct ImageCropper: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    @Binding var cropShapeType: Mantis.CropShapeType
    @Binding var presetFixedRatioType: Mantis.PresetFixedRatioType

    class Coordinator: NSObject, CropViewControllerDelegate {
        var parent: ImageCropper

        init(_ parent: ImageCropper) {
            self.parent = parent
        }

        func cropViewControllerDidCrop(_ cropViewController: Mantis.CropViewController, cropped: UIImage, transformation: Transformation, cropInfo: CropInfo) {
                ImageStorage.shared.croppedImage = cropped // Salva l'immagine nel Singleton
                print("Image saved to ImageStorage")
        }

        func cropViewControllerDidCancel(_ cropViewController: Mantis.CropViewController, original: UIImage) {
            print("Crop operation was cancelled.")
            parent.presentationMode.wrappedValue.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        var config = Mantis.Config()
        config.cropViewConfig.cropShapeType = cropShapeType
        config.presetFixedRatioType = presetFixedRatioType
        config.showAttachedCropToolbar = false
        let cropViewController: CustomViewController = Mantis.cropViewController(image: self.image!, config: config)
        cropViewController.delegate = context.coordinator
        print("CropViewController has been initialized.")

        return UINavigationController(rootViewController: cropViewController)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Qui puoi aggiornare la UI del CropViewController se necessario
    }
}

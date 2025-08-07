import UIKit
import FirebaseStorage
import FirebaseMLModelDownloader
import FirebaseFirestore

class ImageAnalysisService {
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    
    func analyzeAndUploadImage(_ image: UIImage, userId: String, completion: @escaping (Result<(Int, String), Error>) -> Void) {
        uploadImage(image, userId: userId) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let imageUrl):
                self.analyzeWithCustomModel(image: image) { calories in
                    completion(.success((calories, imageUrl)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func uploadImage(_ image: UIImage, userId: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "ImageConversionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG data"])))
            return
        }
        
        let storageRef = storage.reference()
        let imageName = "\(UUID().uuidString).jpg"
        let userImagesRef = storageRef.child("user_images/\(userId)/\(imageName)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        userImagesRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            userImagesRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url.absoluteString))
                } else {
                    completion(.failure(NSError(domain: "DownloadURLError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])))
                }
            }
        }
    }
    
    private func analyzeWithCustomModel(image: UIImage, completion: @escaping (Int) -> Void) {
        // Option 1: Server-side processing (recommended)
        // This would typically involve:
        // 1. Uploading the image to a Cloud Function endpoint
        // 2. Processing it with a more powerful model on server
        // 3. Returning the analysis results
        
        // Option 2: On-device Core ML model
        // This would involve:
        // 1. Downloading the model using FirebaseMLModelDownloader
        // 2. Running inference locally
        
        // For demonstration purposes, here's a more sophisticated mock implementation
        // that simulates either approach:
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Simulate processing time
            Thread.sleep(forTimeInterval: 1.5)
            
            // Calculate mock calories based on image characteristics
            let sizeFactor = image.size.width * image.size.height
            let brightness = image.averageBrightness // You'd need to implement this
            let mockCalories = Int((sizeFactor * brightness) / 1000)
            
            // Ensure calories are within a reasonable range
            let clampedCalories = min(max(mockCalories, 50), 1500)
            
            DispatchQueue.main.async {
                completion(clampedCalories)
            }
        }
    }
}

// Extension to calculate average brightness (needed for the mock implementation)
extension UIImage {
    var averageBrightness: CGFloat {
        guard let cgImage = self.cgImage else { return 0 }
        let ciImage = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: "CIAreaAverage",
                             parameters: [kCIInputImageKey: ciImage, kCIInputExtentKey: CIVector(cgRect: ciImage.extent)])
        
        guard let outputImage = filter?.outputImage else { return 0 }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull!])
        context.render(outputImage,
                      toBitmap: &bitmap,
                      rowBytes: 4,
                      bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                      format: .RGBA8,
                      colorSpace: nil)
        
        return CGFloat(bitmap[0]) / 255.0
    }
}

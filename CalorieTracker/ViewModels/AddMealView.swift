import SwiftUI
import PhotosUI
import FirebaseStorage

struct AddMealView: View {
    @EnvironmentObject var mealViewModel: MealViewModel
    @Environment(\.dismiss) var dismiss

    @State private var selectedImage: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var notes = ""
    @State private var isUploading = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false

    // Input validation states
    @State private var isNotesValid = true
    @State private var isImageValid = true

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Photo Section
                Section(header: Text("Meal Photo").font(.subheadline)) {
                    PhotosPicker(
                        selection: $selectedImage,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label(
                            title: { Text("Choose Photo") },
                            icon: { Image(systemName: "photo") }
                        )
                    }
                    .onChange(of: selectedImage) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                imageData = data
                                isImageValid = true
                            } else {
                                imageData = nil
                                isImageValid = false
                            }
                        }
                    }

                    if let data = imageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(8)
                            .padding(.vertical, 4)
                    } else if !isImageValid {
                        Text("Invalid image. Please select another.")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

                // MARK: - Notes Section
                Section(header: Text("Notes").font(.subheadline)) {
                    TextField("Describe your meal (optional)", text: $notes)
                        .onChange(of: notes) { _ in
                            isNotesValid = true
                        }
                }

                // MARK: - Error Section
                if let errorMessage = errorMessage {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(errorMessage)
                                .foregroundColor(.primary)
                        }
                        .listRowBackground(Color.orange.opacity(0.1))
                    }
                }

                // MARK: - Save Button
                Section {
                    Button(action: saveMeal) {
                        HStack {
                            Spacer()
                            if isUploading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Save Meal")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid || isUploading)
                    .listRowBackground(isFormValid ? Color.blue : Color.gray.opacity(0.5))
                    .foregroundColor(.white)
                }
            }
            .navigationTitle("Add Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Upload Failed", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Unknown error occurred")
            }
        }
    }

    // MARK: - Form Validation
    private var isFormValid: Bool {
        imageData != nil && UIImage(data: imageData!) != nil
    }

    // MARK: - Save Meal Action
    private func saveMeal() {
        guard let data = imageData, let image = UIImage(data: data) else {
            errorMessage = "Please select a valid photo."
            isImageValid = false
            return
        }

        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        isUploading = true
        errorMessage = nil

        Task {
            do {
                try await mealViewModel.addMeal(image: image, notes: trimmedNotes)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = parseErrorMessage(error)
                    showErrorAlert = true
                    isUploading = false
                }
            }
        }
    }

    // MARK: - Error Message Parser
    private func parseErrorMessage(_ error: Error) -> String {
        let nsError = error as NSError

        if nsError.domain == StorageErrorDomain {
            if let code = StorageErrorCode(rawValue: nsError.code) {
                switch code {
                case .unauthorized:
                    return "Permission denied. Please log in again."
                case .retryLimitExceeded:
                    return "Network error. Please check your connection."
                case .cancelled:
                    return "Upload cancelled."
                case .unknown:
                    return "Unknown error occurred."
                default:
                    return "Storage error. Please try again."
                }
            }
        }

        switch nsError.code {
        case 401:
            return "You must be logged in to save meals."
        case 400:
            return "Invalid image format. Please try another photo."
        case -1:
            return "Account error. Please restart the app."
        case -2:
            return "Failed to save meal data."
        default:
            return "Failed to save meal. Please try again."
        }
    }
}




import SwiftUI
import PhotosUI

struct AddMealView: View {
    @EnvironmentObject var mealViewModel: MealViewModel
    @Environment(\.dismiss) private var dismiss
    var onSaved: (() -> Void)? = nil

    @State private var selectedImage: PhotosPickerItem?
    @State private var uiImage: UIImage?
    @State private var showPhotoPicker = false
    @State private var notes = ""
    @State private var isUploading = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    @FocusState private var notesFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Button {
                    notesFocused = false
                    Task { await pickPhoto() }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(.primary.opacity(0.15), lineWidth: 1)
                            .background(RoundedRectangle(cornerRadius: 14).fill(.secondary.opacity(0.08)))
                            .frame(height: 220)
                        
                        if let uiImage {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.title2)
                                Text("Tap to choose a photo")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .safeAreaPadding(.bottom, 8)

                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes").font(.headline)
                    TextField("Optional", text: $notes, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .focused($notesFocused)
                }
                
                HStack {
                    Spacer()
                    Button {
                        Task { await save() }
                    } label: {
                        if isUploading {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(16)
        }
        .navigationTitle("Add Meal")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 60) }
        
        
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Something went wrong.")
        }
    
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedImage, matching: .images)
        .task(id: selectedImage) {
            guard let item = selectedImage else { return }
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    uiImage = image
                }
            } catch {
                errorMessage = "Failed to load photo."
                showErrorAlert = true
            }
        }
}

    private func pickPhoto() async {
        showPhotoPicker = true
    }

    private func save() async {
        guard let uiImage else {
            errorMessage = "Please choose a photo first."
            showErrorAlert = true
            return
        }

        isUploading = true
        do {
            try await mealViewModel.addMeal(image: uiImage, notes: notes)
            await MainActor.run {
                isUploading = false
                onSaved?()
                dismiss()
            }
        } catch {
            await MainActor.run {
                isUploading = false
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
}

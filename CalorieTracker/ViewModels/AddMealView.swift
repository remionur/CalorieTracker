import SwiftUI
import PhotosUI

struct AddMealView: View {
    @EnvironmentObject var mealViewModel: MealViewModel
    @Environment(\.dismiss) private var dismiss
    var onSaved: (() -> Void)? = nil

    @State private var selectedImage: PhotosPickerItem?
    @State private var uiImage: UIImage?
    @State private var notes = ""
    @State private var isUploading = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    @FocusState private var notesFocused: Bool

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let pad  = max(16, min(w, h) * 0.05)

            ScrollView {
                VStack(spacing: 16) {
                    // Image picker card
                    Button {
                        notesFocused = false
                        Task { await pickPhoto() }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14).stroke(.primary.opacity(0.15), lineWidth: 1)
                                .background(RoundedRectangle(cornerRadius: 14).fill(.secondary.opacity(0.08)))
                                .frame(height: max(220, h * 0.26))
                            if let uiImage {
                                Image(uiImage: uiImage)
                                    .resizable().scaledToFill()
                                    .frame(height: max(220, h * 0.26))
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            } else {
                                VStack(spacing: 8) {
                                    Image(systemName: "photo.on.rectangle").font(.title2)
                                    Text("Tap to choose a photo").font(.subheadline).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes").font(.headline)
                        TextField("Optional", text: $notes, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .focused($notesFocused)
                    }

                    // Save
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
                .padding(.horizontal, pad)
                
                .frame(minHeight: h, alignment: .top)
            }
            .background(Color(.systemBackground).ignoresSafeArea())
        }
        .navigationTitle("Add Meal")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showErrorAlert) { Button("OK", role: .cancel) { } } message: {
            Text(errorMessage ?? "Something went wrong.")
        }
    }

    // MARK: - Actions

    private func pickPhoto() async {
        // Present the Photos picker
        // Caller already wrapped this in a button tap
        selectedImage = nil
        #if os(iOS)
        // .photosPicker is usually attached to a view, but to keep this self-contained
        // we fallback to the older UIImagePickerController flow if desired.
        #endif
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

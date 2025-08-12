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

    // Estimation + confirmation
    @State private var estimatedCalories: Int?
    @State private var caloriesToSave: Int = 0
    @State private var showConfirmSheet = false
    @State private var isEstimating = false

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    PhotosPicker(selection: $selectedImage, matching: .images, photoLibrary: .shared()) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).strokeBorder(.secondary.opacity(0.2), lineWidth: 1)
                                .frame(height: 220)
                                .overlay(
                                    Group {
                                        if let uiImage {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(height: 220)
                                                .clipped()
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                        } else {
                                            VStack(spacing: 8) {
                                                Image(systemName: "photo.on.rectangle").font(.title2)
                                                Text("Tap to choose a photo")
                                                    .font(.subheadline)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                )
                        }
                    }
                    .onChange(of: selectedImage) { newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self),
                               let img = UIImage(data: data) {
                                uiImage = img
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes").font(.subheadline).foregroundStyle(.secondary)
                        TextField("Optional", text: $notes, axis: .vertical)
                            .lineLimit(1...5)
                            .textFieldStyle(.roundedBorder)
                            .focused($notesFocused)
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 24)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            
        }
        .navigationTitle("Add Meal")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await saveTapped() }
                } label: {
                    if isUploading || isEstimating { ProgressView() } else { Text("Save").bold() }
                }
                .disabled(isUploading || isEstimating || uiImage == nil)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { notesFocused = false }
            }
        }
        .alert("Couldn't save meal", isPresented: $showErrorAlert, actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text(errorMessage ?? "Unknown error")
        })
        .sheet(isPresented: $showConfirmSheet) {
            ConfirmCaloriesSheet(image: uiImage, initialCalories: estimatedCalories ?? 0, onConfirm: { val in
                caloriesToSave = max(0, val)
                Task { await actuallySave() }
            }, onCancel: {
                // just close the sheet; user can tap Save again later
            })
            .presentationDetents([.height(360)])
        }
    }

    private func saveTapped() async {
        guard let uiImage else { return }
        // If we don't have an estimate yet, try to estimate first and ask for confirmation.
        if estimatedCalories == nil {
            isEstimating = true
            let estimator = OpenAINutritionService()
            if let estimate = try? await estimator.estimateCalories(from: uiImage) {
                estimatedCalories = estimate.totalCalories
                caloriesToSave = estimate.totalCalories
                showConfirmSheet = true
            } else {
                // couldn't estimate — fall back to manual entry sheet with 0 default
                estimatedCalories = 0
                caloriesToSave = 0
                showConfirmSheet = true
            }
            isEstimating = false
            return
        }

        // If we already have an estimate (sheet may have been shown), go straight to save.
        await actuallySave()
    }

    private func actuallySave() async {
        guard let uiImage else { return }
        isUploading = true
        do {
            try await mealViewModel.addMeal(image: uiImage, notes: notes, calories: caloriesToSave)
            await MainActor.run {
                self.uiImage = nil
                notes = ""
                notesFocused = false
                dismiss()
                onSaved?()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
        isUploading = false
    }
}

private struct ConfirmCaloriesSheet: View {
    let image: UIImage?
    @State var calories: Int
    var onConfirm: (Int) -> Void
    var onCancel: () -> Void

    init(image: UIImage?, initialCalories: Int, onConfirm: @escaping (Int) -> Void, onCancel: @escaping () -> Void) {
        self.image = image
        self._calories = State(initialValue: max(0, initialCalories))
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(spacing: 16) {
            if let img = image {
                Image(uiImage: img).resizable().scaledToFit().frame(height: 140).clipShape(RoundedRectangle(cornerRadius: 12))
            }
            Text("Estimated calories").font(.headline)
            HStack {
                Stepper(value: $calories, in: 0...5000, step: 10) { Text("\(calories) cal") }
            }
            .padding(.horizontal)

            HStack {
                Button("Cancel") { onCancel() }
                Spacer()
                Button("Save") { onConfirm(calories) }.buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 16)
    }
}

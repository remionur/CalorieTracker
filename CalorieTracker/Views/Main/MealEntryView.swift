import SwiftUI

struct MealEntryView: View {
    @ObservedObject var viewModel: MealViewModel
    @State private var notes = ""
    @State private var image: UIImage?
    @State private var showingImagePicker = false
    @State private var isSaving = false
    @State private var showError = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Form {
            Section {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                }
                
                Button(action: { showingImagePicker = true }) {
                    Text(image == nil ? "Add Photo" : "Change Photo")
                }
            }
            
            Section(header: Text("Notes")) {
                TextField("Add any notes about this meal", text: $notes)
            }
            
            Section {
                Button(action: saveMeal) {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save Meal")
                        }
                        Spacer()
                    }
                }
                .disabled(image == nil || isSaving)
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $image)
        }
        .alert("Error Saving Meal", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        }
        .navigationTitle("New Meal")
        .navigationTitle("New Meal")
    }
    
    private func saveMeal() {
        guard let image = image else { return }
        
        isSaving = true
        
        Task {
            do {
                try await viewModel.addMeal(image: image, notes: notes)
                await MainActor.run {
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    showError = true
                }
            }
        }
    }
}

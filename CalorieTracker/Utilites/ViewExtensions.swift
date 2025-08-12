import SwiftUI

extension View {
    /// Fill under status/home bars to avoid black gaps when using transparent list/form backgrounds.
    func fullScreenBackground() -> some View {
        self
            .background(Color(.systemBackground))
            .ignoresSafeArea()
    }
}

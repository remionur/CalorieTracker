import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let unit: String?
    var tint: Color = .accentColor

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title2.bold())
                    .monospacedDigit()
                    .foregroundStyle(tint)
                if let unit {
                    Text(unit)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    HStack(spacing: 16) {
        StatCard(title: "Total", value: "3,250", unit: "cal")
        StatCard(title: "Avg/Day", value: "465", unit: "cal")
        StatCard(title: "Goal Met", value: "5", unit: "days", tint: .green)
    }
    .padding()
    .background(Color(.systemBackground))
}


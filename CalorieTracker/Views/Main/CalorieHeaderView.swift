import SwiftUI

struct CalorieHeaderView: View {
    let consumed: Int
    let goal: Int

    private var percent: Double {
        guard goal > 0 else { return 0 }
        return min(Double(consumed) / Double(goal), 1)
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 14)
                Circle()
                    .trim(from: 0, to: percent)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.25), value: percent)

                Text("\(Int(percent * 100))%")
                    .font(.headline.monospacedDigit())
            }
            .frame(width: 120, height: 120)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Consumed").foregroundStyle(.secondary)
                    Spacer()
                    Text("\(consumed) cal").bold().monospacedDigit()
                }
                Divider()
                HStack {
                    Text("Goal").foregroundStyle(.secondary)
                    Spacer()
                    Text("\(goal) cal").bold().monospacedDigit()
                }
                HStack {
                    Text("Remaining").foregroundStyle(.secondary)
                    Spacer()
                    Text("\(max(goal - consumed, 0)) cal")
                        .bold().monospacedDigit()
                        .foregroundStyle((goal - consumed) >= 0 ? .green : .red)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.08))
        )
    }
}


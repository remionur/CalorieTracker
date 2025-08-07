import SwiftUI

struct ProgressRing: View {
    var progress: Double
    var colors: [Color] = [.blue, .green]
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 20)
                .opacity(0.3)
                .foregroundColor(colors.first ?? .blue)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                .fill(AngularGradient(gradient: Gradient(colors: colors), center: .center))
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear, value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.title2.bold())
        }
    }
}
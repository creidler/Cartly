import SwiftUI

/// Circular progress indicator with the percentage (or a check when complete).
struct ProgressRing: View {
    var progress: Double
    var tint: Color
    var lineWidth: CGFloat = 5
    var size: CGFloat = 44

    private var clamped: Double { min(max(progress, 0), 1) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.snappy, value: clamped)

            if clamped >= 1 {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.34, weight: .bold))
                    .foregroundStyle(tint)
            } else {
                Text("\(Int(clamped * 100))%")
                    .font(.system(size: size * 0.26, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
    }
}

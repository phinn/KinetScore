import SwiftUI

/// 合盖外屏书签卡(非交互 accessory):
/// 大字曲名 + 作曲家 + 页码 + 节拍器呼吸点(后台继续走拍)。
/// 深色舞台底 + 琥珀金 accent,与 app 主视觉同族。
struct ScoreCoverCard: View {
    let cover: CoverState

    var body: some View {
        VStack(spacing: 10) {
            if cover.metroRunning {
                // 呼吸点:节拍器后台走拍时的活性指示
                Circle()
                    .fill(Color(red: 0.96, green: 0.62, blue: 0.20))
                    .frame(width: 10, height: 10)
                    .symbolEffect(.pulse, options: .repeating)
            }

            Text(cover.title)
                .font(.system(size: 26, weight: .bold, design: .serif))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)

            if !cover.composer.isEmpty {
                Text(cover.composer)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
            }

            Spacer(minLength: 4)

            HStack(spacing: 12) {
                if cover.metroRunning {
                    Label("\(cover.bpm)", systemImage: "metronome.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(red: 0.96, green: 0.62, blue: 0.20))
                }
                Text(cover.pageCount > 0 ? "第 \(cover.page + 1) 页 · 共 \(cover.pageCount) 页" : "未开始")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color(red: 0.09, green: 0.09, blue: 0.11), Color(red: 0.05, green: 0.05, blue: 0.06)],
                startPoint: .top, endPoint: .bottom
            )
        )
    }
}

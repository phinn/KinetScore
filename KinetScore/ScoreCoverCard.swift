import SwiftUI

/// 合盖外屏书签卡(非交互 accessory):
/// 大字曲名 + 作曲家 + 页码 + 节拍器呼吸点(后台继续走拍)
struct ScoreCoverCard: View {
    let cover: CoverState

    var body: some View {
        VStack(spacing: 10) {
            if cover.metroRunning {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                    Text("\(cover.bpm) BPM")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.orange)
                }
            } else {
                Text("已合盖 · 翻盖续读")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Text(cover.title.isEmpty ? "未在演奏" : cover.title)
                .font(.system(size: 22, weight: .bold, design: .serif))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)

            if !cover.composer.isEmpty {
                Text(cover.composer)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            if cover.pageCount > 0 {
                Text("第 \(cover.page + 1) / \(cover.pageCount) 页")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.tint)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

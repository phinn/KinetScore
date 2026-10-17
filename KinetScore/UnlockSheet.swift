import SwiftUI
import StoreKit

/// 买断解锁弹层:权益态 + 购买 + 恢复购买。
/// 沙盒验证:scheme 挂 StoreKit Configuration(KinetScore.storekit),真机走 ASC 沙盒账号。
struct UnlockSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var gate = StoreGate.shared
    @State private var theme: StageTheme = .stage
    @State private var busy = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.system(size: 44))
                .foregroundStyle(theme.accent)

            Text("KinetScore 完整版")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 10) {
                Label("节拍器不限速(60–240 BPM 全速)", systemImage: "metronome")
                Label("对开双页模式(展开态)", systemImage: "rectangle.split.2x1")
                Label("无限曲库导入", systemImage: "square.and.arrow.down")
                Label("买断制 · 一次付费 · 永久使用", systemImage: "checkmark.seal")
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)

            Spacer()

            if gate.unlocked {
                Label("已解锁", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.green)
                    .padding(.bottom, 24)
            } else {
                Button {
                    busy = true
                    Task { await gate.purchase(); busy = false }
                } label: {
                    HStack {
                        if busy { ProgressView().tint(.white) }
                        Text(gate.product.map { "解锁完整版 \($0.displayPrice)" } ?? "加载中…")
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(gate.product == nil ? Color.gray : theme.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(gate.product == nil || busy)

                Button("恢复购买") {
                    busy = true
                    Task { await gate.restore(); busy = false }
                }
                .font(.subheadline)
                .padding(.top, 6)

                Text("免费版:5 首曲谱 · 节拍器限速 60–120")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 18)
            }
        }
        .padding(24)
        .task { await gate.refresh() }
    }
}

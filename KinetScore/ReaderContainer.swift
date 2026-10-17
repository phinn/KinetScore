import SwiftUI
import PDFKit
import Observation

/// 阅读器装配层:从 Score 建引擎,接库/节拍器/合盖卡,离开时回写进度。
/// 半开 = 上谱下控制台(ReservedRegion 语义,由 hinge.reserveConsole 驱动);
/// 展开 = 双页对开(spread);直板 = 单页。
struct ScoreReaderView: View {
    let score: Score
    var library: LibraryModel

    @State private var engine = ScoreEngine()
    @State private var metro = MetroEngine()
    var cover: CoverState
    @State private var showUnlock = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { geo in
            let posture = effectivePosture(canvas: geo.size)
            VStack(spacing: 0) {
                ScorePager(engine: engine, spread: posture == .fullyOpened && engine.settings.spread)
                    .frame(maxHeight: .infinity)

                if posture == .halfOpened && engine.settings.consoleInHalfOpen {
                    ConsoleBar(engine: engine, metro: metro, showUnlock: $showUnlock)
                        .frame(height: geo.size.height * 0.30)
                        .transition(.move(edge: .bottom))
                }
            }
            .sheet(isPresented: $showUnlock) {
                UnlockSheet()
                    .presentationDetents([.medium])
            }
        }
        .background(engine.settings.theme.bg)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    metro.toggle()
                } label: {
                    Image(systemName: metro.isRunning ? "metronome.fill" : "metronome")
                        .foregroundStyle(metro.isRunning ? engine.settings.theme.accent : engine.settings.theme.fg)
                }
            }
        }
        .task {
            engine.open(score)
            metro.bpm = score.bpm
            // 截图素材 harness:-kinetscore.page N 冷启动后直接定位页
            let args = ProcessInfo.processInfo.arguments
            if let i = args.firstIndex(of: "-kinetscore.page"),
               i + 1 < args.count, let p = Int(args[i + 1]),
               p >= 0 {
                // 等待 PDF 文档加载完成
                for _ in 0..<30 where engine.pageCount == 0 {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                engine.setPage(p)
            }
            cover.activate(score: score, metro: metro)
        }
        .onDisappear {
            library.updatePage(score, page: engine.page)
            library.updateBPM(score, bpm: metro.bpm)
            cover.endSession()
            metro.stop()
            engine.close()
        }
        .onChange(of: engine.page) { _, newPage in
            cover.sync(page: newPage, bpm: metro.bpm, metroRunning: metro.isRunning)
        }
    }

    /// 姿态判定:launch argument harness 优先(-kinetscore.posture half|open),
    /// 否则按画布几何推断 —— 宽高比 ≥ 1.05 视为全展开(对开),竖画布=直板/半开单页。
    /// 真机接 HingeMonitor(devicePosture)后走系统回调,此推断仅作模拟器/兜底。
    private func effectivePosture(canvas: CGSize) -> HingeMonitor.Posture {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-kinetscore.posture"), i + 1 < args.count {
            switch args[i + 1] {
            case "half": return .halfOpened
            case "open": return .fullyOpened
            default: break
            }
        }
        guard canvas.width > 0, canvas.height > 0 else { return .unknown }
        return canvas.width / canvas.height >= 1.05 ? .fullyOpened : .halfOpened
    }
}

/// 半开态 ReservedRegion 控制台:翻页 + 页码 + 节拍器速调
struct ConsoleBar: View {
    @Bindable var engine: ScoreEngine
    @Bindable var metro: MetroEngine
    @Binding var showUnlock: Bool

    var body: some View {
        HStack(spacing: 16) {
            Button { engine.prevPage() } label: {
                Image(systemName: "chevron.left.2")
                    .font(.title2.weight(.semibold))
            }
            .disabled(engine.page <= 0)

            VStack(spacing: 2) {
                Text("\(engine.page + 1) / \(engine.pageCount)")
                    .font(.headline.monospacedDigit())
                Text(metro.isRunning ? "\(metro.bpm) BPM" : "已暂停")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: 84)

            Button { engine.nextPage() } label: {
                Image(systemName: "chevron.right.2")
                    .font(.title2.weight(.semibold))
            }
            .disabled(engine.page >= engine.pageCount - 1)

            Divider()
                .frame(height: 30)

            Button {
                metro.toggle()
            } label: {
                Image(systemName: metro.isRunning ? "stop.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(metro.isRunning ? Color.red.opacity(0.9) : Color.green.opacity(0.85))
            }
            .buttonStyle(.plain)

            Stepper(value: Binding(
                get: { metro.bpm },
                set: { metro.setBPM($0, capped: !StoreGate.shared.unlocked) }
            ), in: 30...250, step: 4) {
                Text("\(metro.bpm) BPM")
                    .font(.subheadline.monospacedDigit())
            }
            .labelsHidden()
            .frame(width: 110)
            .onTapGesture {
                if !StoreGate.shared.unlocked { showUnlock = true }
            }

            if StoreGate.shared.unlocked {
                Image(systemName: "crown.fill")
                    .font(.caption)
                    .foregroundStyle(engine.settings.theme.accent)
            } else {
                Button {
                    showUnlock = true
                } label: {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity)
        .background(engine.settings.theme.panel)
    }
}

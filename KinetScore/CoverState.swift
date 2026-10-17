import SwiftUI
import Observation

/// 合盖书签卡状态:KinetScore 变体 = 曲名/作曲家/页码 + BPM 脉冲。
/// RootView 持有并喂给 sceneAccessory;阅读器 onAppear/onDisappear 驱动会话,
/// 定时轮询回写节拍器状态(合盖后 app 内 UI 不再触发 onChange,轮询保真)。
@Observable @MainActor
final class CoverState {
    var isActive = false
    var title = ""
    var composer = ""
    var page = 0
    var pageCount = 0
    var bpm = 0
    var metroRunning = false

    private weak var metro: MetroEngine?
    private var poll: Task<Void, Never>?

    func activate(score: Score, metro: MetroEngine) {
        self.metro = metro
        isActive = true
        title = score.title
        composer = score.composer
        pageCount = score.pageCount
        page = score.lastPage
        bpm = metro.bpm
        metroRunning = metro.isRunning
        startPolling()
    }

    func sync(page: Int, bpm: Int, metroRunning: Bool) {
        guard isActive else { return }
        self.page = page
        self.bpm = bpm
        self.metroRunning = metroRunning
    }

    func endSession() {
        poll?.cancel()
        poll = nil
        metro = nil
        isActive = false
        title = ""
        composer = ""
        page = 0
        pageCount = 0
        bpm = 0
        metroRunning = false
    }

    /// 0.5s 轮询:合盖时内屏 SwiftUI 交互停了,但节拍器后台继续走,
    /// 外屏呼吸点必须跟真实 isRunning/BPM,不能只靠 onChange。
    private func startPolling() {
        poll?.cancel()
        poll = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 500_000_000)
                guard let self, self.isActive, let m = self.metro else { continue }
                self.bpm = m.bpm
                self.metroRunning = m.isRunning
            }
        }
    }

}

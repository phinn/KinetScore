import SwiftUI
import Observation

/// 合盖书签卡状态:KinetScore 变体 = 曲名/作曲家/页码 + BPM 脉冲。
/// 阅读会话期间激活;M5Chat DuoExternalStatus / DuoFolio FolioCoverState 同族改写。
@Observable @MainActor
final class CoverState {
    var isActive = false
    var title = ""
    var composer = ""
    var page = 0
    var pageCount = 0
    var bpm = 0
    var metroRunning = false

    func activate(score: Score, metro: MetroEngine) {
        isActive = true
        title = score.title
        composer = score.composer
        pageCount = score.pageCount
        page = score.lastPage
        bpm = metro.bpm
        metroRunning = metro.isRunning
    }

    func sync(page: Int, bpm: Int, metroRunning: Bool) {
        self.page = page
        self.bpm = bpm
        self.metroRunning = metroRunning
    }

    func endSession() {
        isActive = false
        title = ""
        composer = ""
        page = 0
        pageCount = 0
        bpm = 0
        metroRunning = false
    }
}

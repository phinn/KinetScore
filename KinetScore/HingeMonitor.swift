import SwiftUI
import Observation

/// iPhone Duo 铰链状态监听(iOS 27 devicePosture / AvailabilityContext)。
/// V1 兜底策略:size class + 横竖比推断;系统 API 可用时优先系统。
/// DuoFolio FolioBridge 同族配方,场景挂载点在 RootView。
@Observable @MainActor
final class HingeMonitor {
    /// 半开(桌立)vs 全展开(对开)vs 合盖
    enum Posture { case unknown, folded, halfOpened, fullyOpened }

    private(set) var posture: Posture = .unknown

    /// 半开态下内屏底部保留给控制台的分区(ReservedRegion)
    /// 真机按系统回调刷新;模拟器里恒 false
    var reserveConsole: Bool { posture == .halfOpened }

    func update(isSplit: Bool, isFolded: Bool) {
        if isFolded { posture = .folded }
        else if isSplit { posture = .halfOpened }
        else { posture = .fullyOpened }
    }

    func reset() { posture = .unknown }
}

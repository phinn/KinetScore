import Foundation
import SwiftUI

/// 乐谱库主题。V1 定案:默认深色舞台模式(练琴暗房),暖白纸为可选 ——
/// 与 DuoFolio(纯暖纸白默认)形成主视觉差异(4.3 同族指纹规避)。
/// 铁律:营销截图拍 warm 模式,app 内默认 stage。
enum StageTheme: String, CaseIterable, Identifiable, Codable {
    /// 深色舞台(默认):近黑背景 + 暖金强调,乐谱页本身保持纸白
    case stage
    /// 暖白纸:与 DuoFolio 视觉语系接近但强调色不同(琥珀 vs 橙棕)
    case warm

    var id: String { rawValue }

    var bg: Color {
        switch self {
        case .stage: return Color(red: 0.071, green: 0.067, blue: 0.059)   // #121110
        case .warm:  return Color(red: 0.980, green: 0.957, blue: 0.910)   // #FAF4E8
        }
    }
    /// 控制台面板色
    var panel: Color {
        switch self {
        case .stage: return Color(red: 0.114, green: 0.106, blue: 0.094)   // #1D1B18
        case .warm:  return Color(red: 0.937, green: 0.906, blue: 0.843)   // #EFE7D7
        }
    }
    var fg: Color {
        switch self {
        case .stage: return Color(red: 0.847, green: 0.824, blue: 0.769)   // #D8D2C4
        case .warm:  return Color(red: 0.243, green: 0.188, blue: 0.141)   // #3E3024
        }
    }
    var dim: Color {
        switch self {
        case .stage: return Color(red: 0.541, green: 0.514, blue: 0.459)   // #8A8375
        case .warm:  return Color(red: 0.471, green: 0.408, blue: 0.345)   // #786858
        }
    }
    /// 便利别名(ScorePager 等处用 text 语义)
    var text: Color { fg }
    /// 品牌强调色:琥珀金(节拍器脉冲/BPM 圆盘/选中态)
    var accent: Color {
        switch self {
        case .stage: return Color(red: 0.960, green: 0.706, blue: 0.290)   // #F5B44A
        case .warm:  return Color(red: 0.784, green: 0.435, blue: 0.118)   // #C86F1E
        }
    }
    var label: String {
        switch self {
        case .stage: return "舞台"
        case .warm:  return "暖纸"
        }
    }
    var icon: String {
        switch self {
        case .stage: return "theatermasks"
        case .warm:  return "sun.max"
        }
    }
}

/// 阅读器可调项(节拍器偏好持久化在 MetroEngine 侧)
struct ScoreSettings: Codable, Equatable {
    var theme: StageTheme = .stage
    /// 对开:展开态双页并排(买断解锁)
    var spread: Bool = true
    /// 半开 ReservedRegion 时显示控制台
    var consoleInHalfOpen: Bool = true
    static let standard = ScoreSettings()
}

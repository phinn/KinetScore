import Foundation
import SwiftUI

/// 曲库一首曲子(元数据持久化到 Documents/kinetscore.json)
/// 对应 DuoFolio.Book 的极简变体:V1 只有 PDF,新增 BPM(节拍器默认速度)与 lastPage(续读页)
struct Score: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var composer: String
    var fileName: String          // Documents/ 下文件名
    var pageCount: Int
    var bpm: Int                  // 默认练习速度
    var lastPage: Int             // 0-based,续读
    var addedAt: Date

    init(id: UUID = UUID(), title: String, composer: String = "",
         fileName: String, pageCount: Int = 0, bpm: Int = 90,
         lastPage: Int = 0, addedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.composer = composer
        self.fileName = fileName
        self.pageCount = pageCount
        self.bpm = bpm
        self.lastPage = lastPage
        self.addedAt = addedAt
    }

    var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    /// 深色舞台模式下的封面占位底色(按 id 稳定取色,曲库有层次)
    var stageTint: Color {
        let palette: [Color] = [
            Color(red: 0.16, green: 0.18, blue: 0.24),
            Color(red: 0.18, green: 0.15, blue: 0.22),
            Color(red: 0.13, green: 0.20, blue: 0.21),
            Color(red: 0.21, green: 0.17, blue: 0.14),
        ]
        let h = abs(id.hashValue)
        return palette[h % palette.count]
    }
}

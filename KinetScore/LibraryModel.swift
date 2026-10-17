import Foundation
import PDFKit
import Observation

/// 曲库状态:JSON 持久化 + PDF 导入(页数探测/去重)+ 打开/续读
@Observable
final class LibraryModel {
    private(set) var scores: [Score] = []
    var isImporting = false
    var presentImporter = false
    var importError: String?
    /// 待打开的曲子(库视图监听切到乐谱页)
    var pendingOpen: Score?

    /// 免费版曲库上限(V1 定案:5 首;买断解锁)
    static let freeLimit = 5
    var isPurchased = false   // V1.0 暂无 IAP,直接 true 也行;留接口
    var limitReached: Bool { !isPurchased && scores.count >= Self.freeLimit }

    private static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("kinetscore.json")
    }

    /// 兼容 ISO8601 字符串与 double 两种日期格式(DuoFolio 踩过的坑平移)
    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { dec in
            let c = try dec.singleValueContainer()
            if let s = try? c.decode(String.self),
               let date = ISO8601DateFormatter().date(from: s) { return date }
            if let t = try? c.decode(Double.self) { return Date(timeIntervalSinceReferenceDate: t) }
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "bad date")
        }
        return d
    }()

    init() {
        load()
    }

    // MARK: - 持久化

    private func load() {
        if let data = try? Data(contentsOf: Self.fileURL),
           var list = try? Self.decoder.decode([Score].self, from: data) {
            list = list.filter { FileManager.default.fileExists(atPath: $0.fileURL.path) }
            scores = list
            NSLog("[KinetScore] load ok: %ld scores", scores.count)
        } else {
            NSLog("[KinetScore] load empty at %@", Self.fileURL.path)
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(scores) else { return }
        try? data.write(to: Self.fileURL, options: .atomic)
    }

    // MARK: - 打开

    @MainActor
    func open(_ score: Score) {
        guard FileManager.default.fileExists(atPath: score.fileURL.path) else {
            importError = "找不到乐谱文件:\(score.fileName)"
            return
        }
        pendingOpen = score
    }

    // MARK: - 导入(PDF)

    /// PDF 导入:拷贝到 Documents → PDFKit 探页数 → 标题取文件名 → 按 title+页数去重
    func importPDF(from url: URL) {
        isImporting = true
        defer { isImporting = false }
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        do {
            if limitReached {
                importError = "免费版曲库上限 \(Self.freeLimit) 首"
                return
            }
            let data = try Data(contentsOf: url)
            guard let doc = PDFDocument(data: data), doc.pageCount > 0 else {
                importError = "无法解析 PDF"
                return
            }
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = "\(UUID().uuidString).pdf"
            try data.write(to: docs.appendingPathComponent(fileName), options: .atomic)

            let baseName = url.deletingPathExtension().lastPathComponent
            let title = prettyTitle(baseName)
            // 去重:同名同页数视为已导入
            if scores.contains(where: { $0.title == title && $0.pageCount == doc.pageCount }) {
                try? FileManager.default.removeItem(at: docs.appendingPathComponent(fileName))
                importError = "已在曲库中:\(title)"
                return
            }

            let score = Score(title: title,
                              fileName: fileName,
                              pageCount: doc.pageCount)
            scores.insert(score, at: 0)
            save()
            NSLog("[KinetScore] imported %@ (%ld pages)", title, doc.pageCount)
        } catch {
            importError = "无法导入:\(error.localizedDescription)"
        }
    }

    /// "Chopin_Nocturne_Op9No2_clean" → "Chopin Nocturne Op9No2"(下划线/连字符转空格,压多空格)
    private func prettyTitle(_ raw: String) -> String {
        let cleaned = raw
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        return cleaned.isEmpty ? "Untitled" : cleaned
    }

    // MARK: - 增删改

    func remove(_ score: Score) {
        try? FileManager.default.removeItem(at: score.fileURL)
        scores.removeAll { $0.id == score.id }
        save()
    }

    func updateBPM(_ score: Score, bpm: Int) {
        guard let i = scores.firstIndex(where: { $0.id == score.id }) else { return }
        scores[i].bpm = bpm
        save()
    }

    func updatePage(_ score: Score, page: Int) {
        guard let i = scores.firstIndex(where: { $0.id == score.id }) else { return }
        guard scores[i].lastPage != page else { return }
        scores[i].lastPage = page
        save()
    }
}

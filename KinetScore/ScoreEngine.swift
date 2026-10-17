import Foundation
import PDFKit
import Observation

/// PDFKit 渲染层:V1 全部走 PDFDocument,零第三方。
/// 职责:文档装载、页数、页面缩略、逐页跳转;不持有 UI。
@Observable @MainActor
final class ScoreEngine {
    private(set) var document: PDFDocument?
    private(set) var pageCount: Int = 0
    var page: Int = 0

    /// 钳制写入(@Observable 下 didSet 回写自身会无限递归,禁止)
    func setPage(_ newValue: Int) {
        page = min(max(0, newValue), max(0, pageCount - 1))
    }
    var settings = ScoreSettings()

    private(set) var loadError: String?

    var score: Score?

    func open(_ score: Score) {
        self.score = score
        loadError = nil
        guard let doc = PDFDocument(url: score.fileURL), doc.pageCount > 0 else {
            document = nil
            pageCount = 0
            loadError = "无法解析 PDF"
            return
        }
        document = doc
        pageCount = doc.pageCount
        page = min(score.lastPage, max(0, doc.pageCount - 1))
    }

    func close() {
        document = nil
        pageCount = 0
        page = 0
        loadError = nil
    }

    func nextPage() { setPage(page + 1) }
    func prevPage() { setPage(page - 1) }

    /// 当前页缩略(曲库封面用)
    func thumbnail(of score: Score, width: CGFloat = 300) -> UIImage? {
        guard let doc = PDFDocument(url: score.fileURL),
              let first = doc.page(at: 0) else { return nil }
        return first.thumbnail(of: CGSize(width: width, height: width * 1.414), for: .mediaBox)
    }

    /// 展开态对开:左右两页索引
    var spreadIndices: (left: Int, right: Int)? {
        guard document != nil else { return nil }
        let l = page
        let r = page + 1 < pageCount ? page + 1 : nil
        return (l, r ?? -1)
    }
}

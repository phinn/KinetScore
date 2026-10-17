import SwiftUI
import PDFKit
import Observation

/// 阅读容器内谱面渲染:连续滚动模式;对开翻页模式由 SpreadView 呈现。
struct ScorePager: View {
    let engine: ScoreEngine
    var spread: Bool = false

    var body: some View {
        if spread {
            SpreadView(engine: engine)
        } else {
            ContinuousView(engine: engine)
        }
    }
}

/// 纵向连续滚动(PDFKit 原生,自动翻页友好)
struct ContinuousView: View {
    let engine: ScoreEngine

    var body: some View {
        Group {
            if let doc = engine.document,
               let page = doc.page(at: engine.page) {
                PDFKitView(page: page)
                    .ignoresSafeArea(edges: .bottom)
            } else {
                Text(engine.loadError ?? "未打开乐谱")
                    .foregroundStyle(engine.settings.theme.text)
            }
        }
    }
}

/// 展开态双页对开:左=当前页,右=下一页
struct SpreadView: View {
    let engine: ScoreEngine

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                if let doc = engine.document {
                    if let l = doc.page(at: engine.page) {
                        PDFKitView(page: l).frame(width: geo.size.width / 2)
                    }
                    if engine.page + 1 < engine.pageCount,
                       let r = doc.page(at: engine.page + 1) {
                        PDFKitView(page: r).frame(width: geo.size.width / 2)
                    } else {
                        Rectangle().fill(engine.settings.theme.bg).frame(width: geo.size.width / 2)
                    }
                }
            }
        }
    }
}

/// PDFKit 单页包装:双击放大禁用(读谱场景缩放失焦),禁滚动回弹抖动
struct PDFKitView: UIViewRepresentable {
    let page: PDFPage

    func makeUIView(context: Context) -> PDFView {
        let v = PDFView()
        v.displayMode = .singlePage
        v.displayDirection = .horizontal
        v.autoScales = true
        v.backgroundColor = .clear
        v.pageShadowsEnabled = false
        v.document = page.document
        v.go(to: page)
        return v
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document !== page.document {
            uiView.document = page.document
        }
        if uiView.currentPage !== page {
            uiView.go(to: page)
        }
    }
}
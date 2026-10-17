import SwiftUI
import UniformTypeIdentifiers

/// 曲库 + 打开乐谱(阅读器内嵌:半开=ReservedRegion 上下分区,展开=对开)
struct LibraryView: View {
    @State var library: LibraryModel
    @Binding var openedScore: Score?
    @State private var importError: String?

    var body: some View {
        NavigationStack {
            Group {
                if library.scores.isEmpty {
                    emptyState
                } else {
                    scoreList
                }
            }
            .navigationTitle("KinetScore")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        library.isImporting = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .fileImporter(isPresented: $library.isImporting,
                          allowedContentTypes: [.pdf],
                          allowsMultipleSelection: true) { result in
                switch result {
                case .success(let urls):
                    for url in urls { library.importPDF(from: url) }
                    importError = library.importError
                case .failure(let err):
                    importError = err.localizedDescription
                }
            }
            .navigationDestination(item: $openedScore) { score in
                ScoreReaderView(score: score, library: library)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("导入你的第一份乐谱", systemImage: "music.note.list")
        } description: {
            Text("支持 PDF 乐谱,导入后自动生成曲库。半开手机即得谱架,展开即对开双页。")
        } actions: {
            Button("导入 PDF") { library.isImporting = true }
                .buttonStyle(.borderedProminent)
        }
    }

    private var scoreList: some View {
        List {
            ForEach(library.scores) { score in
                Button {
                    openedScore = score
                } label: {
                    ScoreRow(score: score)
                }
                .buttonStyle(.plain)
            }
            .onDelete { offsets in
                for i in offsets { library.remove(library.scores[i]) }
            }
        }
        .listStyle(.plain)
        .alert("导入失败", isPresented: .constant(importError != nil)) {
            Button("好") { importError = nil; library.importError = nil }
        } message: {
            Text(importError ?? "")
        }
    }
}

struct ScoreRow: View {
    let score: Score

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 8)
                .fill(score.stageTint)
                .frame(width: 52, height: 68)
                .overlay {
                    Image(systemName: "music.quarternote.3")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
            VStack(alignment: .leading, spacing: 4) {
                Text(score.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(score.composer.isEmpty ? "PDF 乐谱 · \(score.pageCount) 页" : "\(score.composer) · \(score.pageCount) 页")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Label("\(score.bpm) BPM", systemImage: "metronome")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    if score.lastPage > 0 {
                        Text("上次读到第 \(score.lastPage + 1) 页")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

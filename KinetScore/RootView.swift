import SwiftUI

struct RootView: View {
    @State private var library = LibraryModel()
    @State private var openedScore: Score?

    var body: some View {
        NavigationStack {
            LibraryView(library: library, openedScore: $openedScore)
        }
        .onAppear {
            #if DEBUG
            // -kinetscore.openIndex N 冷启动直开(harness,只读一次)
            let args = ProcessInfo.processInfo.arguments
            if let idx = args.firstIndex(of: "-kinetscore.openIndex"),
               args.count > idx + 1,
               let i = Int(args[idx + 1]),
               library.scores.indices.contains(i) {
                openedScore = library.scores[i]
            }
            #endif
        }
        .onOpenURL { url in
            #if DEBUG
            // kinetscore://open?index=N 烟囱深链(截图 harness)
            guard url.scheme == "kinetscore", url.host == "open",
                  let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let raw = comps.queryItems?.first(where: { $0.name == "index" })?.value,
                  let i = Int(raw), library.scores.indices.contains(i) else { return }
            openedScore = library.scores[i]
            #endif
        }
    }
}

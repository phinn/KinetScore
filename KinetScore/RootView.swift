import SwiftUI

struct RootView: View {
    @State private var library = LibraryModel()
    @State private var cover = CoverState()
    @State private var openedScore: Score?

    var body: some View {
        NavigationStack {
            LibraryView(library: library, openedScore: $openedScore, cover: cover)
        }
        .modifier(ScoreCoverSceneAccessory(state: cover))
        // 截图素材 harness:-kinetscore.openIndex N 冷启动直进阅读器
        .task {
            let args = ProcessInfo.processInfo.arguments
            guard let i = args.firstIndex(of: "-kinetscore.openIndex"),
                  i + 1 < args.count,
                  let idx = Int(args[i + 1])
            else { return }
            // 等待曲库加载完成
            for _ in 0..<40 where library.scores.isEmpty {
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            guard idx >= 0, idx < library.scores.count else { return }
            openedScore = library.scores[idx]
        }
    }
}

/// 合盖书签卡 accessory(iOS 27.1 SceneAccessoryContent + ExternalNonInteractiveAccessory):
/// 有活动阅读会话时 isEnabled=true,系统只在合盖(外屏呈现时机)才真正显示。
@available(iOS 27.1, *)
struct ScoreCoverAccessory: SceneAccessoryContent {
    let state: CoverState

    var body: some SceneAccessoryContent {
        ExternalNonInteractiveAccessory(isEnabled: Binding(get: { state.isActive }, set: { _ in })) {
            ScoreCoverCard(cover: state)
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(white: 0.08))
        }
    }
}

/// ViewModifier 包一层 #available,对旧系统安全
struct ScoreCoverSceneAccessory: ViewModifier {
    let state: CoverState

    func body(content: Content) -> some View {
        if #available(iOS 27.1, *) {
            content.sceneAccessory {
                ScoreCoverAccessory(state: state)
            }
        } else {
            content
        }
    }
}

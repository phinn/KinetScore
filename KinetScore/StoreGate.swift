import Foundation
import StoreKit
import Observation

/// 买断解锁:StoreKit 2 非消耗型 com.kinet.score.unlock。
/// 模拟器走 scheme 挂的 StoreKit Configuration(KinetScore.storekit);真机走 ASC 沙盒。
@MainActor
@Observable
final class StoreGate {
    static let productID = "com.kinet.score.unlock"
    static let shared = StoreGate()

    /// 是否已解锁(响应式;购买/恢复成功后立即生效)
    private(set) var unlocked = false
    /// 解锁商品(购买面板展示价格用)
    private(set) var product: Product?
    private(set) var purchasing = false
    private(set) var lastError: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { [weak self] in
            // 交易监听:处理沙盒/生产环境中断后续付(如购买后未 finish)
            for await update in Transaction.updates {
                await self?.handle(update)
            }
        }
        Task { await refresh() }
    }


    /// 拉商品 + 对账当前权益
    func refresh() async {
        do {
            product = try await Product.products(for: [Self.productID]).first
        } catch {
            NSLog("[KinetScore] StoreGate products error: \(error)")
        }
        var owned = false
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let t) = entitlement, t.productID == Self.productID {
                owned = true
            }
        }
        unlocked = owned
        #if DEBUG
        NSLog("[KinetScore] StoreGate refresh: unlocked=\(unlocked) product=\(product?.displayName ?? "nil")")
        #endif
    }

    /// 购买(非消耗型)。返回是否成功解锁。
    @discardableResult
    func purchase() async -> Bool {
        guard let product else {
            lastError = "商品未加载,请检查网络后重试"
            return false
        }
        purchasing = true
        defer { purchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    unlocked = true
                    return true
                } else {
                    lastError = "交易校验失败"
                    return false
                }
            case .userCancelled:
                return false
            case .pending:
                lastError = "交易待批准(家庭共享/家长审批)"
                return false
            @unknown default:
                return false
            }
        } catch {
            lastError = "购买失败:\(error.localizedDescription)"
            return false
        }
    }

    /// 恢复购买(换机/重装)
    func restore() async -> Bool {
        purchasing = true
        defer { purchasing = false }
        do {
            try await AppStore.sync()
        } catch {
            lastError = "恢复失败:\(error.localizedDescription)"
            return false
        }
        await refresh()
        return unlocked
    }

    private func handle(_ update: VerificationResult<Transaction>) async {
        if case .verified(let transaction) = update, transaction.productID == Self.productID {
            await transaction.finish()
            unlocked = true
        }
    }
}

@MainActor
enum StoreGateCompat {
    /// 供 ConsoleBar 等静态语境读取(老 StoreGate.unlocked 调用点收敛到这)
    static var unlocked: Bool { StoreGate.shared.unlocked }
}

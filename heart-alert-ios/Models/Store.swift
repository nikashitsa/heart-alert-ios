import Foundation
import StoreKit

/// Something the paywall may want to tell the user about.
enum StoreEvent {
    case userCancelled
    case purchasePending
    case nothingToRestore
    case unavailable
    case failed
}

/// Owns the App Store connection for the one-time "Unlimited access" product.
///
/// Granting routes through `Settings.shared` rather than living here on purpose: the purchase
/// sheet can be dismissed mid-flow, and an Ask to Buy approval can land while the app is not
/// even running. The grant has to outlive both.
@MainActor
final class Store: ObservableObject {
    static let productID = "unlimited_access"

    /// Shown until the App Store tells us the real, localised price.
    private static let fallbackPrice = "$4.99"

    @Published private(set) var product: Product?

    /// True while the App Store is being talked to, so the paywall can show a loader.
    @Published private(set) var busy = false

    /// A short line to show under the description, or nil when there is nothing to say.
    @Published private(set) var notice: String?

    var displayPrice: String { product?.displayPrice ?? Store.fallbackPrice }

    private var updates: Task<Void, Never>?

    init() {
        // Started before any other StoreKit call, so nothing is missed in the window between
        // launch and the first product lookup. Detached because it must outlive every view:
        // MainView swaps its children with .id(flow), so a listener owned by a view's .task
        // would be torn down on the first navigation.
        updates = Task.detached(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(result)
            }
        }
        // On a cold start, pick up anything the App Store knows that this install does not:
        // a purchase made on another device, or one approved while the process was dead.
        Task {
            guard !Settings.shared.unlimitedAccess else { return }
            await refreshEntitlement()
            await loadProduct(silent: true)
        }
    }

    // Deliberately no `deinit { updates?.cancel() }`. This is a @StateObject on the App, so it
    // is never deallocated, and cancellation would only add a way for the listener to die.

    // MARK: - What the paywall calls

    /// Opens the App Store purchase sheet.
    func purchase() async {
        guard !busy else { return }
        beginStoreCall()
        defer { busy = false }

        if product == nil {
            await loadProduct(silent: false)
        }
        guard let product else { return } // loadProduct already said why

        do {
            switch try await product.purchase() {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    grant()
                    await transaction.finish()
                case .unverified:
                    // The signature did not check out. Do not grant, and do not finish either:
                    // leaving it open lets a merely transient failure come back to us.
                    notice = Store.text(for: .failed)
                }
            case .userCancelled:
                // Cancelling is a deliberate choice, not something to comment on.
                break
            case .pending:
                // Ask to Buy, or a bank confirmation. Nothing to grant yet; the approval
                // arrives later through Transaction.updates, possibly on the next launch.
                notice = Store.text(for: .purchasePending)
            @unknown default:
                notice = Store.text(for: .failed)
            }
        } catch {
            let event = Store.event(for: error)
            if event != .userCancelled {
                notice = Store.text(for: event)
            }
        }
    }

    /// Re-reads what the App Store says the user owns, and says so if it owns nothing.
    func restore() async {
        guard !busy else { return }
        beginStoreCall()
        defer { busy = false }

        // Silent pass first. It reads on-device signed transactions, so it never prompts for
        // a password and covers all but the unusual cases.
        if await refreshEntitlement() { return }

        // Only now pay for the App Store sign-in sheet, which catches a device with no
        // transaction history for this app under the current Apple Account.
        do {
            try await AppStore.sync()
        } catch {
            let event = Store.event(for: error)
            if event != .userCancelled {
                notice = Store.text(for: event)
            }
            return
        }

        if await refreshEntitlement() == false {
            notice = Store.text(for: .nothingToRestore)
        }
    }

    // MARK: - Talking to the App Store

    /// Reads the product so the paywall can show the real, localised price.
    /// `silent` is for the startup load, which must not paint a notice on a paywall the user
    /// has not even opened.
    func loadProduct(silent: Bool) async {
        do {
            let products = try await Product.products(for: [Store.productID])
            // An unknown or not-yet-approved product id comes back as an empty list rather
            // than an error, so this case has to be caught by hand.
            guard let match = products.first(where: { $0.id == Store.productID }) else {
                if !silent { notice = Store.text(for: .unavailable) }
                return
            }
            product = match
        } catch {
            if !silent { notice = Store.text(for: Store.event(for: error)) }
        }
    }

    /// Grants access for anything the App Store says is already paid for.
    @discardableResult
    func refreshEntitlement() async -> Bool {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.productID == Store.productID,
                  transaction.revocationDate == nil else { continue }
            grant()
            return true
        }
        return false
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result,
              transaction.productID == Store.productID else { return }
        if transaction.revocationDate == nil {
            grant()
        }
        // Finish even a revoked transaction, so the system stops redelivering it.
        await transaction.finish()
    }

    private func grant() {
        Settings.shared.grantUnlimitedAccess()
        notice = nil
    }

    /// Drops the last message and shows the loader until the App Store reports back.
    private func beginStoreCall() {
        notice = nil
        busy = true
    }

    // MARK: - Small helpers

    private static func event(for error: Error) -> StoreEvent {
        switch error {
        case let error as StoreKitError:
            switch error {
            case .userCancelled: return .userCancelled
            case .networkError, .notAvailableInStorefront: return .unavailable
            case .notEntitled: return .nothingToRestore
            case .systemError, .unknown: return .failed
            case .unsupported: return .failed
            @unknown default: return .failed
            }
        case let error as Product.PurchaseError:
            switch error {
            // The store will not sell this: either the product is not purchasable, or Screen
            // Time is blocking purchases.
            case .productUnavailable, .purchaseNotAllowed: return .unavailable
            default: return .failed
            }
        case is CancellationError:
            return .userCancelled
        default:
            return .failed
        }
    }

    /// What the paywall says about an outcome, or nil when it should stay quiet.
    private static func text(for event: StoreEvent) -> String? {
        switch event {
        case .userCancelled:
            return nil
        case .purchasePending:
            return "Your purchase is pending. Access unlocks once payment completes."
        case .nothingToRestore:
            return "No previous purchase found."
        case .unavailable:
            return "The App Store is not available right now."
        case .failed:
            return "Something went wrong. Please try again."
        }
    }
}

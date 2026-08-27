import UIKit
import ProgressHUD

// MARK: - UIBlockingProgressHUD

/// Показывает индикатор и одновременно блокирует ввод, чтобы пользователь
/// не мог повторно запустить операцию (например, снова открыть WebView).
final class UIBlockingProgressHUD {

    private static var window: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }

    static func show() {
        window?.isUserInteractionEnabled = false
        ProgressHUD.animate()
    }

    static func dismiss() {
        window?.isUserInteractionEnabled = true
        ProgressHUD.dismiss()
    }
}

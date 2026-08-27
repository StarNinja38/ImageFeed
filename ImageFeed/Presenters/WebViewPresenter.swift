import Foundation

// MARK: - Протоколы View ↔ Presenter

protocol WebViewViewControllerProtocol: AnyObject {
    var presenter: WebViewPresenterProtocol? { get set }
    func load(request: URLRequest)
    func setProgressValue(_ newValue: Float)
    func setProgressHidden(_ isHidden: Bool)
}

protocol WebViewPresenterProtocol: AnyObject {
    var view: WebViewViewControllerProtocol? { get set }
    func viewDidLoad()
    func didUpdateProgressValue(_ newValue: Double)
    func code(from url: URL) -> String?
}

// MARK: - WebViewPresenter

final class WebViewPresenter: WebViewPresenterProtocol {

    weak var view: WebViewViewControllerProtocol?

    private let authHelper: AuthHelperProtocol

    init(authHelper: AuthHelperProtocol = AuthHelper()) {
        self.authHelper = authHelper
    }

    func viewDidLoad() {
        guard let request = authHelper.authRequest() else {
            print("[WebViewPresenter.viewDidLoad]: не удалось собрать запрос авторизации")
            return
        }
        didUpdateProgressValue(0)
        view?.load(request: request)
    }

    func didUpdateProgressValue(_ newValue: Double) {
        let newProgressValue = Float(newValue)
        view?.setProgressValue(newProgressValue)

        let shouldHideProgress = shouldHideProgress(for: newProgressValue)
        view?.setProgressHidden(shouldHideProgress)
    }

    /// Вынесено отдельным методом — так его можно проверить unit-тестом
    /// (верификация возвращаемого значения).
    func shouldHideProgress(for value: Float) -> Bool {
        abs(value - 1.0) <= 0.0001
    }

    func code(from url: URL) -> String? {
        authHelper.code(from: url)
    }
}

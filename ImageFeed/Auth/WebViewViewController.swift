import UIKit
@preconcurrency import WebKit

// MARK: - WebViewViewControllerDelegate

protocol WebViewViewControllerDelegate: AnyObject {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String)
    func webViewViewControllerDidCancel(_ vc: WebViewViewController)
}

// MARK: - WebViewViewController

/// После рефакторинга на MVP контроллер отвечает только за отображение:
/// сборка запроса, расчёт прогресса и разбор кода живут в `WebViewPresenter`.
final class WebViewViewController: UIViewController & WebViewViewControllerProtocol {

    private enum Layout {
        static let backButtonInset: CGFloat = 9
        static let backButtonSize: CGFloat = 24
        static let progressTopInset: CGFloat = 9
    }

    weak var delegate: WebViewViewControllerDelegate?
    var presenter: WebViewPresenterProtocol?

    private let webView = WKWebView()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let backButton = UIButton(type: .custom)

    private var estimatedProgressObservation: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        webView.accessibilityIdentifier = "UnsplashWebView"

        setupWebView()
        setupBackButton()
        setupProgressView()

        webView.navigationDelegate = self
        observeEstimatedProgress()
        presenter?.viewDidLoad()
    }

    // MARK: WebViewViewControllerProtocol

    func load(request: URLRequest) {
        webView.load(request)
    }

    func setProgressValue(_ newValue: Float) {
        progressView.setProgress(newValue, animated: true)
    }

    func setProgressHidden(_ isHidden: Bool) {
        progressView.isHidden = isHidden
    }

    // MARK: KVO за прогрессом

    private func observeEstimatedProgress() {
        estimatedProgressObservation = webView.observe(
            \.estimatedProgress,
            options: [.new]
        ) { [weak self] _, _ in
            guard let self else { return }
            self.presenter?.didUpdateProgressValue(self.webView.estimatedProgress)
        }
    }

    @objc private func didTapBackButton() {
        delegate?.webViewViewControllerDidCancel(self)
    }

    // MARK: Вёрстка

    private func setupWebView() {
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupBackButton() {
        backButton.setImage(UIImage(named: "nav_back_button"), for: .normal)
        backButton.tintColor = UIColor(named: "YP Black")
        backButton.addTarget(self, action: #selector(didTapBackButton), for: .touchUpInside)
        backButton.accessibilityIdentifier = "BackButton"
        backButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backButton)
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: Layout.backButtonInset),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Layout.backButtonInset),
            backButton.widthAnchor.constraint(equalToConstant: Layout.backButtonSize),
            backButton.heightAnchor.constraint(equalToConstant: Layout.backButtonSize)
        ])
    }

    private func setupProgressView() {
        progressView.progressTintColor = UIColor(named: "YP Black")
        progressView.trackTintColor = .clear
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: Layout.progressTopInset),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}

// MARK: - WKNavigationDelegate

extension WebViewViewController: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if let url = navigationAction.request.url, let code = presenter?.code(from: url) {
            delegate?.webViewViewController(self, didAuthenticateWithCode: code)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
}

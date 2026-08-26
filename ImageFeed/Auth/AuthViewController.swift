import UIKit

protocol AuthViewControllerDelegate: AnyObject {
    func didAuthenticate(_ vc: AuthViewController)
}

final class AuthViewController: UIViewController {

    weak var delegate: AuthViewControllerDelegate?

    private let logoImageView = UIImageView()
    private let loginButton = UIButton(type: .system)
    private let oauth2Service = OAuth2Service.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "YP Black")
        setupLogo()
        setupLoginButton()
    }

    private func setupLogo() {
        logoImageView.image = UIImage(named: "auth_screen_logo")
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoImageView)
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 60),
            logoImageView.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    private func setupLoginButton() {
        loginButton.setTitle("Войти", for: .normal)
        loginButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        loginButton.setTitleColor(UIColor(named: "YP Black"), for: .normal)
        loginButton.backgroundColor = .white
        loginButton.layer.cornerRadius = 16
        loginButton.layer.masksToBounds = true
        loginButton.addTarget(self, action: #selector(didTapLoginButton), for: .touchUpInside)
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loginButton)
        NSLayoutConstraint.activate([
            loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            loginButton.heightAnchor.constraint(equalToConstant: 48),
            loginButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -90)
        ])
    }

    @objc private func didTapLoginButton() {
        let webViewViewController = WebViewViewController()
        webViewViewController.delegate = self
        webViewViewController.modalPresentationStyle = .fullScreen
        present(webViewViewController, animated: true)
    }
}

// MARK: - WebViewViewControllerDelegate

extension AuthViewController: WebViewViewControllerDelegate {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) {
        vc.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            self.oauth2Service.fetchAuthToken(code: code) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success:
                    self.delegate?.didAuthenticate(self)
                case .failure(let error):
                    print("[AuthViewController.webViewViewController]: не удалось получить токен — \(error.localizedDescription)")
                }
            }
        }
    }

    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        vc.dismiss(animated: true)
    }
}

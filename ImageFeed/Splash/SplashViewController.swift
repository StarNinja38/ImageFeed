import UIKit

// MARK: - SplashViewController

final class SplashViewController: UIViewController {

    private let logoImageView = UIImageView()

    private let tokenStorage = OAuth2TokenStorage()
    private let profileService = ProfileService.shared
    private let profileImageService = ProfileImageService.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "YP Black")
        setupLogo()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard let token = tokenStorage.token else {
            showAuthViewController()
            return
        }
        // Токен уже есть — тянем профиль, splash висит до готовности данных.
        fetchProfile(token)
    }

    // MARK: Вёрстка кодом

    private func setupLogo() {
        logoImageView.image = UIImage(named: "splash_screen_logo")
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoImageView)
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: Флоу

    private func showAuthViewController() {
        let authViewController = AuthViewController()
        authViewController.delegate = self
        authViewController.modalPresentationStyle = .fullScreen
        present(authViewController, animated: true)
    }

    private func fetchProfile(_ token: String) {
        UIBlockingProgressHUD.show()
        profileService.fetchProfile(token) { [weak self] result in
            UIBlockingProgressHUD.dismiss()
            guard let self else { return }

            switch result {
            case .success(let profile):
                self.profileImageService.fetchProfileImageURL(username: profile.username) { _ in }
                self.switchToTabBarController()
            case .failure(let error):
                print("[SplashViewController.fetchProfile]: \(error)")
                self.showAuthViewController()
            }
        }
    }

    private func switchToTabBarController() {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else {
            print("[SplashViewController.switchToTabBarController]: не удалось получить keyWindow")
            return
        }

        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        guard let tabBarController = storyboard.instantiateViewController(
            withIdentifier: "TabBarViewController"
        ) as? TabBarController else {
            print("[SplashViewController.switchToTabBarController]: не удалось создать TabBarController из Main.storyboard")
            return
        }

        window.rootViewController = tabBarController
    }
}

// MARK: - AuthViewControllerDelegate

extension SplashViewController: AuthViewControllerDelegate {
    func didAuthenticate(_ vc: AuthViewController) {
        vc.dismiss(animated: true) { [weak self] in
            guard let self, let token = self.tokenStorage.token else { return }
            self.fetchProfile(token)
        }
    }
}

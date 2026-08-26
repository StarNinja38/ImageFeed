import UIKit

final class SplashViewController: UIViewController {

    private let logoImageView = UIImageView()
    private let tokenStorage = OAuth2TokenStorage()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "YP Black")
        setupLogo()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if tokenStorage.token != nil {
            switchToTabBarController()
        } else {
            showAuthViewController()
        }
    }

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

    private func showAuthViewController() {
        let authViewController = AuthViewController()
        authViewController.delegate = self
        authViewController.modalPresentationStyle = .fullScreen
        present(authViewController, animated: true)
    }

    private func switchToTabBarController() {
        guard let window = view.window else {
            print("[SplashViewController.switchToTabBarController]: не удалось получить window")
            return
        }

        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        guard let imagesListViewController = storyboard.instantiateViewController(
            withIdentifier: "ImagesListViewController"
        ) as? ImagesListViewController else {
            print("[SplashViewController.switchToTabBarController]: не удалось создать ImagesListViewController из Main.storyboard")
            return
        }

        let profileViewController = ProfileViewController()

        imagesListViewController.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(named: "tab_editorial_active"),
            selectedImage: nil
        )
        profileViewController.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(named: "tab_profile_active"),
            selectedImage: nil
        )

        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [imagesListViewController, profileViewController]
        tabBarController.tabBar.barTintColor = UIColor(named: "YP Black")
        tabBarController.tabBar.tintColor = .white

        window.rootViewController = tabBarController
    }
}

// MARK: - AuthViewControllerDelegate

extension SplashViewController: AuthViewControllerDelegate {
    func didAuthenticate(_ vc: AuthViewController) {
        vc.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            self.switchToTabBarController()
        }
    }
}

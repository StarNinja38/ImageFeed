import UIKit

// MARK: - TabBarController

final class TabBarController: UITabBarController {

    override func awakeFromNib() {
        super.awakeFromNib()

        let imagesListViewController = ImagesListViewController()

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

        viewControllers = [imagesListViewController, profileViewController]
        setupTabBarAppearance()
    }

    /// С iOS 15 `barTintColor` игнорируется — фон задаётся через `UITabBarAppearance`,
    /// иначе панель остаётся светлой и белые иконки на ней не видны.
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(named: "YP Black")
        appearance.shadowColor = .clear

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = .white
        tabBar.unselectedItemTintColor = .white
    }
}

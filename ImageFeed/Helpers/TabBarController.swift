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
        tabBar.barTintColor = UIColor(named: "YP Black")
        tabBar.tintColor = .white
    }
}

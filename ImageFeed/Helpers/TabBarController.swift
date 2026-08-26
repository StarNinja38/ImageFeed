import UIKit

// MARK: - TabBarController

final class TabBarController: UITabBarController {

    override func awakeFromNib() {
        super.awakeFromNib()

        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        guard let imagesListViewController = storyboard.instantiateViewController(
            withIdentifier: "ImagesListViewController"
        ) as? ImagesListViewController else {
            print("[TabBarController.awakeFromNib]: не удалось создать ImagesListViewController")
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

        viewControllers = [imagesListViewController, profileViewController]
        tabBar.barTintColor = UIColor(named: "YP Black")
        tabBar.tintColor = .white
    }
}

import Foundation

// MARK: - Протоколы View ↔ Presenter

protocol ProfileViewControllerProtocol: AnyObject {
    var presenter: ProfilePresenterProtocol? { get set }
    func updateProfileDetails(name: String, loginName: String, bio: String?)
    func updateAvatar(url: URL)
    func showLogoutAlert()
    func switchToSplash()
}

protocol ProfilePresenterProtocol: AnyObject {
    var view: ProfileViewControllerProtocol? { get set }
    func viewDidLoad()
    func didTapLogout()
    func confirmLogout()
    func avatarURL() -> URL?
}

// MARK: - ProfilePresenter

final class ProfilePresenter: ProfilePresenterProtocol {

    weak var view: ProfileViewControllerProtocol?

    private let profileService: ProfileService
    private let profileImageService: ProfileImageService
    private let logoutService: ProfileLogoutService
    private var profileImageServiceObserver: NSObjectProtocol?

    init(
        profileService: ProfileService = .shared,
        profileImageService: ProfileImageService = .shared,
        logoutService: ProfileLogoutService = .shared
    ) {
        self.profileService = profileService
        self.profileImageService = profileImageService
        self.logoutService = logoutService
    }

    func viewDidLoad() {
        showProfileDetails()
        observeAvatarChanges()
        showAvatar()
    }

    func didTapLogout() {
        view?.showLogoutAlert()
    }

    func confirmLogout() {
        logoutService.logout()
        view?.switchToSplash()
    }

    func avatarURL() -> URL? {
        guard let urlString = profileImageService.avatarURL else { return nil }
        return URL(string: urlString)
    }

    // MARK: Приватное

    private func showProfileDetails() {
        guard let profile = profileService.profile else {
            print("[ProfilePresenter.showProfileDetails]: профиль ещё не загружен")
            return
        }
        view?.updateProfileDetails(
            name: profile.name,
            loginName: profile.loginName,
            bio: profile.bio
        )
    }

    private func observeAvatarChanges() {
        profileImageServiceObserver = NotificationCenter.default.addObserver(
            forName: ProfileImageService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.showAvatar()
        }
    }

    private func showAvatar() {
        guard let url = avatarURL() else { return }
        view?.updateAvatar(url: url)
    }
}

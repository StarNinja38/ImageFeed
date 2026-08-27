import XCTest
@testable import ImageFeed

final class ProfileTests: XCTestCase {

    private func makeProfile() -> Profile {
        Profile(result: ProfileResult(
            username: "starninja",
            firstName: "Mike",
            lastName: "Zhura",
            bio: "iOS-разработчик"
        ))
    }

    // Контроллер при загрузке дёргает презентер.
    func testViewControllerCallsViewDidLoad() {
        // Given
        let viewController = ProfileViewController()
        let presenter = ProfilePresenterSpy()
        viewController.presenter = presenter
        presenter.view = viewController

        // When
        _ = viewController.view

        // Then
        XCTAssertTrue(presenter.viewDidLoadCalled)
    }

    // Презентер отдаёт вью имя, логин и био из сервиса.
    func testPresenterUpdatesProfileDetails() {
        // Given
        let view = ProfileViewControllerSpy()
        let presenter = ProfilePresenter(
            profileService: ProfileServiceStub(profile: makeProfile()),
            profileImageService: ProfileImageServiceStub(avatarURL: nil),
            logoutService: ProfileLogoutServiceSpy()
        )
        view.presenter = presenter
        presenter.view = view

        // When
        presenter.viewDidLoad()

        // Then
        XCTAssertTrue(view.updateProfileDetailsCalled)
        XCTAssertEqual(view.lastName, "Mike Zhura")
        XCTAssertEqual(view.lastLoginName, "@starninja")
        XCTAssertEqual(view.lastBio, "iOS-разработчик")
    }

    // Есть аватар в сервисе — вью получает URL.
    func testPresenterUpdatesAvatar() {
        // Given
        let view = ProfileViewControllerSpy()
        let presenter = ProfilePresenter(
            profileService: ProfileServiceStub(profile: makeProfile()),
            profileImageService: ProfileImageServiceStub(avatarURL: "https://example.com/avatar.jpg"),
            logoutService: ProfileLogoutServiceSpy()
        )
        view.presenter = presenter
        presenter.view = view

        // When
        presenter.viewDidLoad()

        // Then
        XCTAssertEqual(view.lastAvatarURL?.absoluteString, "https://example.com/avatar.jpg")
    }

    // Тап по кнопке выхода только показывает алерт — разлогин ещё не делается.
    func testDidTapLogoutShowsAlertOnly() {
        // Given
        let view = ProfileViewControllerSpy()
        let logoutService = ProfileLogoutServiceSpy()
        let presenter = ProfilePresenter(
            profileService: ProfileServiceStub(profile: makeProfile()),
            profileImageService: ProfileImageServiceStub(avatarURL: nil),
            logoutService: logoutService
        )
        view.presenter = presenter
        presenter.view = view

        // When
        presenter.didTapLogout()

        // Then
        XCTAssertTrue(view.showLogoutAlertCalled)
        XCTAssertFalse(logoutService.logoutCalled)
    }

    // Подтверждение — чистим данные и уходим на сплеш.
    func testConfirmLogoutClearsDataAndSwitchesToSplash() {
        // Given
        let view = ProfileViewControllerSpy()
        let logoutService = ProfileLogoutServiceSpy()
        let presenter = ProfilePresenter(
            profileService: ProfileServiceStub(profile: makeProfile()),
            profileImageService: ProfileImageServiceStub(avatarURL: nil),
            logoutService: logoutService
        )
        view.presenter = presenter
        presenter.view = view

        // When
        presenter.confirmLogout()

        // Then
        XCTAssertTrue(logoutService.logoutCalled)
        XCTAssertTrue(view.switchToSplashCalled)
    }
}

import Foundation
@testable import ImageFeed

// MARK: - Дублёры для WebView

final class WebViewViewControllerSpy: WebViewViewControllerProtocol {
    var presenter: WebViewPresenterProtocol?

    var loadRequestCalled = false
    var lastRequest: URLRequest?
    var lastProgressValue: Float?
    var lastProgressHidden: Bool?

    func load(request: URLRequest) {
        loadRequestCalled = true
        lastRequest = request
    }

    func setProgressValue(_ newValue: Float) {
        lastProgressValue = newValue
    }

    func setProgressHidden(_ isHidden: Bool) {
        lastProgressHidden = isHidden
    }
}

final class WebViewPresenterSpy: WebViewPresenterProtocol {
    var view: WebViewViewControllerProtocol?

    var viewDidLoadCalled = false

    func viewDidLoad() {
        viewDidLoadCalled = true
    }

    func didUpdateProgressValue(_ newValue: Double) { }

    func code(from url: URL) -> String? {
        nil
    }
}

// MARK: - Дублёры для Profile

final class ProfileViewControllerSpy: ProfileViewControllerProtocol {
    var presenter: ProfilePresenterProtocol?

    var updateProfileDetailsCalled = false
    var lastName: String?
    var lastLoginName: String?
    var lastBio: String?
    var lastAvatarURL: URL?
    var showLogoutAlertCalled = false
    var switchToSplashCalled = false

    func updateProfileDetails(name: String, loginName: String, bio: String?) {
        updateProfileDetailsCalled = true
        lastName = name
        lastLoginName = loginName
        lastBio = bio
    }

    func updateAvatar(url: URL) {
        lastAvatarURL = url
    }

    func showLogoutAlert() {
        showLogoutAlertCalled = true
    }

    func switchToSplash() {
        switchToSplashCalled = true
    }
}

final class ProfilePresenterSpy: ProfilePresenterProtocol {
    var view: ProfileViewControllerProtocol?

    var viewDidLoadCalled = false

    func viewDidLoad() {
        viewDidLoadCalled = true
    }

    func didTapLogout() { }

    func confirmLogout() { }

    func avatarURL() -> URL? {
        nil
    }
}

final class ProfileServiceStub: ProfileServiceProtocol {
    var profile: Profile?

    init(profile: Profile?) {
        self.profile = profile
    }
}

final class ProfileImageServiceStub: ProfileImageServiceProtocol {
    var avatarURL: String?

    init(avatarURL: String?) {
        self.avatarURL = avatarURL
    }
}

final class ProfileLogoutServiceSpy: ProfileLogoutServiceProtocol {
    var logoutCalled = false

    func logout() {
        logoutCalled = true
    }
}

// MARK: - Дублёры для ImagesList

final class ImagesListViewControllerSpy: ImagesListViewControllerProtocol {
    var presenter: ImagesListPresenterProtocol?

    var updateTableViewCalled = false
    var lastOldCount: Int?
    var lastNewCount: Int?
    var lastIsLiked: Bool?
    var lastLikedIndexPath: IndexPath?
    var showLikeErrorAlertCalled = false
    var lastSingleImageURL: URL?

    func updateTableViewAnimated(oldCount: Int, newCount: Int) {
        updateTableViewCalled = true
        lastOldCount = oldCount
        lastNewCount = newCount
    }

    func setIsLiked(_ isLiked: Bool, at indexPath: IndexPath) {
        lastIsLiked = isLiked
        lastLikedIndexPath = indexPath
    }

    func showLikeErrorAlert() {
        showLikeErrorAlertCalled = true
    }

    func showSingleImage(url: URL?) {
        lastSingleImageURL = url
    }
}

final class ImagesListPresenterSpy: ImagesListPresenterProtocol {
    var view: ImagesListViewControllerProtocol?
    var photos: [Photo] = []

    var viewDidLoadCalled = false

    func viewDidLoad() {
        viewDidLoadCalled = true
    }

    func fetchPhotosNextPageIfNeeded(at index: Int) { }

    func didTapLike(at indexPath: IndexPath) { }

    func didSelectPhoto(at index: Int) { }

    func cellHeight(at index: Int, tableWidth: CGFloat) -> CGFloat {
        0
    }
}

final class ImagesListServiceFake: ImagesListServiceProtocol {
    private(set) var photos: [Photo] = []

    var fetchPhotosNextPageCallCount = 0
    var changeLikeResult: Result<Void, Error> = .success(())
    var lastChangeLikePhotoId: String?
    var lastChangeLikeIsLike: Bool?

    init(photos: [Photo] = []) {
        self.photos = photos
    }

    func fetchPhotosNextPage() {
        fetchPhotosNextPageCallCount += 1
    }

    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void) {
        lastChangeLikePhotoId = photoId
        lastChangeLikeIsLike = isLike
        if case .success = changeLikeResult,
           let index = photos.firstIndex(where: { $0.id == photoId }) {
            photos[index] = photos[index].withChangedLike()
        }
        completion(changeLikeResult)
    }

    /// Имитирует приход новой страницы и уведомление, на которое подписан презентер.
    func simulateNewPage(_ newPhotos: [Photo]) {
        photos.append(contentsOf: newPhotos)
        NotificationCenter.default.post(name: ImagesListService.didChangeNotification, object: nil)
    }
}

// MARK: - Фабрика тестовых данных

enum TestData {
    static func makePhoto(id: String, width: Int = 500, height: Int = 250, isLiked: Bool = false) -> Photo {
        Photo(
            id: id,
            size: CGSize(width: width, height: height),
            createdAt: nil,
            welcomeDescription: nil,
            thumbImageURL: "https://example.com/\(id)-thumb.jpg",
            largeImageURL: "https://example.com/\(id)-large.jpg",
            isLiked: isLiked
        )
    }
}

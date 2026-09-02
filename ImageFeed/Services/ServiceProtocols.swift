import Foundation

// MARK: - Протоколы сервисов

/// Презентеры зависят от протоколов, а не от синглтонов — так в тестах
/// вместо сети подставляется fake-объект.

protocol ImagesListServiceProtocol: AnyObject {
    var photos: [Photo] { get }
    func fetchPhotosNextPage()
    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void)
}

protocol ProfileServiceProtocol: AnyObject {
    var profile: Profile? { get }
}

protocol ProfileImageServiceProtocol: AnyObject {
    var avatarURL: String? { get }
}

protocol ProfileLogoutServiceProtocol: AnyObject {
    func logout()
}

// MARK: - Соответствие боевых сервисов

extension ImagesListService: ImagesListServiceProtocol {}
extension ProfileService: ProfileServiceProtocol {}
extension ProfileImageService: ProfileImageServiceProtocol {}
extension ProfileLogoutService: ProfileLogoutServiceProtocol {}

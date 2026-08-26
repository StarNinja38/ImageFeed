import Foundation

// MARK: - ProfileImageService

final class ProfileImageService {

    static let shared = ProfileImageService()
    private init() {}

    static let didChangeNotification = Notification.Name("ProfileImageProviderDidChange")

    private let urlSession = URLSession.shared
    private let tokenStorage = OAuth2TokenStorage()
    private var task: URLSessionTask?
    private var lastUsername: String?

    private(set) var avatarURL: String?

    func fetchProfileImageURL(
        username: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        assert(Thread.isMainThread)

        if lastUsername == username {
            print("[ProfileImageService.fetchProfileImageURL]: AuthServiceError.invalidRequest - повторный вызов для \(username)")
            completion(.failure(AuthServiceError.invalidRequest))
            return
        }
        task?.cancel()
        lastUsername = username

        guard let request = makeProfileImageRequest(username: username) else {
            print("[ProfileImageService.fetchProfileImageURL]: AuthServiceError.invalidRequest - не удалось собрать URLRequest, username: \(username)")
            completion(.failure(AuthServiceError.invalidRequest))
            return
        }

        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<UserResult, Error>) in
            guard let self else { return }

            switch result {
            case .success(let userResult):
                guard let imageURL = userResult.profileImage?.large ?? userResult.profileImage?.medium else {
                    print("[ProfileImageService.fetchProfileImageURL]: NetworkError.urlSessionError - в ответе нет profile_image, username: \(username)")
                    completion(.failure(NetworkError.urlSessionError))
                    self.task = nil
                    self.lastUsername = nil
                    return
                }
                self.avatarURL = imageURL
                completion(.success(imageURL))
                NotificationCenter.default.post(
                    name: ProfileImageService.didChangeNotification,
                    object: self,
                    userInfo: ["URL": imageURL]
                )
            case .failure(let error):
                print("[ProfileImageService.fetchProfileImageURL]: \(error) - username: \(username)")
                completion(.failure(error))
            }

            self.task = nil
            self.lastUsername = nil
        }

        self.task = task
        task.resume()
    }

    private func makeProfileImageRequest(username: String) -> URLRequest? {
        guard let token = tokenStorage.token else {
            print("[ProfileImageService.makeProfileImageRequest]: нет Bearer Token в хранилище")
            return nil
        }
        guard let url = URL(string: "\(Constants.defaultBaseURLString)/users/\(username)") else {
            print("[ProfileImageService.makeProfileImageRequest]: не удалось создать URL для /users/\(username)")
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}

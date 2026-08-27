import Foundation

// MARK: - ProfileService

final class ProfileService {

    static let shared = ProfileService()
    private init() {}

    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private var lastToken: String?

    private(set) var profile: Profile?

    func fetchProfile(
        _ token: String,
        completion: @escaping (Result<Profile, Error>) -> Void
    ) {
        assert(Thread.isMainThread)

        if lastToken == token {
            print("[ProfileService.fetchProfile]: AuthServiceError.invalidRequest - повторный вызов с тем же токеном")
            completion(.failure(AuthServiceError.invalidRequest))
            return
        }
        task?.cancel()
        lastToken = token

        guard let request = makeProfileRequest(token: token) else {
            print("[ProfileService.fetchProfile]: AuthServiceError.invalidRequest - не удалось собрать URLRequest")
            completion(.failure(AuthServiceError.invalidRequest))
            return
        }

        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<ProfileResult, Error>) in
            guard let self else { return }

            // Ответ устаревшего запроса игнорируем — иначе он затрёт состояние актуального.
            guard self.lastToken == token else { return }

            self.task = nil
            self.lastToken = nil

            switch result {
            case .success(let profileResult):
                let profile = Profile(result: profileResult)
                self.profile = profile
                completion(.success(profile))
            case .failure(let error):
                print("[ProfileService.fetchProfile]: \(error)")
                completion(.failure(error))
            }
        }

        self.task = task
        task.resume()
    }

    private func makeProfileRequest(token: String) -> URLRequest? {
        guard let url = URL(string: "\(Constants.defaultBaseURLString)/me") else {
            print("[ProfileService.makeProfileRequest]: не удалось создать URL для /me")
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}

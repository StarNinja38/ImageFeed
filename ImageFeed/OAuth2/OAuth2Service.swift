import Foundation

enum AuthServiceError: Error {
    case invalidRequest
}

// MARK: - OAuth2Service

final class OAuth2Service {

    static let shared = OAuth2Service()
    private init() {}

    private let urlSession = URLSession.shared
    private let tokenStorage = OAuth2TokenStorage()

    /// Текущий запрос и код, с которым он ушёл, — защита от гонки.
    private var task: URLSessionTask?
    private var lastCode: String?

    func fetchOAuthToken(
        code: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        assert(Thread.isMainThread)

        // Тот же код и запрос ещё в полёте — второй вызов не нужен.
        if lastCode == code {
            print("[OAuth2Service.fetchOAuthToken]: AuthServiceError.invalidRequest - повторный вызов с тем же code")
            completion(.failure(AuthServiceError.invalidRequest))
            return
        }

        // Код другой — прошлый запрос уже неактуален, отменяем.
        task?.cancel()
        lastCode = code

        guard let request = makeTokenRequest(code: code) else {
            print("[OAuth2Service.fetchOAuthToken]: AuthServiceError.invalidRequest - не удалось собрать URLRequest, code: \(code)")
            completion(.failure(AuthServiceError.invalidRequest))
            return
        }

        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<OAuthTokenResponseBody, Error>) in
            guard let self else { return }

            switch result {
            case .success(let responseBody):
                self.tokenStorage.token = responseBody.accessToken
                completion(.success(responseBody.accessToken))
            case .failure(let error):
                print("[OAuth2Service.fetchOAuthToken]: \(error) - code: \(code)")
                completion(.failure(error))
            }

            self.task = nil
            self.lastCode = nil
        }

        self.task = task
        task.resume()
    }

    private func makeTokenRequest(code: String) -> URLRequest? {
        guard var urlComponents = URLComponents(string: Constants.unsplashTokenURLString) else {
            print("[OAuth2Service.makeTokenRequest]: не удалось создать URLComponents из \(Constants.unsplashTokenURLString)")
            return nil
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code")
        ]

        guard let url = urlComponents.url else {
            print("[OAuth2Service.makeTokenRequest]: не удалось получить URL из URLComponents")
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        return request
    }
}

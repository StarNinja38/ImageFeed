import Foundation

enum AuthServiceError: Error {
    case invalidURLComponents
    case invalidURL
    case httpStatusCode(Int)
    case urlRequestError(Error)
    case urlSessionError
    case decodingError(Error)
}

final class OAuth2Service {

    static let shared = OAuth2Service()
    private init() {}

    private enum HTTPStatus {
        static let successRange = 200..<300
    }

    private let tokenStorage = OAuth2TokenStorage()

    func fetchAuthToken(
        code: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let request = makeTokenRequest(code: code) else {
            print("[OAuth2Service.fetchAuthToken]: не удалось собрать URLRequest для code")
            completeOnMainThread(completion, .failure(AuthServiceError.invalidURL))
            return
        }

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self else { return }

            if let error {
                print("[OAuth2Service.fetchAuthToken]: сетевая ошибка — \(error.localizedDescription)")
                self.completeOnMainThread(completion, .failure(AuthServiceError.urlRequestError(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("[OAuth2Service.fetchAuthToken]: ответ не является HTTPURLResponse")
                self.completeOnMainThread(completion, .failure(AuthServiceError.urlSessionError))
                return
            }

            let statusCode = httpResponse.statusCode
            guard HTTPStatus.successRange.contains(statusCode) else {
                print("[OAuth2Service.fetchAuthToken]: сервис Unsplash вернул код \(statusCode)")
                self.completeOnMainThread(completion, .failure(AuthServiceError.httpStatusCode(statusCode)))
                return
            }

            guard let data else {
                print("[OAuth2Service.fetchAuthToken]: пустое тело ответа при коде \(statusCode)")
                self.completeOnMainThread(completion, .failure(AuthServiceError.urlSessionError))
                return
            }

            do {
                let responseBody = try JSONDecoder().decode(OAuthTokenResponseBody.self, from: data)
                self.tokenStorage.token = responseBody.accessToken
                self.completeOnMainThread(completion, .success(responseBody.accessToken))
            } catch {
                print("[OAuth2Service.fetchAuthToken]: ошибка декодирования OAuthTokenResponseBody — \(error.localizedDescription)")
                self.completeOnMainThread(completion, .failure(AuthServiceError.decodingError(error)))
            }
        }
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

    private func completeOnMainThread(
        _ completion: @escaping (Result<String, Error>) -> Void,
        _ result: Result<String, Error>
    ) {
        DispatchQueue.main.async {
            completion(result)
        }
    }
}

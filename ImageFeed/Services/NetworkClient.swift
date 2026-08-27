import Foundation

enum NetworkError: Error {
    case httpStatusCode(Int)
    case urlRequestError(Error)
    case urlSessionError
    case decodingError(Error)
    case invalidRequest
}

extension URLSession {

    private enum HTTPStatus {
        static let successRange = 200..<300
    }

    /// Базовый запрос: отдаёт сырые данные, все ошибки логирует и возвращает как NetworkError.
    func data(
        for request: URLRequest,
        completion: @escaping (Result<Data, Error>) -> Void
    ) -> URLSessionTask {
        let fulfillCompletionOnMainThread: (Result<Data, Error>) -> Void = { result in
            DispatchQueue.main.async { completion(result) }
        }

        let task = dataTask(with: request) { data, response, error in
            if let error {
                print("[data(for:)]: NetworkError.urlRequestError - \(error.localizedDescription), url: \(request.url?.absoluteString ?? "nil")")
                fulfillCompletionOnMainThread(.failure(NetworkError.urlRequestError(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("[data(for:)]: NetworkError.urlSessionError - ответ не HTTPURLResponse, url: \(request.url?.absoluteString ?? "nil")")
                fulfillCompletionOnMainThread(.failure(NetworkError.urlSessionError))
                return
            }

            let statusCode = httpResponse.statusCode
            guard HTTPStatus.successRange.contains(statusCode) else {
                print("[data(for:)]: NetworkError.httpStatusCode - код ошибки \(statusCode), url: \(request.url?.absoluteString ?? "nil")")
                fulfillCompletionOnMainThread(.failure(NetworkError.httpStatusCode(statusCode)))
                return
            }

            guard let data else {
                print("[data(for:)]: NetworkError.urlSessionError - пустое тело ответа, код \(statusCode)")
                fulfillCompletionOnMainThread(.failure(NetworkError.urlSessionError))
                return
            }

            fulfillCompletionOnMainThread(.success(data))
        }
        return task
    }

    /// Дженерик-обёртка: сразу декодирует ответ в нужную модель.
    func objectTask<T: Decodable>(
        for request: URLRequest,
        completion: @escaping (Result<T, Error>) -> Void
    ) -> URLSessionTask {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return data(for: request) { result in
            switch result {
            case .success(let data):
                do {
                    let object = try decoder.decode(T.self, from: data)
                    completion(.success(object))
                } catch {
                    let raw = String(data: data, encoding: .utf8) ?? "не удалось прочитать данные"
                    print("[objectTask(for:)]: NetworkError.decodingError - \(error.localizedDescription), тип: \(T.self), данные: \(raw)")
                    completion(.failure(NetworkError.decodingError(error)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

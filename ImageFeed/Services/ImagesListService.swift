import Foundation

// MARK: - ImagesListService

final class ImagesListService {

    static let shared = ImagesListService()
    private init() {}

    static let didChangeNotification = Notification.Name(rawValue: "ImagesListServiceDidChange")

    private enum Config {
        static let perPage = 10
    }

    private let urlSession = URLSession.shared
    private let tokenStorage = OAuth2TokenStorage()

    private(set) var photos: [Photo] = []

    private var task: URLSessionTask?
    private var lastLoadedPage: Int?

    /// Сервер прислал пустую страницу — метаинформация кончилась,
    /// дальше за ней не ходим (проверяется Breakpoint'ом в Charles Proxy).
    private(set) var isLastPageLoaded = false

    private var likeTask: URLSessionTask?

    // MARK: Постраничная загрузка

    /// Номер страницы вычисляется внутри — снаружи его сообщать не нужно.
    func fetchPhotosNextPage() {
        assert(Thread.isMainThread)

        // Пока запрос в полёте, новый не создаём.
        guard task == nil else { return }

        // Крайняя страница уже получена — новых запросов не делаем.
        guard !isLastPageLoaded else { return }

        let nextPage = (lastLoadedPage ?? 0) + 1

        guard let request = makePhotosRequest(page: nextPage) else {
            print("[ImagesListService.fetchPhotosNextPage]: AuthServiceError.invalidRequest - не удалось собрать URLRequest, page: \(nextPage)")
            return
        }

        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            guard let self else { return }
            self.task = nil

            switch result {
            case .success(let photoResults):
                // Пустая страница = лента закончилась.
                guard !photoResults.isEmpty else {
                    self.isLastPageLoaded = true
                    return
                }

                // Массив обновляем на главном потоке, новые фото — в конец.
                let newPhotos = photoResults.map { Photo(from: $0) }
                self.photos.append(contentsOf: newPhotos)
                self.lastLoadedPage = nextPage
                NotificationCenter.default.post(
                    name: ImagesListService.didChangeNotification,
                    object: self
                )
            case .failure(let error):
                print("[ImagesListService.fetchPhotosNextPage]: \(error) - page: \(nextPage)")
            }
        }

        self.task = task
        task.resume()
    }

    // MARK: Лайки

    func changeLike(
        photoId: String,
        isLike: Bool,
        _ completion: @escaping (Result<Void, Error>) -> Void
    ) {
        assert(Thread.isMainThread)

        guard let request = makeLikeRequest(photoId: photoId, isLike: isLike) else {
            print("[ImagesListService.changeLike]: AuthServiceError.invalidRequest - не удалось собрать URLRequest, photoId: \(photoId)")
            completion(.failure(AuthServiceError.invalidRequest))
            return
        }

        likeTask?.cancel()

        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<PhotoLikeResult, Error>) in
            guard let self else { return }
            self.likeTask = nil

            switch result {
            case .success:
                if let index = self.photos.firstIndex(where: { $0.id == photoId }) {
                    self.photos[index] = self.photos[index].withChangedLike()
                }
                completion(.success(()))
            case .failure(let error):
                print("[ImagesListService.changeLike]: \(error) - photoId: \(photoId), isLike: \(isLike)")
                completion(.failure(error))
            }
        }

        likeTask = task
        task.resume()
    }

    /// Сброс при выходе из аккаунта.
    func clean() {
        photos = []
        lastLoadedPage = nil
        isLastPageLoaded = false
        task?.cancel()
        task = nil
        likeTask?.cancel()
        likeTask = nil
    }

    // MARK: Запросы

    private func makePhotosRequest(page: Int) -> URLRequest? {
        guard let token = tokenStorage.token else {
            print("[ImagesListService.makePhotosRequest]: нет Bearer Token в хранилище")
            return nil
        }
        guard var urlComponents = URLComponents(string: "\(Constants.defaultBaseURLString)/photos") else {
            print("[ImagesListService.makePhotosRequest]: не удалось создать URLComponents")
            return nil
        }
        urlComponents.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "\(Config.perPage)")
        ]
        guard let url = urlComponents.url else {
            print("[ImagesListService.makePhotosRequest]: не удалось получить URL из URLComponents")
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func makeLikeRequest(photoId: String, isLike: Bool) -> URLRequest? {
        guard let token = tokenStorage.token else {
            print("[ImagesListService.makeLikeRequest]: нет Bearer Token в хранилище")
            return nil
        }
        guard let url = URL(string: "\(Constants.defaultBaseURLString)/photos/\(photoId)/like") else {
            print("[ImagesListService.makeLikeRequest]: не удалось создать URL, photoId: \(photoId)")
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = isLike ? "POST" : "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}

import Foundation

// MARK: - Протоколы View ↔ Presenter

protocol ImagesListViewControllerProtocol: AnyObject {
    var presenter: ImagesListPresenterProtocol? { get set }
    func updateTableViewAnimated(oldCount: Int, newCount: Int)
    func setIsLiked(_ isLiked: Bool, at indexPath: IndexPath)
    func showLikeErrorAlert()
    func showSingleImage(url: URL?)
}

protocol ImagesListPresenterProtocol: AnyObject {
    var view: ImagesListViewControllerProtocol? { get set }
    var photos: [Photo] { get }
    func viewDidLoad()
    func fetchPhotosNextPageIfNeeded(at index: Int)
    func didTapLike(at indexPath: IndexPath)
    func didSelectPhoto(at index: Int)
    func cellHeight(at index: Int, tableWidth: CGFloat) -> CGFloat
}

// MARK: - ImagesListPresenter

final class ImagesListPresenter: ImagesListPresenterProtocol {

    private enum Layout {
        static let imageSideInset: CGFloat = 16
        static let imageVerticalInset: CGFloat = 4
        static let defaultRowHeight: CGFloat = 200
    }

    weak var view: ImagesListViewControllerProtocol?

    private(set) var photos: [Photo] = []

    private let imagesListService: ImagesListService
    private var imagesListServiceObserver: NSObjectProtocol?

    init(imagesListService: ImagesListService = .shared) {
        self.imagesListService = imagesListService
    }

    func viewDidLoad() {
        observePhotosChanges()
        imagesListService.fetchPhotosNextPage()
    }

    /// Долистали до последней ячейки — тянем следующую страницу.
    func fetchPhotosNextPageIfNeeded(at index: Int) {
        guard index + 1 == photos.count else { return }
        imagesListService.fetchPhotosNextPage()
    }

    func didTapLike(at indexPath: IndexPath) {
        guard indexPath.row < photos.count else { return }
        let photo = photos[indexPath.row]

        UIBlockingProgressHUD.show()
        imagesListService.changeLike(photoId: photo.id, isLike: !photo.isLiked) { [weak self] result in
            UIBlockingProgressHUD.dismiss()
            guard let self else { return }

            switch result {
            case .success:
                self.photos = self.imagesListService.photos
                guard indexPath.row < self.photos.count else { return }
                self.view?.setIsLiked(self.photos[indexPath.row].isLiked, at: indexPath)
            case .failure(let error):
                print("[ImagesListPresenter.didTapLike]: \(error) - photoId: \(photo.id)")
                self.view?.showLikeErrorAlert()
            }
        }
    }

    func didSelectPhoto(at index: Int) {
        guard index < photos.count else { return }
        view?.showSingleImage(url: URL(string: photos[index].largeImageURL))
    }

    /// Высота считается по пропорциям фото, известным до загрузки картинки.
    func cellHeight(at index: Int, tableWidth: CGFloat) -> CGFloat {
        guard index < photos.count else { return Layout.defaultRowHeight }
        let photo = photos[index]
        guard photo.size.width > 0 else { return Layout.defaultRowHeight }
        let imageViewWidth = tableWidth - Layout.imageSideInset * 2
        let scale = imageViewWidth / photo.size.width
        return photo.size.height * scale + Layout.imageVerticalInset * 2
    }

    // MARK: Приватное

    private func observePhotosChanges() {
        imagesListServiceObserver = NotificationCenter.default.addObserver(
            forName: ImagesListService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            let oldCount = self.photos.count
            self.photos = self.imagesListService.photos
            self.view?.updateTableViewAnimated(oldCount: oldCount, newCount: self.photos.count)
        }
    }
}

import UIKit
import ProgressHUD

// MARK: - ImagesListViewController

final class ImagesListViewController: UIViewController {

    private enum Layout {
        static let contentInset: CGFloat = 12
        static let imageSideInset: CGFloat = 16
        static let imageVerticalInset: CGFloat = 4
        static let defaultRowHeight: CGFloat = 200
    }

    private let tableView = UITableView()

    private let imagesListService = ImagesListService.shared
    private var imagesListServiceObserver: NSObjectProtocol?
    private var photos: [Photo] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "YP Black")
        setupTableView()
        observePhotosChanges()
        imagesListService.fetchPhotosNextPage()
    }

    // MARK: Обновление ленты

    private func observePhotosChanges() {
        imagesListServiceObserver = NotificationCenter.default.addObserver(
            forName: ImagesListService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.updateTableViewAnimated()
        }
    }

    /// Анимированно доливает новые строки, не перерисовывая уже показанные.
    private func updateTableViewAnimated() {
        let oldCount = photos.count
        let newCount = imagesListService.photos.count
        photos = imagesListService.photos

        guard oldCount != newCount else { return }

        tableView.performBatchUpdates {
            let indexPaths = (oldCount..<newCount).map { IndexPath(row: $0, section: 0) }
            tableView.insertRows(at: indexPaths, with: .automatic)
        }
    }

    // MARK: Вёрстка кодом

    private func setupTableView() {
        tableView.backgroundColor = UIColor(named: "YP Black")
        tableView.separatorStyle = .none
        tableView.rowHeight = Layout.defaultRowHeight
        tableView.contentInset = UIEdgeInsets(
            top: Layout.contentInset,
            left: 0,
            bottom: Layout.contentInset,
            right: 0
        )
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ImagesListCell.self, forCellReuseIdentifier: ImagesListCell.reuseIdentifier)
        tableView.accessibilityIdentifier = "ImagesListTable"
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: - UITableViewDataSource

extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        photos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ImagesListCell.reuseIdentifier,
            for: indexPath
        )
        guard let imagesListCell = cell as? ImagesListCell else {
            return UITableViewCell()
        }
        imagesListCell.delegate = self
        imagesListCell.configure(with: photos[indexPath.row])
        return imagesListCell
    }
}

// MARK: - UITableViewDelegate

extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let singleImageViewController = SingleImageViewController()
        singleImageViewController.imageURL = URL(string: photos[indexPath.row].largeImageURL)
        singleImageViewController.modalPresentationStyle = .fullScreen
        present(singleImageViewController, animated: true)
    }

    /// Высота зависит от пропорций фото, известных ещё до загрузки картинки.
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let photo = photos[indexPath.row]
        guard photo.size.width > 0 else { return Layout.defaultRowHeight }
        let imageViewWidth = tableView.bounds.width - Layout.imageSideInset * 2
        let scale = imageViewWidth / photo.size.width
        return photo.size.height * scale + Layout.imageVerticalInset * 2
    }

    /// Долистали до последней ячейки — тянем следующую страницу.
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == photos.count {
            imagesListService.fetchPhotosNextPage()
        }
    }
}

// MARK: - ImagesListCellDelegate

extension ImagesListViewController: ImagesListCellDelegate {
    func imageListCellDidTapLike(_ cell: ImagesListCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let photo = photos[indexPath.row]

        // Блокируем UI, чтобы не поймать гонку из-за повторных тапов.
        UIBlockingProgressHUD.show()
        imagesListService.changeLike(photoId: photo.id, isLike: !photo.isLiked) { [weak self] result in
            UIBlockingProgressHUD.dismiss()
            guard let self else { return }

            switch result {
            case .success:
                self.photos = self.imagesListService.photos
                cell.setIsLiked(self.photos[indexPath.row].isLiked)
            case .failure(let error):
                print("[ImagesListViewController.imageListCellDidTapLike]: \(error) - photoId: \(photo.id)")
                self.showLikeErrorAlert()
            }
        }
    }

    private func showLikeErrorAlert() {
        let alert = UIAlertController(
            title: "Что-то пошло не так(",
            message: "Не удалось поставить лайк",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }
}

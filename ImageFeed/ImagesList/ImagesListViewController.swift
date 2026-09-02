import UIKit

// MARK: - ImagesListViewController

/// После рефакторинга на MVP контроллер только показывает таблицу:
/// загрузка страниц, лайки и расчёт высоты живут в `ImagesListPresenter`.
final class ImagesListViewController: UIViewController & ImagesListViewControllerProtocol {

    private enum Layout {
        static let contentInset: CGFloat = 12
        static let defaultRowHeight: CGFloat = 200
    }

    var presenter: ImagesListPresenterProtocol?

    private let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "YP Black")
        setupTableView()
        presenter?.viewDidLoad()
    }

    // MARK: - ImagesListViewControllerProtocol

    func updateTableViewAnimated(oldCount: Int, newCount: Int) {
        guard oldCount != newCount else { return }
        tableView.performBatchUpdates {
            let indexPaths = (oldCount..<newCount).map { IndexPath(row: $0, section: 0) }
            tableView.insertRows(at: indexPaths, with: .automatic)
        }
    }

    func setIsLiked(_ isLiked: Bool, at indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? ImagesListCell else { return }
        cell.setIsLiked(isLiked)
    }

    func showLikeErrorAlert() {
        let alert = UIAlertController(
            title: "Что-то пошло не так(",
            message: "Не удалось поставить лайк",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }

    func showSingleImage(url: URL?) {
        let singleImageViewController = SingleImageViewController()
        singleImageViewController.imageURL = url
        singleImageViewController.modalPresentationStyle = .fullScreen
        present(singleImageViewController, animated: true)
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
        presenter?.photos.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ImagesListCell.reuseIdentifier,
            for: indexPath
        )
        guard
            let imagesListCell = cell as? ImagesListCell,
            let photo = presenter?.photos[safe: indexPath.row]
        else {
            return UITableViewCell()
        }
        imagesListCell.delegate = self
        imagesListCell.configure(with: photo)
        return imagesListCell
    }
}

// MARK: - UITableViewDelegate

extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        presenter?.didSelectPhoto(at: indexPath.row)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        presenter?.cellHeight(at: indexPath.row, tableWidth: tableView.bounds.width) ?? Layout.defaultRowHeight
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        presenter?.fetchPhotosNextPageIfNeeded(at: indexPath.row)
    }
}

// MARK: - ImagesListCellDelegate

extension ImagesListViewController: ImagesListCellDelegate {
    func imageListCellDidTapLike(_ cell: ImagesListCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        presenter?.didTapLike(at: indexPath)
    }
}

// MARK: - Безопасный доступ по индексу

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

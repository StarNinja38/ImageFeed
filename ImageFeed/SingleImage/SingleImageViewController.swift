import UIKit
import Kingfisher
import ProgressHUD

// MARK: - SingleImageViewController

final class SingleImageViewController: UIViewController {

    private enum Layout {
        static let backButtonInset: CGFloat = 9
        static let backButtonSize: CGFloat = 44
        static let shareButtonSize: CGFloat = 51
        static let shareBottomInset: CGFloat = 17
    }

    private enum Zoom {
        static let minimum: CGFloat = 0.1
        static let maximum: CGFloat = 1.25
    }

    /// Ссылка на полноразмерную версию — грузим через Kingfisher.
    var imageURL: URL?

    var image: UIImage? {
        didSet {
            guard isViewLoaded, let image else { return }
            imageView.image = image
            imageView.frame.size = image.size
            rescaleAndCenterImageInScrollView(image: image)
        }
    }

    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private let backButton = UIButton(type: .custom)
    private let shareButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "YP Black")

        setupScrollView()
        setupBackButton()
        setupShareButton()

        scrollView.minimumZoomScale = Zoom.minimum
        scrollView.maximumZoomScale = Zoom.maximum

        if imageURL != nil {
            loadFullImage()
            return
        }

        guard let image else { return }
        imageView.image = image
        imageView.frame.size = image.size
        rescaleAndCenterImageInScrollView(image: image)
    }

    // MARK: Загрузка полноразмерного фото

    private func loadFullImage() {
        guard let imageURL else { return }

        UIBlockingProgressHUD.show()
        imageView.kf.setImage(with: imageURL) { [weak self] result in
            UIBlockingProgressHUD.dismiss()
            guard let self else { return }

            switch result {
            case .success(let value):
                self.image = value.image
                self.imageView.frame.size = value.image.size
                self.rescaleAndCenterImageInScrollView(image: value.image)
            case .failure(let error):
                print("[SingleImageViewController.loadFullImage]: \(error) - url: \(imageURL.absoluteString)")
                self.showLoadErrorAlert()
            }
        }
    }

    private func showLoadErrorAlert() {
        let alert = UIAlertController(
            title: "Что-то пошло не так(",
            message: "Попробовать ещё раз?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Не надо", style: .cancel))
        alert.addAction(UIAlertAction(title: "Повторить", style: .default) { [weak self] _ in
            self?.loadFullImage()
        })
        present(alert, animated: true)
    }

    // MARK: Вёрстка кодом

    private func setupScrollView() {
        scrollView.delegate = self
        scrollView.backgroundColor = UIColor(named: "YP Black")
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        imageView.contentMode = .scaleAspectFill
        scrollView.addSubview(imageView)
    }

    private func setupBackButton() {
        backButton.setImage(UIImage(named: "nav_back_button_white"), for: .normal)
        backButton.addTarget(self, action: #selector(didTapBackButton), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backButton)
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: Layout.backButtonInset),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Layout.backButtonInset),
            backButton.widthAnchor.constraint(equalToConstant: Layout.backButtonSize),
            backButton.heightAnchor.constraint(equalToConstant: Layout.backButtonSize)
        ])
    }

    /// Кнопка «Поделиться» — НАД ScrollView, а не внутри него (требование ТЗ).
    private func setupShareButton() {
        shareButton.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        shareButton.tintColor = .white
        shareButton.addTarget(self, action: #selector(didTapShareButton), for: .touchUpInside)
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(shareButton)
        NSLayoutConstraint.activate([
            shareButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shareButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Layout.shareBottomInset),
            shareButton.widthAnchor.constraint(equalToConstant: Layout.shareButtonSize),
            shareButton.heightAnchor.constraint(equalToConstant: Layout.shareButtonSize)
        ])
    }

    // MARK: Действия

    @objc private func didTapBackButton() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func didTapShareButton() {
        guard let image else { return }
        let share = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(share, animated: true, completion: nil)
    }

    // MARK: Зум и центрирование

    private func rescaleAndCenterImageInScrollView(image: UIImage) {
        let minZoomScale = scrollView.minimumZoomScale
        let maxZoomScale = scrollView.maximumZoomScale
        view.layoutIfNeeded()
        let visibleRectSize = scrollView.bounds.size
        let imageSize = image.size
        let hScale = visibleRectSize.width / imageSize.width
        let vScale = visibleRectSize.height / imageSize.height
        let scale = min(maxZoomScale, max(minZoomScale, min(hScale, vScale)))
        scrollView.setZoomScale(scale, animated: false)
        scrollView.layoutIfNeeded()
        let newContentSize = scrollView.contentSize
        let x = (newContentSize.width - visibleRectSize.width) / 2
        let y = (newContentSize.height - visibleRectSize.height) / 2
        scrollView.setContentOffset(CGPoint(x: x, y: y), animated: false)
    }
}

// MARK: - UIScrollViewDelegate

extension SingleImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
}

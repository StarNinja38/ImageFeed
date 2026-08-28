import UIKit
import Kingfisher

// MARK: - ImagesListCellDelegate

/// Ячейка свёрстана кодом (задача ⭐ Спринта 11), поэтому вместо `@IBAction`
/// о тапе по лайку сообщаем делегату.
protocol ImagesListCellDelegate: AnyObject {
    func imageListCellDidTapLike(_ cell: ImagesListCell)
}

// MARK: - ImagesListCell

final class ImagesListCell: UITableViewCell {

    static let reuseIdentifier = "ImagesListCell"

    weak var delegate: ImagesListCellDelegate?

    private enum Layout {
        static let imageSideInset: CGFloat = 16
        static let imageVerticalInset: CGFloat = 4
        static let cornerRadius: CGFloat = 16
        static let labelInset: CGFloat = 8
        static let likeButtonSize: CGFloat = 44
        static let dateFontSize: CGFloat = 13
    }

    let cellImage = UIImageView()
    let dateLabel = UILabel()
    let likeButton = UIButton(type: .custom)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
        setupCellImage()
        setupLikeButton()
        setupDateLabel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cellImage.kf.cancelDownloadTask()   // отменяем загрузку прошлой картинки
        cellImage.image = nil
        dateLabel.text = nil
    }

    // MARK: Конфигурация

    func configure(with photo: Photo) {
        let placeholder = UIImage(named: "stub_photo")
        if let url = URL(string: photo.thumbImageURL) {
            cellImage.kf.indicatorType = .activity
            cellImage.kf.setImage(with: url, placeholder: placeholder)
        } else {
            cellImage.image = placeholder
        }

        if let createdAt = photo.createdAt {
            dateLabel.text = DateFormatter.feedDateFormatter.string(from: createdAt)
        } else {
            dateLabel.text = ""   // graceful degradation: дата не распарсилась
        }

        setIsLiked(photo.isLiked)
    }

    /// Меняет картинку индикатора лайка.
    func setIsLiked(_ isLiked: Bool) {
        let likeImage = isLiked ? UIImage(named: "like_button_on") : UIImage(named: "like_button_off")
        likeButton.setImage(likeImage, for: .normal)
        likeButton.accessibilityIdentifier = isLiked ? "like button on" : "like button off"
    }

    @objc private func didTapLikeButton() {
        delegate?.imageListCellDidTapLike(self)
    }

    // MARK: Вёрстка кодом

    private func setupCell() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        clipsToBounds = true
    }

    private func setupCellImage() {
        cellImage.contentMode = .scaleAspectFill
        cellImage.layer.cornerRadius = Layout.cornerRadius
        cellImage.layer.masksToBounds = true
        cellImage.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cellImage)
        NSLayoutConstraint.activate([
            cellImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Layout.imageSideInset),
            cellImage.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Layout.imageSideInset),
            cellImage.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Layout.imageVerticalInset),
            cellImage.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Layout.imageVerticalInset)
        ])
    }

    private func setupLikeButton() {
        likeButton.addTarget(self, action: #selector(didTapLikeButton), for: .touchUpInside)
        likeButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(likeButton)
        NSLayoutConstraint.activate([
            likeButton.topAnchor.constraint(equalTo: cellImage.topAnchor),
            likeButton.trailingAnchor.constraint(equalTo: cellImage.trailingAnchor),
            likeButton.widthAnchor.constraint(equalToConstant: Layout.likeButtonSize),
            likeButton.heightAnchor.constraint(equalToConstant: Layout.likeButtonSize)
        ])
    }

    private func setupDateLabel() {
        dateLabel.font = .systemFont(ofSize: Layout.dateFontSize)
        dateLabel.textColor = .white
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dateLabel)
        NSLayoutConstraint.activate([
            dateLabel.leadingAnchor.constraint(equalTo: cellImage.leadingAnchor, constant: Layout.labelInset),
            dateLabel.bottomAnchor.constraint(equalTo: cellImage.bottomAnchor, constant: -Layout.labelInset),
            dateLabel.trailingAnchor.constraint(lessThanOrEqualTo: likeButton.leadingAnchor, constant: -Layout.labelInset)
        ])
    }
}

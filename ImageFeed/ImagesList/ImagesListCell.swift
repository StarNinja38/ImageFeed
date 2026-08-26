import UIKit

// MARK: - ImagesListCell

final class ImagesListCell: UITableViewCell {

    static let reuseIdentifier = "ImagesListCell"

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

    // MARK: Инициализация (вёрстка кодом вместо прототипа в Storyboard)

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
        cellImage.image = nil
        dateLabel.text = nil
    }

    // MARK: Вёрстка

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

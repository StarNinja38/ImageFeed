import UIKit
import Kingfisher

// MARK: - ProfileViewController

final class ProfileViewController: UIViewController {

    private enum Layout {
        static let avatarSize: CGFloat = 70
        static let avatarCornerRadius: CGFloat = 35
        static let sideInset: CGFloat = 16
        static let topInset: CGFloat = 32
        static let spacing: CGFloat = 8
        static let logoutButtonSize: CGFloat = 44
    }

    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let loginNameLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let logoutButton = UIButton()

    private let profileService = ProfileService.shared
    private var profileImageServiceObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "YP Black")

        setupAvatar()
        setupLogoutButton()
        setupNameLabel()
        setupLoginNameLabel()
        setupDescriptionLabel()

        updateProfileDetails(profile: profileService.profile)
        observeAvatarChanges()
        updateAvatar()
    }

    // MARK: Данные

    private func updateProfileDetails(profile: Profile?) {
        guard let profile else {
            print("[ProfileViewController.updateProfileDetails]: профиль ещё не загружен")
            return
        }
        nameLabel.text = profile.name
        loginNameLabel.text = profile.loginName
        descriptionLabel.text = profile.bio
    }

    private func observeAvatarChanges() {
        profileImageServiceObserver = NotificationCenter.default.addObserver(
            forName: ProfileImageService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.updateAvatar()
        }
    }

    private func updateAvatar() {
        guard
            let urlString = ProfileImageService.shared.avatarURL,
            let url = URL(string: urlString)
        else {
            return
        }
        let processor = RoundCornerImageProcessor(cornerRadius: Layout.avatarCornerRadius)
        avatarImageView.kf.indicatorType = .activity
        avatarImageView.kf.setImage(
            with: url,
            placeholder: UIImage(named: "avatar"),
            options: [.processor(processor), .cacheSerializer(FormatIndicatedCacheSerializer.png)]
        )
    }

    // MARK: Вёрстка кодом

    private func setupAvatar() {
        avatarImageView.image = UIImage(named: "avatar")
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = Layout.avatarCornerRadius
        avatarImageView.layer.masksToBounds = true
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: Layout.sideInset),
            avatarImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Layout.topInset),
            avatarImageView.widthAnchor.constraint(equalToConstant: Layout.avatarSize),
            avatarImageView.heightAnchor.constraint(equalToConstant: Layout.avatarSize)
        ])
    }

    private func setupLogoutButton() {
        logoutButton.setImage(UIImage(named: "logout_button"), for: .normal)
        logoutButton.tintColor = UIColor(red: 0.96, green: 0.42, blue: 0.42, alpha: 1)
        logoutButton.addTarget(self, action: #selector(didTapLogoutButton), for: .touchUpInside)
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoutButton)
        NSLayoutConstraint.activate([
            logoutButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -Layout.sideInset),
            logoutButton.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            logoutButton.widthAnchor.constraint(equalToConstant: Layout.logoutButtonSize),
            logoutButton.heightAnchor.constraint(equalToConstant: Layout.logoutButtonSize)
        ])
    }

    private func setupNameLabel() {
        nameLabel.text = "Имя Фамилия"
        nameLabel.font = .systemFont(ofSize: 23, weight: .semibold)
        nameLabel.textColor = .white
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor),
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: Layout.spacing)
        ])
    }

    private func setupLoginNameLabel() {
        loginNameLabel.text = "@username"
        loginNameLabel.font = .systemFont(ofSize: 13)
        loginNameLabel.textColor = UIColor(red: 0.682, green: 0.686, blue: 0.706, alpha: 1)
        loginNameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loginNameLabel)
        NSLayoutConstraint.activate([
            loginNameLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            loginNameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: Layout.spacing)
        ])
    }

    private func setupDescriptionLabel() {
        descriptionLabel.font = .systemFont(ofSize: 13)
        descriptionLabel.textColor = .white
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descriptionLabel)
        NSLayoutConstraint.activate([
            descriptionLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -Layout.sideInset),
            descriptionLabel.topAnchor.constraint(equalTo: loginNameLabel.bottomAnchor, constant: Layout.spacing)
        ])
    }

    @objc private func didTapLogoutButton() {
        // выход — реализуем в следующих спринтах
    }
}

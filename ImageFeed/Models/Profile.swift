import Foundation

/// Ответ Unsplash на GET /me
struct ProfileResult: Decodable {
    let username: String
    let firstName: String?
    let lastName: String?
    let bio: String?
}

/// Модель для экрана профиля
struct Profile {
    let username: String
    let name: String
    let loginName: String
    let bio: String?

    init(result: ProfileResult) {
        username = result.username
        name = [result.firstName, result.lastName]
            .compactMap { $0 }
            .joined(separator: " ")
        loginName = "@\(result.username)"
        bio = result.bio
    }
}

/// Ответ Unsplash на GET /users/:username — нас интересует profile_image
struct UserResult: Decodable {
    let profileImage: ProfileImage?

    struct ProfileImage: Decodable {
        let small: String?
        let medium: String?
        let large: String?
    }
}

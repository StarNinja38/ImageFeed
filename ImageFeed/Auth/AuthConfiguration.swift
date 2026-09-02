import Foundation

// MARK: - AuthConfiguration

/// Данные авторизации как объект — вместо разбросанных обращений к `Constants`.
/// Это же позволяет подменить конфигурацию в тестах.
struct AuthConfiguration {
    let accessKey: String
    let secretKey: String
    let redirectURI: String
    let accessScope: String
    let defaultBaseURL: URL?
    let authURLString: String

    static var standard: AuthConfiguration {
        AuthConfiguration(
            accessKey: Constants.accessKey,
            secretKey: Constants.secretKey,
            redirectURI: Constants.redirectURI,
            accessScope: Constants.accessScope,
            defaultBaseURL: URL(string: Constants.defaultBaseURLString),
            authURLString: Constants.unsplashAuthorizeURLString
        )
    }
}

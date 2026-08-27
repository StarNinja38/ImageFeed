import Foundation

/// Ответ Unsplash на POST /oauth/token.
/// CodingKeys не нужны: декодер настроен на `.convertFromSnakeCase`,
/// он сам приводит `access_token` → `accessToken`.
struct OAuthTokenResponseBody: Decodable {
    let accessToken: String
    let tokenType: String
    let scope: String
    let createdAt: Int
}

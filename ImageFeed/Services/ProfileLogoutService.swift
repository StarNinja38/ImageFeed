import Foundation
import WebKit

// MARK: - ProfileLogoutService

final class ProfileLogoutService {

    static let shared = ProfileLogoutService()
    private init() {}

    private let tokenStorage = OAuth2TokenStorage()

    func logout() {
        cleanCookies()
        tokenStorage.clearToken()
        ImagesListService.shared.clean()
    }

    /// Без очистки кук браузер откроется уже авторизованным и не покажет форму логина.
    private func cleanCookies() {
        HTTPCookieStorage.shared.removeCookies(since: .distantPast)

        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(
                    ofTypes: record.dataTypes,
                    for: [record],
                    completionHandler: {}
                )
            }
        }
    }
}

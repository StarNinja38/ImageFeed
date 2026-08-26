import Foundation
import SwiftKeychainWrapper

// MARK: - OAuth2TokenStorage

/// Хранит Bearer Token в Keychain (раньше был UserDefaults — небезопасно для чувствительных данных).
final class OAuth2TokenStorage {

    private enum Keys {
        static let bearerToken = "BearerToken"
    }

    private let keychain = KeychainWrapper.standard

    var token: String? {
        get {
            keychain.string(forKey: Keys.bearerToken)
        }
        set {
            guard let newValue else {
                keychain.removeObject(forKey: Keys.bearerToken)
                return
            }
            let isSuccess = keychain.set(newValue, forKey: Keys.bearerToken)
            if !isSuccess {
                print("[OAuth2TokenStorage.token]: не удалось сохранить токен в Keychain")
            }
        }
    }

    func clearToken() {
        keychain.removeObject(forKey: Keys.bearerToken)
    }
}

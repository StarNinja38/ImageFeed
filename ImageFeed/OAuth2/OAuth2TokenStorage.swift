import Foundation

final class OAuth2TokenStorage {

    private enum Keys: String {
        case bearerToken
    }

    private let storage = UserDefaults.standard

    var token: String? {
        get {
            storage.string(forKey: Keys.bearerToken.rawValue)
        }
        set {
            if let newValue {
                storage.set(newValue, forKey: Keys.bearerToken.rawValue)
            } else {
                storage.removeObject(forKey: Keys.bearerToken.rawValue)
            }
        }
    }
}

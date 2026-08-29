import XCTest

// MARK: - UI-тесты ImageFeed

/// Перед запуском подставь свои данные Unsplash в `Credentials`.
/// Тесты идут в порядке сценария: авторизация → лента → профиль.
final class ImageFeedUITests: XCTestCase {

    private enum Credentials {
        static let email = "<твоя почта Unsplash>"
        static let password = "<твой пароль Unsplash>"
        static let name = "<Имя Фамилия>"
        static let login = "@<логин>"
    }

    private let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    // Сценарий 1: логин через WebView.
    func testAuth() throws {
        app.buttons["Authenticate"].tap()

        let webView = app.webViews["UnsplashWebView"]
        XCTAssertTrue(webView.waitForExistence(timeout: 10))

        let loginTextField = webView.descendants(matching: .textField).element
        XCTAssertTrue(loginTextField.waitForExistence(timeout: 10))
        focus(loginTextField)
        loginTextField.typeText(Credentials.email)
        webView.swipeUp()

        let passwordTextField = webView.descendants(matching: .secureTextField).element
        XCTAssertTrue(passwordTextField.waitForExistence(timeout: 10))
        focus(passwordTextField)
        passwordTextField.typeText(Credentials.password)
        webView.swipeUp()

        webView.buttons["Login"].tap()

        let cell = app.tables.children(matching: .cell).element(boundBy: 0)
        XCTAssertTrue(cell.waitForExistence(timeout: 10))
    }

    // Сценарий 2: лента — скролл, лайк, полноэкранный просмотр.
    func testFeed() throws {
        let tablesQuery = app.tables

        let firstCell = tablesQuery.children(matching: .cell).element(boundBy: 0)
        XCTAssertTrue(firstCell.waitForExistence(timeout: 10))
        firstCell.swipeUp()

        let cellToLike = tablesQuery.children(matching: .cell).element(boundBy: 1)
        XCTAssertTrue(cellToLike.waitForExistence(timeout: 5))

        cellToLike.buttons["like button off"].tap()
        XCTAssertTrue(cellToLike.buttons["like button on"].waitForExistence(timeout: 10))

        cellToLike.buttons["like button on"].tap()
        XCTAssertTrue(cellToLike.buttons["like button off"].waitForExistence(timeout: 10))

        cellToLike.tap()

        let image = app.scrollViews.images.element(boundBy: 0)
        XCTAssertTrue(image.waitForExistence(timeout: 10))
        image.pinch(withScale: 3, velocity: 1)
        image.pinch(withScale: 0.5, velocity: -1)

        app.buttons["BackButton"].tap()
        XCTAssertTrue(firstCell.waitForExistence(timeout: 10))
    }

    // Сценарий 3: профиль — данные на месте, выход работает.
    func testProfile() throws {
        XCTAssertTrue(app.tables.children(matching: .cell).element(boundBy: 0).waitForExistence(timeout: 10))

        app.tabBars.buttons.element(boundBy: 1).tap()

        XCTAssertTrue(app.staticTexts[Credentials.name].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts[Credentials.login].exists)

        app.buttons["logout button"].tap()

        // Идентификатор "Bye bye!" задан у `alert.view`, но всплывает он не на всех
        // версиях iOS, поэтому берём алерт по идентификатору с откатом на первый видимый.
        let namedAlert = app.alerts["Bye bye!"]
        let alert = namedAlert.waitForExistence(timeout: 5) ? namedAlert : app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["Да"].tap()

        XCTAssertTrue(app.buttons["Authenticate"].waitForExistence(timeout: 10))
    }

    /// WebKit-поля внутри `WKWebView` часто не получают фокус от обычного `tap()`:
    /// клавиатура может быть уже поднята предыдущим полем, и `typeText` падает с
    /// «Neither element nor any descendant has keyboard focus».
    /// Поэтому тапаем по координате поля и проверяем фокус именно у него.
    private func focus(_ element: XCUIElement, attempts: Int = 5) {
        for _ in 0..<attempts {
            if element.hasKeyboardFocus { return }
            element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            _ = app.keyboards.element.waitForExistence(timeout: 2)
        }
        XCTAssertTrue(element.hasKeyboardFocus, "Не удалось поставить курсор в поле")
    }
}

private extension XCUIElement {
    /// У XCUIElement нет публичного флага фокуса — берём его через KVC.
    var hasKeyboardFocus: Bool {
        (value(forKey: "hasKeyboardFocus") as? Bool) ?? false
    }
}

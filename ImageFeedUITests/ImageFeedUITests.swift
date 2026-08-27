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
        loginTextField.tap()
        loginTextField.typeText(Credentials.email)
        webView.swipeUp()

        let passwordTextField = webView.descendants(matching: .secureTextField).element
        XCTAssertTrue(passwordTextField.waitForExistence(timeout: 10))
        passwordTextField.tap()
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
        app.alerts["Bye bye!"].scrollViews.otherElements.buttons["Да"].tap()

        XCTAssertTrue(app.buttons["Authenticate"].waitForExistence(timeout: 10))
    }
}

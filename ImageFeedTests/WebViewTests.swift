import XCTest
@testable import ImageFeed

final class WebViewTests: XCTestCase {

    // Given-When-Then: контроллер при загрузке сообщает об этом презентеру.
    func testViewControllerCallsViewDidLoad() {
        // Given
        let viewController = WebViewViewController()
        let presenter = WebViewPresenterSpy()
        viewController.presenter = presenter
        presenter.view = viewController

        // When
        _ = viewController.view

        // Then
        XCTAssertTrue(presenter.viewDidLoadCalled)
    }

    // Презентер на старте просит вью загрузить запрос авторизации.
    func testPresenterCallsLoadRequest() {
        // Given
        let viewController = WebViewViewControllerSpy()
        let presenter = WebViewPresenter(authHelper: AuthHelper())
        viewController.presenter = presenter
        presenter.view = viewController

        // When
        presenter.viewDidLoad()

        // Then
        XCTAssertTrue(viewController.loadRequestCalled)
    }

    // Прогресс 0.6 — полоску прятать рано.
    func testProgressVisibleWhenLessThenOne() {
        // Given
        let presenter = WebViewPresenter(authHelper: AuthHelper())
        let progress: Float = 0.6

        // When
        let shouldHideProgress = presenter.shouldHideProgress(for: progress)

        // Then
        XCTAssertFalse(shouldHideProgress)
    }

    // Прогресс 1.0 — полоска скрывается.
    func testProgressHiddenWhenOne() {
        // Given
        let presenter = WebViewPresenter(authHelper: AuthHelper())
        let progress: Float = 1.0

        // When
        let shouldHideProgress = presenter.shouldHideProgress(for: progress)

        // Then
        XCTAssertTrue(shouldHideProgress)
    }

    // authURL содержит адрес авторизации и все обязательные параметры.
    func testAuthHelperAuthURL() throws {
        // Given
        let configuration = AuthConfiguration.standard
        let authHelper = AuthHelper(configuration: configuration)

        // When
        let url = try XCTUnwrap(authHelper.authURL())

        // Then
        let urlString = url.absoluteString
        XCTAssertTrue(urlString.contains(configuration.authURLString))
        XCTAssertTrue(urlString.contains(configuration.accessKey))
        XCTAssertTrue(urlString.contains(configuration.redirectURI))
        XCTAssertTrue(urlString.contains("code"))
        XCTAssertTrue(urlString.contains(configuration.accessScope))
    }

    // Код достаётся из redirect-URL нужного вида.
    func testCodeFromURL() {
        // Given
        var urlComponents = URLComponents(string: "https://unsplash.com/oauth/authorize/native")
        urlComponents?.queryItems = [URLQueryItem(name: "code", value: "test code")]
        guard let url = urlComponents?.url else {
            return XCTFail("не удалось собрать тестовый URL")
        }
        let authHelper = AuthHelper()

        // When
        let code = authHelper.code(from: url)

        // Then
        XCTAssertEqual(code, "test code")
    }

    // Чужой путь — кода нет.
    func testCodeFromWrongURLReturnsNil() {
        // Given
        guard let url = URL(string: "https://unsplash.com/other/path?code=test") else {
            return XCTFail("не удалось собрать тестовый URL")
        }
        let authHelper = AuthHelper()

        // When
        let code = authHelper.code(from: url)

        // Then
        XCTAssertNil(code)
    }
}

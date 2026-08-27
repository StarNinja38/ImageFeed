import XCTest
@testable import ImageFeed

final class ImagesListTests: XCTestCase {

    // Контроллер при загрузке дёргает презентер.
    func testViewControllerCallsViewDidLoad() {
        // Given
        let viewController = ImagesListViewController()
        let presenter = ImagesListPresenterSpy()
        viewController.presenter = presenter
        presenter.view = viewController

        // When
        _ = viewController.view

        // Then
        XCTAssertTrue(presenter.viewDidLoadCalled)
    }

    // На старте презентер просит первую страницу.
    func testViewDidLoadFetchesFirstPage() {
        // Given
        let service = ImagesListServiceFake()
        let presenter = ImagesListPresenter(imagesListService: service)
        presenter.view = ImagesListViewControllerSpy()

        // When
        presenter.viewDidLoad()

        // Then
        XCTAssertEqual(service.fetchPhotosNextPageCallCount, 1)
    }

    // Долистали до последней ячейки — грузим следующую страницу.
    func testFetchNextPageOnLastCell() {
        // Given
        let photos = [TestData.makePhoto(id: "1"), TestData.makePhoto(id: "2")]
        let service = ImagesListServiceFake(photos: photos)
        let presenter = ImagesListPresenter(imagesListService: service)
        let view = ImagesListViewControllerSpy()
        presenter.view = view
        presenter.viewDidLoad()
        service.simulateNewPage([])

        // When
        presenter.fetchPhotosNextPageIfNeeded(at: photos.count - 1)

        // Then — 1 вызов из viewDidLoad + 1 из пагинации
        XCTAssertEqual(service.fetchPhotosNextPageCallCount, 2)
    }

    // Ячейка не последняя — лишнего запроса нет.
    func testNoFetchOnMiddleCell() {
        // Given
        let photos = [TestData.makePhoto(id: "1"), TestData.makePhoto(id: "2")]
        let service = ImagesListServiceFake(photos: photos)
        let presenter = ImagesListPresenter(imagesListService: service)
        presenter.view = ImagesListViewControllerSpy()
        presenter.viewDidLoad()
        service.simulateNewPage([])

        // When
        presenter.fetchPhotosNextPageIfNeeded(at: 0)

        // Then — только вызов из viewDidLoad
        XCTAssertEqual(service.fetchPhotosNextPageCallCount, 1)
    }

    // Пришла страница — вью получает старое и новое количество.
    func testUpdateTableViewAnimatedOnNewPage() {
        // Given
        let service = ImagesListServiceFake()
        let presenter = ImagesListPresenter(imagesListService: service)
        let view = ImagesListViewControllerSpy()
        presenter.view = view
        presenter.viewDidLoad()

        // When
        service.simulateNewPage([TestData.makePhoto(id: "1"), TestData.makePhoto(id: "2")])

        // Then
        XCTAssertTrue(view.updateTableViewCalled)
        XCTAssertEqual(view.lastOldCount, 0)
        XCTAssertEqual(view.lastNewCount, 2)
        XCTAssertEqual(presenter.photos.count, 2)
    }

    // Высота считается по пропорциям фото: 500×250 при ширине 375
    // → (375 − 32) / 500 × 250 + 8.
    func testCellHeightKeepsPhotoProportions() {
        // Given
        let service = ImagesListServiceFake(photos: [TestData.makePhoto(id: "1", width: 500, height: 250)])
        let presenter = ImagesListPresenter(imagesListService: service)
        presenter.view = ImagesListViewControllerSpy()
        presenter.viewDidLoad()
        service.simulateNewPage([])

        // When
        let height = presenter.cellHeight(at: 0, tableWidth: 375)

        // Then
        let expected = (375 - 32) / 500.0 * 250.0 + 8
        XCTAssertEqual(height, CGFloat(expected), accuracy: 0.01)
    }

    // Индекс за пределами массива — падать нельзя, отдаём дефолт.
    func testCellHeightForMissingIndex() {
        // Given
        let presenter = ImagesListPresenter(imagesListService: ImagesListServiceFake())
        presenter.view = ImagesListViewControllerSpy()

        // When
        let height = presenter.cellHeight(at: 42, tableWidth: 375)

        // Then
        XCTAssertEqual(height, 200)
    }

    // Тап по фото — вью получает URL большой картинки.
    func testDidSelectPhotoPassesLargeURL() {
        // Given
        let service = ImagesListServiceFake()
        let presenter = ImagesListPresenter(imagesListService: service)
        let view = ImagesListViewControllerSpy()
        presenter.view = view
        presenter.viewDidLoad()
        service.simulateNewPage([TestData.makePhoto(id: "42")])

        // When
        presenter.didSelectPhoto(at: 0)

        // Then
        XCTAssertEqual(view.lastSingleImageURL?.absoluteString, "https://example.com/42-large.jpg")
    }

    // Успешный лайк — вью узнаёт новое состояние сердечка.
    func testDidTapLikeUpdatesCell() {
        // Given
        let service = ImagesListServiceFake()
        let presenter = ImagesListPresenter(imagesListService: service)
        let view = ImagesListViewControllerSpy()
        presenter.view = view
        presenter.viewDidLoad()
        service.simulateNewPage([TestData.makePhoto(id: "1", isLiked: false)])

        // When
        presenter.didTapLike(at: IndexPath(row: 0, section: 0))

        // Then
        XCTAssertEqual(service.lastChangeLikePhotoId, "1")
        XCTAssertEqual(service.lastChangeLikeIsLike, true)
        XCTAssertEqual(view.lastIsLiked, true)
        XCTAssertEqual(view.lastLikedIndexPath, IndexPath(row: 0, section: 0))
    }

    // Сеть отвалилась — показываем алерт.
    func testDidTapLikeShowsAlertOnFailure() {
        // Given
        let service = ImagesListServiceFake()
        service.changeLikeResult = .failure(NetworkError.urlRequestError(URLError(.notConnectedToInternet)))
        let presenter = ImagesListPresenter(imagesListService: service)
        let view = ImagesListViewControllerSpy()
        presenter.view = view
        presenter.viewDidLoad()
        service.simulateNewPage([TestData.makePhoto(id: "1")])

        // When
        presenter.didTapLike(at: IndexPath(row: 0, section: 0))

        // Then
        XCTAssertTrue(view.showLikeErrorAlertCalled)
    }
}

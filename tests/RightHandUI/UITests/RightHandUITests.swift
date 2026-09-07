import XCTest

final class RightHandUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    func testBrowserControlsStayInRightThumbAreaAndDispatchActions() {
        let app = XCUIApplication()
        app.launchArguments = ["toolbar"]
        app.launch()
        for (identifier, title) in [("back", "Back"), ("forward", "Forward"), ("share", "Share"), ("library", "Library"), ("download", "Downloads"), ("tabOverview", "Tabs")] {
            let button = app.buttons["browser.\(identifier)"]
            XCTAssertTrue(button.waitForExistence(timeout: 5))
            assertReachable(button, in: app)
            button.tap()
            XCTAssertEqual(app.staticTexts["result"].label, title)
        }
        attachScreenshot("browser-portrait")
        XCUIDevice.shared.orientation = .landscapeLeft
        for identifier in ["back", "forward", "share", "library", "download", "tabOverview"] {
            assertReachable(app.buttons["browser.\(identifier)"], in: app)
        }
        attachScreenshot("browser-landscape")
    }

    func testNavigationMenusBackAndLiveSaveValidationWithKeyboard() {
        let app = XCUIApplication()
        app.launchArguments = ["navigation"]
        app.launch()
        XCTAssertTrue(app.buttons["edit"].waitForExistence(timeout: 5))
        assertReachable(app.buttons["edit"], in: app)
        app.buttons["sections"].tap()
        app.buttons["Downloads"].tap()
        XCTAssertTrue(app.staticTexts["Downloads"].firstMatch.waitForExistence(timeout: 3))
        attachScreenshot("settings")
        app.buttons["edit"].tap()
        let save = app.buttons["save"]
        XCTAssertTrue(save.waitForExistence(timeout: 3))
        XCTAssertFalse(save.isEnabled)
        assertReachable(app.buttons["navigation.back"], in: app)
        let field = app.textFields["name"]
        field.tap()
        field.typeText("Right hand")
        XCTAssertTrue(save.isEnabled)
        XCTAssertTrue(save.isHittable)
        XCTAssertLessThanOrEqual(save.frame.maxY, app.keyboards.firstMatch.frame.minY + 1)
        attachScreenshot("editor-keyboard")
        save.tap()
        XCTAssertTrue(app.staticTexts["Saved"].firstMatch.waitForExistence(timeout: 3))
        app.buttons["navigation.back"].tap()
        XCTAssertTrue(app.buttons["edit"].waitForExistence(timeout: 3))
    }

    func testDarkAppearanceKeepsControlsReachable() {
        let app = XCUIApplication()
        app.launchArguments = ["toolbar", "dark"]
        app.launch()
        XCTAssertTrue(app.buttons["browser.back"].waitForExistence(timeout: 5))
        assertReachable(app.buttons["browser.back"], in: app)
        attachScreenshot("browser-dark")
    }

    private func assertReachable(_ button: XCUIElement, in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let frame = button.frame
        let screen = app.windows.firstMatch.frame
        XCTAssertTrue(button.isHittable, file: file, line: line)
        XCTAssertGreaterThanOrEqual(frame.width, 44, file: file, line: line)
        XCTAssertGreaterThanOrEqual(frame.height, 44, file: file, line: line)
        XCTAssertGreaterThanOrEqual(frame.minX, screen.maxX - 280, file: file, line: line)
        XCTAssertGreaterThanOrEqual(frame.minY, screen.maxY - 250, file: file, line: line)
        XCTAssertLessThanOrEqual(frame.maxX, screen.maxX, file: file, line: line)
        XCTAssertLessThanOrEqual(frame.maxY, screen.maxY, file: file, line: line)
    }

    private func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

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
            assertReachable(button, in: app, rightReach: 360)
            button.tap()
            XCTAssertEqual(app.staticTexts["result"].label, title)
        }
        assertToolbarSingleRow(in: app)
        attachScreenshot("browser-portrait")
        XCUIDevice.shared.orientation = .landscapeLeft
        let rotationFinished = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let screen = app.windows.firstMatch.frame
            return screen.width > screen.height && app.buttons["browser.back"].isHittable
        }, object: app)
        XCTAssertEqual(XCTWaiter.wait(for: [rotationFinished], timeout: 10), .completed)
        for identifier in ["back", "forward", "share", "library", "download", "tabOverview"] {
            assertReachable(app.buttons["browser.\(identifier)"], in: app, rightReach: 360)
        }
        assertToolbarSingleRow(in: app)
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
        // UIKit's keyboard frame includes the input assistant; XCTest may
        // expose only the key grid. Neither the dock nor its controls may overlap it.
        XCTAssertLessThanOrEqual(app.otherElements["navigation.bottomDock"].frame.maxY,
                                app.keyboards.firstMatch.frame.minY + 1)
        attachScreenshot("editor-keyboard")
        save.tap()
        XCTAssertTrue(app.staticTexts["Saved"].firstMatch.waitForExistence(timeout: 3))
        let keyboardDismissed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            abs(app.otherElements["navigation.bottomDock"].frame.maxY - app.windows.firstMatch.frame.maxY) <= 1
        }, object: app)
        XCTAssertEqual(XCTWaiter.wait(for: [keyboardDismissed], timeout: 10), .completed)
        app.buttons["navigation.back"].tap()
        XCTAssertTrue(app.buttons["edit"].waitForExistence(timeout: 3))
    }

    func testDarkAppearanceKeepsControlsReachable() {
        let app = XCUIApplication()
        app.launchArguments = ["toolbar", "dark"]
        app.launch()
        XCTAssertTrue(app.buttons["browser.back"].waitForExistence(timeout: 5))
        assertReachable(app.buttons["browser.back"], in: app, rightReach: 360)
        attachScreenshot("browser-dark")
    }

    func testLibraryHasOneTitleAndUnobstructedList() {
        let app = XCUIApplication()
        app.launchArguments = ["library"]
        app.launch()
        let close = app.buttons["library.close"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label == %@", "Settings")).count, 1)
        assertReachable(close, in: app)
        assertReachable(app.buttons["library.sections"], in: app)
        let firstRow = app.staticTexts["Appearance"]
        XCTAssertTrue(firstRow.isHittable)
        XCTAssertLessThan(firstRow.frame.maxY, app.windows.firstMatch.frame.midY)
        let lastRow = app.staticTexts["Setting 12"]
        if !lastRow.isHittable { app.tables.firstMatch.swipeUp() }
        XCTAssertTrue(lastRow.isHittable)
        XCTAssertLessThanOrEqual(lastRow.frame.maxY, app.staticTexts["Settings"].frame.minY)
        assertDockCoversBottom(in: app)
        XCTAssertEqual(app.staticTexts["Settings"].frame.midY, close.frame.midY, accuracy: 1)
        attachScreenshot("library-clean-layout")
        app.buttons["library.sections"].tap()
        let settingsMenuItem = app.buttons["Settings"]
        settingsMenuItem.tap()
        let menuDismissed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: settingsMenuItem)
        XCTAssertEqual(XCTWaiter.wait(for: [menuDismissed], timeout: 5), .completed)
        close.tap()
        XCTAssertTrue(app.staticTexts["Closed"].waitForExistence(timeout: 3))
    }

    func testCompactBrowserToolbarUsesOneReachableRow() {
        let app = XCUIApplication()
        app.launchArguments = ["toolbar", "compact"]
        app.launch()
        XCTAssertTrue(app.buttons["browser.back"].waitForExistence(timeout: 5))
        assertToolbarSingleRow(in: app)
        attachScreenshot("browser-compact-single-row")
    }

    func testSettingsSheetCoversBottomWhileScrollingInBothAppearances() {
        for appearance in ["light", "dark"] {
            let app = XCUIApplication()
            app.launchArguments = ["library-sheet", "long-list", appearance]
            app.launch()
            let close = app.buttons["library.close"]
            XCTAssertTrue(close.waitForExistence(timeout: 10))
            assertDockCoversBottom(in: app)
            let table = app.tables.firstMatch
            table.swipeUp()
            assertDockCoversBottom(in: app)
            attachScreenshot("settings-sheet-\(appearance)-scroll")
            let lastRow = app.staticTexts["Setting 40"]
            for _ in 0..<8 {
                if lastRow.isHittable && lastRow.frame.maxY <= app.otherElements["navigation.bottomDock"].frame.minY { break }
                table.swipeUp()
            }
            XCTAssertTrue(lastRow.isHittable)
            XCTAssertLessThanOrEqual(lastRow.frame.maxY, app.otherElements["navigation.bottomDock"].frame.minY)
            assertDockCoversBottom(in: app)
            attachScreenshot("settings-sheet-\(appearance)-bottom")
            close.tap()
            XCTAssertTrue(app.staticTexts["sheet.closed"].waitForExistence(timeout: 5))
            app.terminate()
        }
    }

    private func assertDockCoversBottom(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let dock = app.otherElements["navigation.bottomDock"].frame
        let window = app.windows.firstMatch.frame
        XCTAssertEqual(dock.maxY, window.maxY, accuracy: 1, file: file, line: line)
        XCTAssertEqual(dock.minX, window.minX, accuracy: 1, file: file, line: line)
        XCTAssertEqual(dock.width, window.width, accuracy: 1, file: file, line: line)
        let close = app.buttons["library.close"]
        assertReachable(close, in: app, file: file, line: line)
        XCTAssertEqual(close.frame.height, 48, accuracy: 1, file: file, line: line)
        XCTAssertEqual(close.frame.midY, app.buttons["library.sections"].frame.midY, accuracy: 1, file: file, line: line)
        XCTAssertLessThan(close.frame.maxY, dock.maxY, file: file, line: line)
    }

    private func assertToolbarSingleRow(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let back = app.buttons["browser.back"].frame
        for identifier in ["share", "download", "forward", "library", "tabOverview", "back"] {
            let button = app.buttons["browser.\(identifier)"]
            assertReachable(button, in: app, rightReach: 360, file: file, line: line)
            XCTAssertEqual(button.frame.midY, back.midY, accuracy: 1, file: file, line: line)
            XCTAssertLessThanOrEqual(button.frame.height, 48, file: file, line: line)
        }
        let screen = app.windows.firstMatch.frame
        if screen.height > screen.width {
            XCTAssertEqual(back.maxX, screen.maxX - 12, accuracy: 1, file: file, line: line)
        }
    }

    private func assertReachable(_ button: XCUIElement, in app: XCUIApplication, rightReach: CGFloat = 280, file: StaticString = #filePath, line: UInt = #line) {
        let frame = button.frame
        let screen = app.windows.firstMatch.frame
        XCTAssertTrue(button.isHittable, file: file, line: line)
        XCTAssertGreaterThanOrEqual(frame.width, 44, file: file, line: line)
        XCTAssertGreaterThanOrEqual(frame.height, 44, file: file, line: line)
        XCTAssertGreaterThanOrEqual(frame.minX, screen.maxX - rightReach, file: file, line: line)
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

import XCTest
final class NavigationTests: XCTestCase {
    func testWelcomeAndTabNavigation() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-reset-welcome"]
        app.launch()
        app.buttons["explore-demo"].tap()
        XCTAssertTrue(app.staticTexts["demo-notice"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5), app.debugDescription)
        app.tabBars.buttons["Portfolio"].tap()
        XCTAssertTrue(app.staticTexts["No portfolio yet"].exists)
        app.tabBars.buttons["Documents"].tap()
        XCTAssertTrue(app.staticTexts["No documents yet"].exists)
        app.tabBars.buttons["Account"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label ==[c] %@", "Your account")).firstMatch.waitForExistence(timeout: 5))
    }
    func testAuthenticationEntryShowsRealProviderOptionsWithoutPretendingToSignIn() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-reset-welcome"]
        app.launch()
        app.buttons["open-auth"].tap()
        XCTAssertTrue(app.buttons["sign-in-apple"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Continue with Google"].exists)
        app.buttons["Continue with Email"].tap()
        XCTAssertTrue(app.textFields["auth-email"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "not configured yet")).firstMatch.exists)
        XCTAssertFalse(app.buttons["Sign In"].isEnabled)
        app.buttons["close-auth"].tap()
    }
    func testDiscoverLoadsAPIPropertyAndOpensDetails() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-skip-welcome"]
        app.launch()
        let property = app.staticTexts["Magnolia House"]
        XCTAssertTrue(property.waitForExistence(timeout: 20), "Seeded property should load from the local API")
        property.tap()
        XCTAssertTrue(app.navigationBars["Property details"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label ==[c] %@", "Illustrative property facts")).firstMatch.waitForExistence(timeout: 5))
        app.navigationBars.buttons["Discover"].tap()
        XCTAssertTrue(property.waitForExistence(timeout: 5))
    }
}

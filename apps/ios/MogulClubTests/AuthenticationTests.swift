import XCTest
@testable import Mogul_Club

final class AuthenticationTests: XCTestCase {
    func testEmailValidationAcceptsNormalAndPlusAddressing() {
        XCTAssertTrue(AuthValidation.email("member@example.com"))
        XCTAssertTrue(AuthValidation.email("mogul+demo@sub.example.org"))
        XCTAssertFalse(AuthValidation.email("name@localhost"))
        XCTAssertFalse(AuthValidation.email("not-an-email"))
        XCTAssertFalse(AuthValidation.email("name @example.com"))
    }
    func testPasswordMinimum() {
        XCTAssertFalse(AuthValidation.password("1234567"))
        XCTAssertTrue(AuthValidation.password("12345678"))
        XCTAssertTrue(AuthValidation.password("correct horse battery staple"))
    }
    @MainActor
    func testMissingFirebaseConfigurationNeverCreatesFakeSession() {
        guard !AuthConfiguration.isReady else { return }
        let manager = AuthManager()
        XCTAssertEqual(manager.state, .signedOut)
        XCTAssertNil(manager.currentUser)
        XCTAssertNotNil(manager.setupMessage)
    }
}

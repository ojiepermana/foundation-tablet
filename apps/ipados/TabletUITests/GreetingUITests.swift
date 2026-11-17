import XCTest

final class GreetingUITests: XCTestCase {
    @MainActor private var app: XCUIApplication!

    @MainActor
    func testGreetingValuesAndEditingPreservesLastResult() {
        launchApp()
        defer { app.terminate() }
        XCTAssertEqual(nameField.value as? String, "Ayu")
        XCTAssertTrue(app.staticTexts["Salam Rust"].exists)
        XCTAssertTrue(app.staticTexts["Masukkan nama, lalu tekan Sapa."].exists)
        XCTAssertTrue(!result.exists || result.label.isEmpty)

        submit.tap()
        assertGreeting("Hello, Ayu!")

        replaceName("Bima")
        assertGreeting("Hello, Ayu!")
        submit.tap()
        assertGreeting("Hello, Bima!")

        replaceName("")
        assertGreeting("Hello, Bima!")
        submit.tap()
        assertGreeting("Hello, !")

        replaceName("Zoë 東京")
        assertGreeting("Hello, !")
        submit.tap()
        assertGreeting("Hello, Zoë 東京!")
    }

    @MainActor
    func testKeyboardSubmitAndRotationPreservePresentationState() {
        launchApp()
        defer {
            XCUIDevice.shared.orientation = .portrait
            app.terminate()
        }
        replaceName("Bima")
        nameField.typeText("\n")
        assertGreeting("Hello, Bima!")

        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        XCTAssertEqual(nameField.value as? String, "Bima")
        assertGreeting("Hello, Bima!")
        XCTAssertTrue(submit.isHittable)
        submit.tap()
        assertGreeting("Hello, Bima!")

        XCUIDevice.shared.orientation = .portrait
        XCTAssertEqual(nameField.value as? String, "Bima")
        assertGreeting("Hello, Bima!")
    }

    @MainActor private var nameField: XCUIElement { app.textFields["greeting.name"] }
    @MainActor private var submit: XCUIElement { app.buttons["greeting.submit"] }
    @MainActor private var result: XCUIElement { app.staticTexts["greeting.result"] }

    @MainActor
    private func launchApp() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        app.launch()
        XCTAssertTrue(nameField.waitForExistence(timeout: 10))
    }

    @MainActor
    private func replaceName(_ text: String) {
        nameField.tap()
        let current = nameField.value as? String ?? ""
        // A TextField exposes its placeholder as value when empty.
        let count = current == "Nama" ? 0 : current.count
        nameField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: count) + text)
    }

    @MainActor
    private func assertGreeting(
        _ expected: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let matches = NSPredicate(format: "label == %@", expected)
        expectation(for: matches, evaluatedWith: result)
        waitForExpectations(timeout: 5)
        XCTAssertEqual(result.label, expected, file: file, line: line)
    }
}

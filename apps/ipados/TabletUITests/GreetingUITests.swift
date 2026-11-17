import XCTest

final class GreetingUITests: XCTestCase {
    @MainActor private var app: XCUIApplication!

    @MainActor
    func testGreetingValuesAndEditingPreservesLastResult() {
        launchApp()
        defer { app.terminate() }
        XCTAssertEqual(nameField.value as? String, "Ayu")
        XCTAssertTrue(app.staticTexts["Salam Rust"].firstMatch.exists)
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

    // Covers spec 0004 AC-1, AC-2, AC-4: state survives destination and layout changes.
    @MainActor
    func testNavigationRotationAndBackgroundPreserveGreeting() {
        launchApp()
        defer {
            XCUIDevice.shared.orientation = .portrait
            app.terminate()
        }
        submit.tap()
        assertGreeting("Hello, Ayu!")
        selectDestination("foundation")
        XCTAssertTrue(app.staticTexts["Satu inti Rust, dua antarmuka native."].waitForExistence(timeout: 5))
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.staticTexts["Rust melalui UniFFI."].waitForExistence(timeout: 5))
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.staticTexts["Rust melalui UniFFI."].waitForExistence(timeout: 5))
        selectDestination("greeting")
        XCTAssertEqual(nameField.value as? String, "Ayu")
        assertGreeting("Hello, Ayu!")
        XCUIDevice.shared.orientation = .portrait
        assertGreeting("Hello, Ayu!")
    }

    // Covers spec 0004 AC-5: actual background, process stop and scene restoration.
    @MainActor
    func testSceneRestoresDestinationAfterProcessRelaunch() {
        launchApp()
        defer { app.terminate() }
        submit.tap()
        assertGreeting("Hello, Ayu!")
        selectDestination("foundation")
        XCTAssertTrue(app.staticTexts["Rust melalui UniFFI."].waitForExistence(timeout: 5))
        // This regression runs in a full-width single scene. Compact restoration
        // has its own environment-dependent test below.
        XCUIDevice.shared.press(.home)
        XCTAssertTrue(app.wait(for: .runningBackground, timeout: 10))
        app.terminate()
        app.launchArguments = []
        app.launch()
        XCTAssertTrue(app.staticTexts["Rust melalui UniFFI."].waitForExistence(timeout: 10))
        selectDestination("greeting")
        XCTAssertEqual(nameField.value as? String, "Ayu")
        XCTAssertTrue(!result.exists || result.label.isEmpty)
    }

    // Covers spec 0004 AC-3, AC-5. Run on an actual narrow window configured
    // with the iPad system Move & Resize menu, never a size-class override.
    @MainActor
    func testCompactBackAndBothRestoredPanels() throws {
        launchApp()
        defer { app.terminate() }
        guard app.windows.firstMatch.frame.width < 600 else {
            throw XCTSkip("Requires an actual narrow iPad window. Use system Move & Resize, Left Half.")
        }
        selectDestination("foundation")
        XCTAssertTrue(app.staticTexts["Rust melalui UniFFI."].waitForExistence(timeout: 5))
        relaunchSavedScene()
        XCTAssertTrue(app.staticTexts["Rust melalui UniFFI."].waitForExistence(timeout: 10))
        let back = app.buttons["BackButton"]
        XCTAssertTrue(back.waitForExistence(timeout: 5))
        back.tap()
        XCTAssertTrue(app.buttons["navigation.foundation"].isHittable)
        relaunchSavedScene()
        XCTAssertTrue(app.buttons["navigation.foundation"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["navigation.foundation"].isHittable)
        XCTAssertFalse(app.staticTexts["Rust melalui UniFFI."].isHittable)
        // Reopening the same selected row must still push content.
        app.buttons["navigation.foundation"].tap()
        XCTAssertTrue(app.staticTexts["Rust melalui UniFFI."].waitForExistence(timeout: 5))
    }

    @MainActor
    private func relaunchSavedScene() {
        // Cover every app scene with a full-screen system app. In Windowed Apps,
        // Home can leave a scene visible, which is not a background checkpoint.
        XCUIApplication(bundleIdentifier: "com.apple.Preferences").activate()
        XCTAssertTrue(app.wait(for: .runningBackground, timeout: 10))
        app.terminate()
        app.launchArguments = []
        app.launch()
    }

    @MainActor
    private func selectDestination(_ destination: String) {
        let link = app.buttons["navigation.\(destination)"]
        if !link.isHittable {
            let back = app.buttons["BackButton"]
            if back.exists {
                back.tap()
            } else {
                let toggle = app.buttons["Show Sidebar"]
                XCTAssertTrue(toggle.waitForExistence(timeout: 5), app.debugDescription)
                toggle.tap()
            }
        }
        XCTAssertTrue(link.waitForExistence(timeout: 5), app.debugDescription)
        link.tap()
    }

    @MainActor private var nameField: XCUIElement { app.textFields["greeting.name"] }
    @MainActor private var submit: XCUIElement { app.buttons["greeting.submit"] }
    @MainActor private var result: XCUIElement { app.staticTexts["greeting.result"] }

    @MainActor
    private func launchApp() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        app.launchArguments = ["--fresh-navigation"]
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

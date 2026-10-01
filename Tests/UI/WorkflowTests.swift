import XCTest

@MainActor final class WorkflowTests: XCTestCase {
  override func setUpWithError() throws { continueAfterFailure = false }
  func testReviewedCasePersists() {
    let app = XCUIApplication()
    app.launchEnvironment["DESK_TEST_RUN"] = UUID().uuidString
    app.launch()
    if app.navigationBars.buttons["Service Desk"].exists {
      app.navigationBars.buttons["Service Desk"].tap()
    }
    XCTAssertTrue(app.buttons["Knowledge guides"].waitForExistence(timeout: 10))
    app.buttons["Knowledge guides"].tap()
    app.buttons["Load sample guides"].tap()
    if app.navigationBars.buttons["Service Desk"].exists {
      app.navigationBars.buttons["Service Desk"].tap()
    }
    app.buttons["New case"].tap()
    let issue = app.textFields["desk-issue"]
    XCTAssertTrue(issue.waitForExistence(timeout: 10), app.debugDescription)
    issue.tap()
    issue.typeText("Printer queue is paused")
    app.swipeUp()
    XCTAssertTrue(app.buttons["Review ticket"].waitForExistence(timeout: 5))
    app.buttons["Review ticket"].tap()
    XCTAssertTrue(app.buttons["Save ticket"].waitForExistence(timeout: 5))
    let notes = app.textFields["ticket-notes"]
    XCTAssertTrue(notes.waitForExistence(timeout: 5), app.debugDescription)
    notes.tap()
    notes.typeText(
      "Customer reports a paused queue. Confirm network and selected printer before escalation.")
    app.buttons["Save ticket"].tap()
    app.terminate()
    app.launch()
    if app.navigationBars.buttons["Service Desk"].exists {
      app.navigationBars.buttons["Service Desk"].tap()
    }
    XCTAssertTrue(
      app.buttons["Printer queue is paused, Open · Normal"].waitForExistence(timeout: 10),
      app.debugDescription)
    app.buttons["Printer queue is paused, Open · Normal"].tap()
    XCTAssertTrue(app.buttons["Edit ticket"].waitForExistence(timeout: 5), app.debugDescription)
    let screenshot = XCTAttachment(screenshot: app.screenshot())
    screenshot.name = "reviewed-case"
    screenshot.lifetime = .keepAlways
    add(screenshot)
    app.terminate()
  }
}

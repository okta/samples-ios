/*
 * Copyright 2019 Okta, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import XCTest

class OktaBrowserSignInUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment = ProcessInfo.processInfo.environment
        app.launch()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testLoginSuccess() {
        let app = XCUIApplication()
        let env = ProcessInfo.processInfo.environment
        guard let login = env["LOGIN"], let pass = env["PASS"], let firstName = env["FIRST_NAME"] else {
            XCTFail("Environment variables LOGIN, PASS, FIRST_NAME not set")
            return
        }
        
        app.buttons["Sign In"].tap()
        passSystemAlert(button: "Continue")
        
        let webViewsQuery = app.webViews
        XCTAssertTrue(webViewsQuery.textFields["Username"].waitForExistence(timeout: 60))
        webViewsQuery.textFields["Username"].tap()
        webViewsQuery.textFields["Username"].typeText(login)
        if webViewsQuery.buttons["Next"].exists {
            webViewsQuery.buttons["Next"].tap()
            XCTAssertTrue(webViewsQuery.secureTextFields["Password"].waitForExistence(timeout: 60))
        }
        webViewsQuery.secureTextFields["Password"].tap()
        sleep(1)
        webViewsQuery.secureTextFields["Password"].typeText(pass)
        webViewsQuery.buttons["Sign In"].tap()

        XCTAssertTrue(app.staticTexts["Welcome, \(firstName)"].waitForExistence(timeout: 30))
        
        app.buttons["Sign Out"].tap()
        
        passSystemAlert(button: "Continue")
        
        XCTAssertTrue(XCUIApplication().staticTexts["Have an account?"].waitForExistence(timeout: 30))
    }
    
    func testLoginFailure() {
        let app = XCUIApplication()
        let login = UUID().uuidString
        let pass = UUID().uuidString
        
        app.buttons["Sign In"].tap()
        passSystemAlert(button: "Continue")
        
        let webViewsQuery = app.webViews
        XCTAssertTrue(webViewsQuery.textFields["Username"].waitForExistence(timeout: 60))
        webViewsQuery.textFields["Username"].tap()
        webViewsQuery.textFields["Username"].typeText(login)
        if webViewsQuery.buttons["Next"].exists {
            webViewsQuery.buttons["Next"].tap()
            XCTAssertTrue(webViewsQuery.secureTextFields["Password"].waitForExistence(timeout: 60))
        }
        webViewsQuery.secureTextFields["Password"].tap()
        webViewsQuery.secureTextFields["Password"].typeText(pass)
        webViewsQuery.buttons["Sign In"].tap()

        XCTAssertTrue(app.webViews.staticTexts["Sign in failed!"].waitForExistence(timeout: 60))
    }

    private func passSystemAlert(button: String) {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        XCTAssertTrue(springboard.buttons[button].waitForExistence(timeout: 30))
        springboard.buttons[button].tap()
    }
}

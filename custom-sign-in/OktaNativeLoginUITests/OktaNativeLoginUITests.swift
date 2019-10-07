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

class OktaNativeLoginUITests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment = ProcessInfo.processInfo.environment
        app.launch()
        addUIInterruptionMonitor(withDescription: "System Dialog") { (alert) -> Bool in
            let continueButton = alert.buttons["Continue"]
            if continueButton.exists {
                continueButton.tap()
            }
            return true
        }
    }

    override func tearDown() {
        super.tearDown()
    }
    
    func testLoginSuccess() {
        let app = XCUIApplication()
        let env = ProcessInfo.processInfo.environment
        guard let login = env["LOGIN"],
            let pass = env["PASS"],
            let firstName = env["FIRST_NAME"] else {
                XCTFail("Environment variables LOGIN, PASS, FIRST_NAME, LAST_NAME not set")
                return
        }
        
        app.textFields["Username"].tap()
        app.textFields["Username"].typeText(login)
        app.secureTextFields["Password"].tap()
        app.secureTextFields["Password"].typeText(pass)
        app.buttons["Sign In"].tap()
        
        XCTAssertTrue(app.staticTexts["Welcome, \(firstName)"].waitForExistence(timeout: 30))
        XCTAssertTrue(app.staticTexts["YES"].waitForExistence(timeout: 30))
        
        app.buttons["View Tokens"].tap()
        
        XCTAssertTrue(app.buttons["Refresh"].waitForExistence(timeout: 10))

        app.buttons["Refresh"].tap()

        XCTAssertTrue(app.alerts["Token refreshed!"].waitForExistence(timeout: 30))

        app.alerts["Token refreshed!"].buttons["OK"].tap()
        
        let backButton = app.buttons.element(boundBy: 0)
        backButton.tap()
        
        if #available(iOS 11.0, *) {
            app.buttons["Sign Out"].tap()
            app.tap()
            XCTAssertTrue(app.buttons["Sign In"].waitForExistence(timeout: 30))
        }
    }
    
    func testLoginFailure() {
        let app = XCUIApplication()
        let login = UUID().uuidString
        let pass = UUID().uuidString
        
        app.textFields["Username"].tap()
        app.textFields["Username"].typeText(login)
        app.secureTextFields["Password"].tap()
        app.secureTextFields["Password"].typeText(pass)
        app.buttons["Sign In"].tap()
        
        XCTAssertTrue(app.alerts["Error"].waitForExistence(timeout: 30))
    }
}

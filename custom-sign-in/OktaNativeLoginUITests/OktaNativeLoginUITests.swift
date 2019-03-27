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
    }

    override func tearDown() {
        super.tearDown()
    }
    
    func testLoginSuccess() {
        let app = XCUIApplication()
        let env = ProcessInfo.processInfo.environment
        guard let login = env["LOGIN"],
            let pass = env["PASS"],
            let firstName = env["FIRST_NAME"],
            let lastName = env["LAST_NAME"] else {
                XCTFail("Environment variables LOGIN, PASS, FIRST_NAME, LAST_NAME not set")
                return
        }
        
        app.buttons["Login"].tap()
        
        app.textFields["Login"].tap()
        app.textFields["Login"].typeText(login)
        app.secureTextFields["Password"].tap()
        app.secureTextFields["Password"].typeText(pass)
        app.buttons["Login"].tap()
        
        XCTAssertTrue(app.alerts["Logged In!"].waitForExistence(timeout: 30))
        app.alerts["Logged In!"].buttons["User Profile"].tap()
        
        XCTAssertTrue(app.staticTexts[firstName].waitForExistence(timeout: 1))
        XCTAssertTrue(app.staticTexts[lastName].exists)
        
        app.navigationBars["User Profile"].buttons["Back"].tap()
        app.buttons["Logout"].tap()
        
        XCTAssertTrue(app.staticTexts["Unathenticated"].exists)
    }
    
    func testLoginFailure() {
        let app = XCUIApplication()
        let login = UUID().uuidString
        let pass = UUID().uuidString
        
        app.buttons["Login"].tap()
        
        app.textFields["Login"].tap()
        app.textFields["Login"].typeText(login)
        app.secureTextFields["Password"].tap()
        app.secureTextFields["Password"].typeText(pass)
        app.buttons["Login"].tap()
        
        XCTAssertTrue(app.alerts["Error"].waitForExistence(timeout: 30))
    }
}

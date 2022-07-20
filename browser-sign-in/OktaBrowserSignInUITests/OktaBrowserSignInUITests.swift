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
import WebAuthenticationUI

class OktaBrowserSignInUITests: XCTestCase {
    lazy var username: String? = {
        ProcessInfo.processInfo.environment["LOGIN"]
    }()

    lazy var password: String? = {
        ProcessInfo.processInfo.environment["PASS"]
    }()
    
    lazy var signInScreen: SignInScreen = { SignInScreen(self) }()
    lazy var profileScreen: ProfileScreen = { ProfileScreen(self) }()

    override func setUpWithError() throws {
        let app = XCUIApplication()
        app.launchEnvironment = ["AutoCorrection": "Disabled"]
        app.launchArguments = ["--reset-keychain"]
        app.launch()
        
        continueAfterFailure = false
    }
    
    func testCancel() throws {
        signInScreen.isVisible()
        signInScreen.setEphemeral(true)
        signInScreen.login()
        signInScreen.cancel()
        signInScreen.isVisible()
    }

    func testEphemeralLoginAndSignOut() throws {
        signInScreen.isVisible()
        signInScreen.setEphemeral(true)
        signInScreen.login(username: username, password: password)
        profileScreen.wait()
        let userNameQuery = profileScreen.app.staticTexts.matching(identifier: "Username").element.label
        XCTAssertEqual(userNameQuery, username)
        profileScreen.signOut()
        signInScreen.isVisible()
    }
    
    func testLoginFailure() {
        let app = XCUIApplication()
        let login = UUID().uuidString
        let password = UUID().uuidString
        
        signInScreen.isVisible()
        signInScreen.setEphemeral(true)
        signInScreen.login(username: login, password: password)
        
        XCTAssertTrue(app.webViews.staticTexts["Unable to sign in"].waitForExistence(timeout: .standard))
    }
}


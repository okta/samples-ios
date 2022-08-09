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
    lazy var profileScreen: ProfileScreen = { ProfileScreen() }()
    
    override func setUpWithError() throws {
        let app = XCUIApplication()
        app.launchEnvironment = ["AutoCorrection": "Disabled"]
        app.launchArguments = ["--reset-keychain"]
        app.launch()
        
        continueAfterFailure = false
    }
    
    func testCancelLogin() throws {
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
        
        XCTAssertTrue(
            app.webViews.staticTexts["Unable to sign in"].waitForExistence(timeout: 1)
        )
    }
    
    func testRefreshToken() {
        signInScreen.isVisible()
        signInScreen.setEphemeral(true)
        signInScreen.login(username: username, password: password)
        profileScreen.wait()
        profileScreen.refreshToken()
    }
    
    func testRevokoToken() {
        signInScreen.isVisible()
        signInScreen.setEphemeral(true)
        signInScreen.login(username: username, password: password)
        profileScreen.wait()
        profileScreen.revokeToken()
        signInScreen.isVisible()
    }
    
    func testIntrospectToken() {
        signInScreen.isVisible()
        signInScreen.setEphemeral(true)
        signInScreen.login(username: username, password: password)
        profileScreen.wait()
        profileScreen.introspectToken()
    }
    
    func testSigninWithBrowser() {
        signInScreen.isVisible()
        signInScreen.setEphemeral(true)
        signInScreen.login(username: username, password: password)
        profileScreen.wait()
        XCTAssertEqual(profileScreen.valueLabel(for: "Username"), username)
    }
    
    func testSignoutOfBrowser() {
        signInScreen.isVisible()
        signInScreen.setEphemeral(true)
        signInScreen.login(username: username, password: password)
        profileScreen.wait()
        XCTAssertEqual(profileScreen.valueLabel(for: "Username"), username)
        profileScreen.signOut()
        signInScreen.isVisible()
    }
}

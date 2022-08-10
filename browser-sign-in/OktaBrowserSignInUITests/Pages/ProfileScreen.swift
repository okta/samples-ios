//
// Copyright (c) 2022-Present, Okta, Inc. and/or its affiliates. All rights reserved.
// The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
//
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
// See the License for the specific language governing permissions and limitations under the License.
//

import Foundation
import XCTest

class ProfileScreen {
    let app: XCUIApplication
    lazy var usernameLabel = app.staticTexts["Username"].label
    private lazy var signOutButton = app.buttons["Sign Out"]
    private lazy var viewTokensButton = app.buttons["viewTokens"]
    private lazy var refreshTokenButton = app.buttons["refresh"]
    private lazy var tokenLabel = app.textViews["token"]
    private lazy var revokeTokenButton = app.buttons["revoke"]
    private lazy var introspectTokenButton = app.buttons["introspect"]

    init(app: XCUIApplication = XCUIApplication()) {
        self.app = app
    }
    
    func wait(timeout: TimeInterval = 3) {
        _ = app.staticTexts["Welcome"].waitForNonExistence(timeout: timeout)
    }
    
    func signOut() {
        _ = signOutButton.waitForExistence(timeout: 1)
        signOutButton.tap()
        app.tap()
        XCTAssertTrue(app.webViews.element.waitForNonExistence(timeout: 3))
    }
    
    func refreshToken() {
        _ = viewTokensButton.waitForExistence(timeout: 1)
        viewTokensButton.tap()
        XCTAssertTrue(refreshTokenButton.exists)
        refreshTokenButton.tap()
        _ = app.staticTexts["Token refreshed!"].waitForExistence(timeout: 2)
        app.buttons["OK"].tap()
        XCTAssertNotNil(tokenLabel.value)
    }
    
    func revokeToken() {
        _ = viewTokensButton.waitForExistence(timeout: 1)
        viewTokensButton.tap()
        XCTAssertTrue(refreshTokenButton.exists)
        revokeTokenButton.tap()
    }
    
    func introspectToken() {
        _ = viewTokensButton.waitForExistence(timeout: 1)
        viewTokensButton.tap()
        XCTAssertTrue(introspectTokenButton.exists)
        introspectTokenButton.tap()
        _ = app.staticTexts["Access token is active!"].waitForExistence(timeout: 1)
        app.buttons["OK"].tap()
    }
}

extension XCUIElement {
    func waitForNonExistence(timeout: TimeInterval) -> Bool {
        let timeStart = Date().timeIntervalSince1970
        
        while Date().timeIntervalSince1970 <= (timeStart + timeout) {
            if !exists {
                return true
            }
        }
        return false
    }
}

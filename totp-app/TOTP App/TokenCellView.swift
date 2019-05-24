/*
 * Copyright (c) 2019, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import UIKit
import OneTimePassword

class TokenCellView: UITableViewCell {

    static let reuseIdentifier = "TokenCellView"
    
    @IBOutlet var issuerLabel: UILabel!
    @IBOutlet var codeLabel: UILabel!
    @IBOutlet var nameLabel: UILabel!
    
    private var updateTimer: Timer?
    
    var token: PersistentToken? {
        didSet {
            configure()
            stopUpdateTimer()
            if (nil != token) {
                runUpdateTimer()
            }
        }
    }
    
    func configure() {
        issuerLabel.text = token?.token.issuer
        codeLabel.text = token?.token.currentPassword
        nameLabel.text = token?.token.name
    }
    
    private func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func runUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { _ in
            self.codeLabel.text = self.token?.token.currentPassword
        })
    }
}


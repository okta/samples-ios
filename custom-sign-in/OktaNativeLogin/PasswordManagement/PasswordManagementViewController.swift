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

import Foundation
import OktaAuthSdk

class PasswordManagementViewController: AuthBaseViewController {

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.navigationItem.setHidesBackButton(true, animated: false)
        skipButton.isHidden = true

        if let warningStatus = status as? OktaAuthStatusPasswordWarning {
            skipButton.isHidden = warningStatus.canSkip()
        }
        
        let showCancel = status?.canCancel() ?? false
        cancelButton.isHidden = !showCancel
    }

    @IBAction private func changeTapped() {
        guard let oldPassword = oldPasswordField.text, !oldPassword.isEmpty,
              let newPassword = newPasswordField.text, !newPassword.isEmpty else { return }
        
        startProgress()
        if let expiredStatus = status as? OktaAuthStatusPasswordExpired {
            expiredStatus.changePassword(oldPassword: oldPassword,
                                         newPassword: newPassword,
                                         onStatusChange:
                { status in
                    self.handleSdkUpdate(status: status, error: nil)
            })  { error in
                    self.handleSdkUpdate(status: nil, error: error)
            }
        }
        if let warningStatus = status as? OktaAuthStatusPasswordWarning {
            warningStatus.changePassword(oldPassword: oldPassword,
                                         newPassword: newPassword,
                                         onStatusChange:
                { status in
                    self.handleSdkUpdate(status: status, error: nil)
            })  { error in
                    self.handleSdkUpdate(status: nil, error: error)
            }
        }
    }
    
    @IBAction private func skipTapped() {
        startProgress()
        if let warningStatus = status as? OktaAuthStatusPasswordWarning {
            warningStatus.skipPasswordChange(onStatusChange: { status in
                self.handleSdkUpdate(status: status, error: nil)
            }) { error in
                self.handleSdkUpdate(status: nil, error: error)
            }
        }
    }

    @IBAction private func cancelTapped() {
        status?.cancel()
        self.flowCoordinatorDelegate?.onCancel()
    }

    func handleSdkUpdate(status: OktaAuthStatus?, error: OktaError?) {
        stopProgress()
        if let status = status {
            flowCoordinatorDelegate?.onStatusChanged(status: status)
        }
        if let error = error {
            showError(message: error.description)
        }
    }

    func startProgress() {
        self.progressIndicatorView.startAnimating()
        self.buttonsStackView.isUserInteractionEnabled = false
    }
    
    func stopProgress() {
        self.buttonsStackView.isUserInteractionEnabled = true
        self.progressIndicatorView.stopAnimating()
    }

    // MARK: - IB
    
    @IBOutlet weak var oldPasswordField: UITextField!
    @IBOutlet weak var newPasswordField: UITextField!
    @IBOutlet weak var progressIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var buttonsStackView: UIStackView!
    @IBOutlet weak var changeButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
}

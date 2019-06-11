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
import SVProgressHUD

class PasswordManagementViewController: AuthBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

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
        
        SVProgressHUD.show()
        if let expiredStatus = status as? OktaAuthStatusPasswordExpired {
            expiredStatus.changePassword(oldPassword: oldPassword,
                                         newPassword: newPassword,
                                         onStatusChange:
                { [weak self] status in
                    self?.handleSdkUpdate(status: status, error: nil)
            })  { [weak self] error in
                    self?.handleSdkUpdate(status: nil, error: error)
            }
        }
        if let warningStatus = status as? OktaAuthStatusPasswordWarning {
            warningStatus.changePassword(oldPassword: oldPassword,
                                         newPassword: newPassword,
                                         onStatusChange:
                { [weak self] status in
                    self?.handleSdkUpdate(status: status, error: nil)
            })  { [weak self] error in
                    self?.handleSdkUpdate(status: nil, error: error)
            }
        }
    }
    
    @IBAction private func skipTapped() {
        SVProgressHUD.show()
        if let warningStatus = status as? OktaAuthStatusPasswordWarning {
            warningStatus.skipPasswordChange(onStatusChange: { [weak self] status in
                self?.handleSdkUpdate(status: status, error: nil)
            }) { [weak self] error in
                self?.handleSdkUpdate(status: nil, error: error)
            }
        }
    }

    @IBAction private func cancelTapped() {
        status?.cancel()
        self.flowCoordinatorDelegate?.onCancel()
    }

    func handleSdkUpdate(status: OktaAuthStatus?, error: OktaError?) {
        SVProgressHUD.dismiss()
        if let status = status {
            flowCoordinatorDelegate?.onStatusChanged(status: status)
        }
        if let error = error {
            showError(message: error.description)
        }
    }

    // MARK: - IB
    
    @IBOutlet weak var oldPasswordField: UITextField!
    @IBOutlet weak var newPasswordField: UITextField!
    @IBOutlet weak var buttonsStackView: UIStackView!
    @IBOutlet weak var changeButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
}

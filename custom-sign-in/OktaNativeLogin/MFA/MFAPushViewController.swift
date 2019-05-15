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

import UIKit
import OktaAuthSdk
import SVProgressHUD

class MFAPushViewController : AuthBaseViewController {
    
    lazy var factor: OktaFactorPush = {
        let mfaChallengeStatus = status as! OktaAuthStatusFactorChallenge
        return mfaChallengeStatus.factor as! OktaFactorPush
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let mfaChallengeStatus = status as! OktaAuthStatusFactorChallenge
        resendButton.isHidden = !mfaChallengeStatus.canResend()
        cancelButton.isHidden = !mfaChallengeStatus.canCancel()
        factorResultLabel.text = mfaChallengeStatus.factorResult?.rawValue ?? "Unknown factor result"
        if let factorStatus = mfaChallengeStatus.factorResult?.rawValue {
            if mfaChallengeStatus.factorResult! == .waiting {
                SVProgressHUD.show(withStatus: factorStatus)
                SVProgressHUD.dismiss(withDelay: 15)
            }
            factorResultLabel.text = factorStatus
        } else {
            factorResultLabel.text = "Unknown factor result"
        }
        factor.verify(onStatusChange: { status in
            SVProgressHUD.dismiss()
            if status.statusType == self.status?.statusType {
                return
            }
            self.flowCoordinatorDelegate?.onStatusChanged(status: status)
        }, onError: { error in
            SVProgressHUD.dismiss()
            self.showError(message: error.description)
        }) { factorResult in
            self.factorResultLabel.text = factorResult.rawValue
        }
    }
    
    @IBAction private func resendTapped() {
        SVProgressHUD.show(withStatus: "Requesting resend...")
        SVProgressHUD.dismiss(withDelay: 15)
        let mfaChallengeStatus = status as! OktaAuthStatusFactorChallenge
        mfaChallengeStatus.resendFactor(onStatusChange: { status in
            SVProgressHUD.dismiss()
            if status.statusType == self.status?.statusType {
                return
            }
            self.flowCoordinatorDelegate?.onStatusChanged(status: status)
        }) { error in
            SVProgressHUD.dismiss()
            self.showError(message: error.description)
        }
    }

    @IBAction func cancelButtonTapped() {
        SVProgressHUD.dismiss()
        self.processCancel()
    }

    @IBOutlet private var factorResultLabel: UILabel!
    @IBOutlet private var resendButton: UIButton!
    @IBOutlet private var cancelButton: UIButton!
}

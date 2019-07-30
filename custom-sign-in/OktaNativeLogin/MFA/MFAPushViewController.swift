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

class MFAPushViewController: AuthBaseViewController {
    
    var factor: OktaFactorPush {
        let mfaChallengeStatus = status as! OktaAuthStatusFactorChallenge
        return mfaChallengeStatus.factor as! OktaFactorPush
    }

    var pushFactorHandler: MFAPushFactorHandler = MFAPushFactorHandler()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let mfaChallengeStatus = status as! OktaAuthStatusFactorChallenge
        resendButton.isHidden = !mfaChallengeStatus.canResend()
        resendButton.isEnabled = false
        cancelButton.isHidden = !mfaChallengeStatus.canCancel()
        factorResultLabel.text = mfaChallengeStatus.factorResult?.rawValue ?? "Unknown factor result"
        factorResultLabel.flash()
        
        if let factorStatus = mfaChallengeStatus.factorResult?.rawValue {
            factorResultLabel.text = factorStatus
        } else {
            factorResultLabel.text = "Unknown factor result"
        }
        
        pushFactorHandler.delegate = self
        factor.verify(onStatusChange: { [weak self] status in
            self?.pushFactorHandler.handlePushFactorResponse(status: status)
        }) { [weak self] error in
            self?.showError(message: error.description)
        }
    }

    override func backButtonTapped() {
        super.backButtonTapped()
        self.pushFactorHandler.cancel()
        self.pushFactorHandler.delegate = nil
    }
    
    @IBAction private func resendTapped() {
        SVProgressHUD.show(withStatus: "Requesting resend...")
        SVProgressHUD.dismiss(withDelay: 15)
        let mfaChallengeStatus = status as! OktaAuthStatusFactorChallenge
        mfaChallengeStatus.resendFactor(onStatusChange: { [weak self] status in
            self?.pushFactorHandler.handlePushFactorResponse(status: status)
        }) { [weak self] error in
            SVProgressHUD.dismiss()
            self?.showError(message: error.description)
        }
    }

    @IBAction func cancelButtonTapped() {
        self.pushFactorHandler.cancel()
        self.pushFactorHandler.delegate = nil
        self.processCancel()
    }

    @IBOutlet private var factorResultLabel: UILabel!
    @IBOutlet private var resendButton: UIButton!
    @IBOutlet private var cancelButton: UIButton!
}

extension MFAPushViewController: MFAPushFactorHandlerProtocol {
    func onStatusChanged(status: OktaAuthStatus) {
        self.flowCoordinatorDelegate?.onStatusChanged(status: status)
    }

    func onPollingProgress(status: OktaAuthStatus) {
        self.status = status
    }

    func onPollingStopped(status: OktaAuthStatus) {
        self.factorResultLabel.layer.removeAllAnimations()
        self.factorResultLabel.text = status.factorResult?.rawValue ?? "Unknown factor result"
    }

    func onError(error: OktaError) {
        self.showError(message: error.description)
    }
}

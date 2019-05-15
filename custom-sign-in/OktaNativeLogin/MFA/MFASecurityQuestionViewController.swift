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

class MFASecurityQuestionViewController: AuthBaseViewController {

    lazy var factor: OktaFactor = {
        let mfaChallengeStatus = status as! OktaAuthStatusFactorChallenge
        return mfaChallengeStatus.factor
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //sendQuestionHandler?()
    }
    
    func verifySecurityQuestion(callback: @escaping (String) -> Void) {
        //onVerify = callback
    }
    
    @IBAction func verifyTapped() {
        guard let answer = answerField.text else { return }
        //onVerify?(answer)
    }
    
    private func configure() {
        guard isViewLoaded else { return }
        
        questionLabel.text = factor.factor.profile?.questionText
    }

    @IBOutlet private var questionLabel: UILabel!
    @IBOutlet private var answerField: UITextField!
}

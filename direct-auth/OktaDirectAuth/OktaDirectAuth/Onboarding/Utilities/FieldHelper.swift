/*
 * Copyright (c) 2021, Okta, Inc. and/or its affiliates. All rights reserved.
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

/// Convenience helper used in Storyboards for linking input field responders together.
class FieldHelper: NSObject, UITextFieldDelegate {
    @IBOutlet weak var label: UIView? {
        didSet {
            label?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectFirstResponder(_:))))
        }
    }
    
    @IBOutlet weak var firstResponder: UIResponder?
    @IBOutlet weak var nextResponder: UIResponder?

    @objc
    @IBAction func selectFirstResponder(_ sender: Any) {
        firstResponder?.becomeFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == firstResponder,
           let nextResponder = nextResponder
        {
            if let control = nextResponder as? UIButton {
                control.sendActions(for: .touchUpInside)
            } else {
                nextResponder.becomeFirstResponder()
            }
        }
        
        return true
    }
}

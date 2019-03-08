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

class UserProfileViewController: UIViewController {

    @IBOutlet private var usernameLabel: UILabel!
    @IBOutlet private var firstnameLabel: UILabel!
    @IBOutlet private var lastnameLabel: UILabel!
    @IBOutlet private var localeLabel: UILabel!
    @IBOutlet private var timezoneLabel: UILabel!

    var profile: EmbeddedResponse.User.Profile? {
        didSet {
            updateUI()
        }
    }
    
    static func create() -> UserProfileViewController {
        return UIStoryboard(name: "UserProfile", bundle: nil)
            .instantiateViewController(withIdentifier: "UserProfileViewController")
            as! UserProfileViewController
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationItem.title = "User Profile"
        
        updateUI()
    }
    
    private func updateUI() {
        guard isViewLoaded else { return }

        updateLabel(usernameLabel, with: profile?.login)
        updateLabel(firstnameLabel, with: profile?.firstName)
        updateLabel(lastnameLabel, with: profile?.lastName)
        updateLabel(localeLabel, with: profile?.locale)
        updateLabel(timezoneLabel, with: profile?.timeZone)
    }
    
    private func updateLabel(_ label: UILabel, with value: String?) {
        guard let value = value else {
            label.text = "Unknown"
            label.textColor = UIColor.lightGray
            return
        }
        
        label.text = value
        label.textColor = UIColor.darkGray
    }
}

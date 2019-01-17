//
//  UserProfileViewController.swift
//  OktaNativeLogin
//
//  Created by Anastasii Iurok on 1/17/19.
//  Copyright © 2019 Okta. All rights reserved.
//

import UIKit
import OktaAuthNative

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
    
    static func fromStoryboard() -> UserProfileViewController {
        return UIStoryboard(name: "Main", bundle: nil)
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

//
//  DetailViewController.swift
//  OktaBrowserSignIn
//
//  Created by Anastasiia Iurok on 1/18/19.
//  Copyright © 2019 Okta. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet private var contentTextView: UITextView!
    
    var content: String? {
        didSet {
            configure()
        }
    }
    
    static func fromStoryboard() -> DetailViewController {
        return UIStoryboard(name: "Main", bundle: nil)
               .instantiateViewController(withIdentifier: "DetailViewController")
               as! DetailViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    private func configure() {
        guard isViewLoaded else { return }
        contentTextView.text = content
    }
}


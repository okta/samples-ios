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


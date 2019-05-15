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

class MFAViewController: AuthBaseViewController {
    
    lazy var factors: [OktaFactor] = {
        let mfaRequiredStatus = status as! OktaAuthStatusFactorRequired
        return mfaRequiredStatus.availableFactors
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        table.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction private func cancelTapped() {
        self.processCancel()
    }

    @IBOutlet private var table: UITableView!
}

extension MFAViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.factors.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MFAFactorCell") ??
            UITableViewCell(style: .default, reuseIdentifier: "MFAFactorCell")
        
        let factor = self.factors[indexPath.row]
        cell.textLabel?.text = factor.factor.factorType.description
        
        return cell
    }
}

extension MFAViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let factor = self.factors[indexPath.row]
        factor.select(onStatusChange: { status in
            self.flowCoordinatorDelegate?.onStatusChanged(status: status)
        }) { error in
            self.showError(message: error.description)
        }
    }
}

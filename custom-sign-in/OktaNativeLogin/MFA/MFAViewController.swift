//
//  MFAViewController.swift
//  OktaNativeLogin
//
//  Created by Anastasiia Iurok on 2/1/19.
//  Copyright © 2019 Okta. All rights reserved.
//

import UIKit
import OktaAuthNative

class MFAViewController: UIViewController {
    
    typealias MFAViewControllerCompletion = (_ factor: EmbeddedResponse.Factor, _ code: String?) -> Void
    
    @IBOutlet private var table: UITableView!

    private var factors = [EmbeddedResponse.Factor]()
    private var completion: MFAViewControllerCompletion?
    private var cancel: (() -> Void)?
    
    @discardableResult
    static func loadAndPresent(from presentingController: UIViewController, factors: [EmbeddedResponse.Factor], completion: MFAViewControllerCompletion?, cancel: (() -> Void)?) -> MFAViewController {
        let navigation = UIStoryboard(name: "MFA", bundle: nil)
            .instantiateViewController(withIdentifier: "MFANavigationController")
            as! UINavigationController
        
        let controller = navigation.topViewController as! MFAViewController

        controller.factors = factors
        controller.completion = completion
        controller.cancel = cancel
        
        presentingController.present(navigation, animated: true)
        
        return controller
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        table.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    @IBAction private func cancelTapped() {
        dismiss(animated: true) {
            self.cancel?()
        }
    }
}

extension MFAViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.factors.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MFAFactorCell") ??
            UITableViewCell(style: .default, reuseIdentifier: "MFAFactorCell")
        
        let factor = self.factors[indexPath.row]
        cell.textLabel?.text = factor.factorType?.description
        
        return cell
    }
}

extension MFAViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let factor = self.factors[indexPath.row]
        switch factor.factorType! {
        case .push:
            let controller = MFAPushViewController.create(with: factor) {
                self.dismiss(animated: true, completion: {
                    self.completion?(factor, nil)
                })
            }

            self.navigationController?.pushViewController(controller, animated: true)
            
        default:
            break
        }
    }
}

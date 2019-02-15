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
    
    typealias MFAFactorSlectionHandler = (_ factor: EmbeddedResponse.Factor) -> Void
    
    @IBOutlet private var table: UITableView!

    private var factors = [EmbeddedResponse.Factor]()
    private var selectionHandler: MFAFactorSlectionHandler?
    private var cancel: (() -> Void)?
    
    private var currentController: UIViewController?

    @discardableResult
    static func loadAndPresent(from presentingController: UIViewController, factors: [EmbeddedResponse.Factor], selectionHandler: MFAFactorSlectionHandler?, cancel: (() -> Void)?) -> MFAViewController {
        let navigation = UIStoryboard(name: "MFA", bundle: nil)
            .instantiateViewController(withIdentifier: "MFANavigationController")
            as! UINavigationController
        
        let controller = navigation.topViewController as! MFAViewController

        controller.factors = factors
        controller.selectionHandler = selectionHandler
        controller.cancel = cancel
        
        presentingController.present(navigation, animated: true)
        
        return controller
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        table.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        currentController = nil
    }
    
    func requestSMSCode(callback: @escaping (String) -> Void) {
        guard let smsController = currentController as? MFASMSViewController else {
            return
        }
        
        smsController.verifySMS { code in
            self.navigationController?.dismiss(animated: true) {
                callback(code)
            }
        }
    }
    
    func requestSecurityQuestionAnswer(callback: @escaping (String) -> Void)  {
        guard let questionController = currentController as? MFASecurityQuestionViewController else {
            return
        }
        
        questionController.verifySecurityQuestion { answer in
            self.navigationController?.dismiss(animated: true) {
                callback(answer)
            }
        }
    }
    
    func requestTOTP(callback: @escaping (String) -> Void) {
        guard let totpController = currentController as? MFATOTPViewController else {
            return
        }
        
        totpController.requestTOTP { code in
            self.navigationController?.dismiss(animated: true) {
                callback(code)
            }
        }
    }
    
    @IBAction private func cancelTapped() {
        self.navigationController?.dismiss(animated: true) {
            self.cancel?()
        }
    }
    
    private func factor(ofType type: FactorType) -> EmbeddedResponse.Factor? {
        return self.factors.first(where: { $0.factorType == type })
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
        var controller: UIViewController?
        
        let factor = self.factors[indexPath.row]
        switch factor.factorType! {
        case .push:
            controller = MFAPushViewController.create(with: factor, pushHandler: { [weak self] in
                self?.navigationController?.dismiss(animated: true) {
                    self?.selectionHandler?(factor)
                }
            })
            
        case .sms:
            controller = MFASMSViewController.create(with: factor) { [weak self] in
                self?.selectionHandler?(factor)
            }
            
        case .question:
            controller = MFASecurityQuestionViewController.create(with: factor) { [weak self] in
                self?.selectionHandler?(factor)
            }
            
        case .TOTP:
            controller = MFATOTPViewController.create(with: factor) { [weak self] in
                self?.selectionHandler?(factor)
            }
            
        default:
            break
        }
        
        if let controller = controller {
            self.currentController = controller
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
}

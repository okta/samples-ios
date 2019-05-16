/*
 * Copyright (c) 2019, Okta, Inc. and/or its affiliates. All rights reserved.
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
import OneTimePassword

class ViewController: UIViewController {

    @IBOutlet var tableView: UITableView!
    
    private var persistentTokens = [PersistentToken]()

    override func viewDidLoad() {
        super.viewDidLoad()
        loadTokens()
    }
    
    // MARK: - Tokens
    
    private func loadTokens() {
        do {
            persistentTokens = Array<PersistentToken>(try Keychain.sharedInstance.allPersistentTokens())
            tableView.reloadData()
        } catch {
            print("Failed to read tokens: \(error)")
        }
    }
    
    private func addToken(_ token: Token) {
        do {
            let persistentToken = try Keychain.sharedInstance.add(token)
            persistentTokens.append(persistentToken)
            tableView.insertRows(at: [IndexPath(row: persistentTokens.count - 1, section: 0)], with: .automatic)
        } catch {
            print("Failed to store token: \(error)")
        }
    }
    
    private func deleteToken(at index: Int) {
        let persistentToken = persistentTokens[index]
        do {
            try Keychain.sharedInstance.delete(persistentToken)
            persistentTokens.remove(at: index)
        } catch {
            print("Failed to remove token: \(error)")
        }
    }
    
    // MARK: - Actions
    
    @IBAction func add() {
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let scanAction = UIAlertAction(title: "Scan QR Code", style: .default) { _ in
            self.presentQRScannerController()
        }
        controller.addAction(scanAction)
        
        let manualAction = UIAlertAction(title: "Input Manually", style: .default) { _ in
            self.presentManualInputController()
        }
        controller.addAction(manualAction)
        
        present(controller, animated: true)
    }
    
    private func presentQRScannerController() {
        let controller = QRScannerController.create()
        controller.completion = addToken(_:)
        navigationController?.pushViewController(controller, animated: true)
    }
    
    private func presentManualInputController() {
        let controller = ManualCodeEntryController.create()
        controller.completion = addToken(_:)
        navigationController?.pushViewController(controller, animated: true)
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return persistentTokens.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TokenCellView.reuseIdentifier) as! TokenCellView
        cell.token = persistentTokens[indexPath.row]
        return cell
    }
}

extension ViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteToken(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}

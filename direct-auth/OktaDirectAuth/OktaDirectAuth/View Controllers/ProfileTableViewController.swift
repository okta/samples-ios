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
import OktaIdx

extension User.ProfileKey {
    var label: String? {
        switch self {
        case .id:
            return "User ID"
        case .name:
            return "Name"
        case .email:
            return "Email"
        case .profile:
            return "Profile"
        case .nickname:
            return "Nickname"
        case .zoneinfo:
            return "Timezone"
        case .locale:
            return "Locale"
        case .username:
            return "Username"
        case .givenName:
            return "First name"
        case .middleName:
            return "Middle name"
        case .familyName:
            return "Last name"
        case .phoneNumber:
            return "Phone number"
        }
    }
}

class ProfileTableViewController: UITableViewController {
    enum Section: Int {
        case profile = 0, details, signOut, count
    }
    
    struct Row {
        enum Kind: String {
            case destructive, disclosure, leftDetail, rightDetail
        }
        
        let kind: Kind
        let id: String?
        let title: String
        let detail: String?
        init(kind: Kind, id: String? = nil, title: String, detail: String? = nil) {
            self.kind = kind
            self.id = id
            self.title = title
            self.detail = detail
        }
    }

    var tableContent: [Section: [Row]] = [:]
    var user: User? {
        didSet {
            if let user = user {
                DispatchQueue.main.async {
                    self.configure(user)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        user = OnboardingManager.shared?.currentUser

        NotificationCenter.default.addObserver(forName: .authenticationSuccessful,
                                               object: nil,
                                               queue: .main) { (notification) in
            guard let user = notification.object as? User else { return }
            self.user = user
        }
    }
    
    func row(at indexPath: IndexPath) -> Row? {
        guard let tableSection = Section(rawValue: indexPath.section),
              let row = tableContent[tableSection]?[indexPath.row]
        else {
            return nil
        }
        
        return row
    }
    
    func configure(_ user: User) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .long
        
        title = user[.name] ?? "Profile"
        self.tabBarItem.title = title
        
        tableContent = [
            .profile: [],
            .details: [
                .init(kind: .disclosure,
                      id: "details",
                      title: "Token details")
            ],
            .signOut: [
                .init(kind: .destructive,
                      id: "signout",
                      title: "Sign out")
            ]
        ]
        
        for key in User.ProfileKey.allCases {
            guard let value = user[key],
                  let title = key.label
            else { continue }
            
            tableContent[.profile]?.append(.init(kind: .leftDetail,
                                                 title: title,
                                                 detail: value))
        }
        
        if let date = user.authenticatedAt {
            tableContent[.details]?.append(.init(kind: .rightDetail,
                                                 title: "Authenticated",
                                                 detail: dateFormatter.string(from: date)))
        }

        if let date = user.expiresAt {
            tableContent[.details]?.append(.init(kind: .rightDetail,
                                                 title: "Expires at",
                                                 detail: dateFormatter.string(from: date)))
        }
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count.rawValue
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let tableSection = Section(rawValue: section),
              let rows = tableContent[tableSection]
        else { return 0 }
        return rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let row = row(at: indexPath) else {
            return UITableViewCell()
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: row.kind.rawValue, for: indexPath)

        cell.textLabel?.text = row.title
        cell.detailTextLabel?.text = row.detail

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let row = row(at: indexPath) else { return }
        
        switch row.id {
        case "signout":
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alert.addAction(.init(title: "Clear tokens", style: .default) { (action) in
                OnboardingManager.shared?.currentUser = nil
            })
            alert.addAction(.init(title: "Revoke tokens", style: .destructive) { (action) in
            })
            alert.addAction(.init(title: "Cancel", style: .cancel))
            
            present(alert, animated: true)
            
        case "details":
            performSegue(withIdentifier: "TokenDetail", sender: tableView)
            
        default: break
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "TokenDetail":
            guard let target = segue.destination as? TokenDetailViewController else { break }
            target.token = user?.token
            
        default: break
        }
    }
}

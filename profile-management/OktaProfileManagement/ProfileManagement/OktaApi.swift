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

import Foundation
import OktaOidc

class OktaApi {
    let config: OktaOidcConfig
    
    lazy private var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        decoder.dateDecodingStrategy = .formatted(formatter)
        return decoder
    }()
    
    init(config: OktaOidcConfig) {
        self.config = config
    }
    
    func getUser(accessToken: String, completion: @escaping ((User?, Error?) -> Void)) {
        guard var url = URL(string: config.issuer) else {
            completion(nil, OktaOidcError.notConfigured)
            return
        }

        url.appendPathComponent("/api/v1/users/me")
        
        var request = URLRequest(url: url)
        request.addValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
    
        performRequest(request, completion: completion)
    }
    
     func changePassword(accessToken: String, old: String, new: String, completion: @escaping ((User?, Error?) -> Void)) {
        guard var url = URL(string: self.config.issuer) else {
            completion(nil, OktaOidcError.notConfigured)
            return
        }

        url.appendPathComponent("/api/v1/users/me/credentials/change_password")
    
        var request = URLRequest(url: url)
    
        request.httpMethod = "POST"

        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        request.addValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
    
        let passwordInfo = PasswordChange(old: old, new: new)
        request.httpBody = try? JSONEncoder().encode(passwordInfo)
    
        performRequest(request, completion: completion)
    }

    // MARK: - Private
    
    func performRequest(_ request: URLRequest, completion: @escaping ((User?, Error?) -> Void)) {
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            DispatchQueue.main.async {
                guard error == nil else {
                    completion(nil, OktaOidcError.APIError(error!.localizedDescription))
                    return
                }
                
                guard let data = data else {
                    completion(nil, OktaOidcError.APIError("No response data"))
                    return
                }

                do {
                    let user = try self.decoder.decode(User.self, from: data)
                    completion(user, nil)
                } catch {
                    completion(nil, OktaOidcError.parseFailure)
                }
            }
        }
        
        task.resume()
    }
}

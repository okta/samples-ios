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

import Foundation
import OktaIdx

extension String {
    func base64Decoded() -> Data? {
        var result = replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        let length = Double(result.lengthOfBytes(using: .utf8))
        let requiredLength = 4 * ceil(length / 4.0)
        let paddingLength = requiredLength - length
        
        if paddingLength > 0 {
            let padding = "".padding(toLength: Int(paddingLength),
                                     withPad: "=",
                                     startingAt: 0)
            result = result + padding
        }
        
        return Data(base64Encoded: result, options: .ignoreUnknownCharacters)
    }
}

extension IDXClient.Token {
    var profile: [String:Any]? {
        guard let data = idToken?.components(separatedBy: ".")[1].base64Decoded(),
              let profile = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any]
        else {
            return nil
        }
        
        return profile
    }
}

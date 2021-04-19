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

class BlurredBackground: NSObject, UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        guard !(viewController.view.subviews.first is UIVisualEffectView) else { return }
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        blurView.frame = viewController.view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewController.view.insertSubview(blurView, at: 0)
        viewController.view.backgroundColor = .clear
    }
}

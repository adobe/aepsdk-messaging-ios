//
// Copyright 2021 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import UIKit
import AEPAssurance

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let deepLinkURL = connectionOptions.urlContexts.first?.url {
            Assurance.startSession(url: deepLinkURL)
        }
        guard let _ = (scene as? UIWindowScene) else { return }
    }    
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let urlContexts = URLContexts.first else { return }
        Assurance.startSession(url: urlContexts.url)
        
        let alert = UIAlertController(title: "Deeplink Received", message: "\(urlContexts.url.description)", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Cool", style: UIAlertAction.Style.default, handler: nil))
        self.window?.rootViewController?.present(alert, animated: true, completion: nil)
    }
}

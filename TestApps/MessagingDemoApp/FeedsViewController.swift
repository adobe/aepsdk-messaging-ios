//
// Copyright 2023 Adobe. All rights reserved.
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
import AEPMessaging
import Foundation

class FeedsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Messaging.setFeedsHandler { feedsDict in
            for (_, feed) in feedsDict.enumerated() {
                print("\(feed)")
            }
        }
    }
    
    @IBAction func updateFeedsForSurfacePaths(_: Any) {
        Messaging.updateFeedsForSurfacePaths(["feeds/promos", "feeds/events"])
    }
    
    @IBAction func getFeedsForSurfacePaths(_: Any) {
        Messaging.getFeedsForSurfacePaths(["feeds/promos", "feeds/events"]) { feedsDict, error in
            
            guard error == nil,
                  let feedsDict = feedsDict else {
                return
            }
            
            for (_, feed) in feedsDict.enumerated() {
                print("\(feed)")
            }
        }
    }
}



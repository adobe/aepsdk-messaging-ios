//
// Copyright 2020 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import AEPCore
import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func collectMessageInfo(_ sender: Any) {
        let aodbeData: String = "{\n        \"cjm\" :{\n          \"_experience\":" +
            "{\n            \"customerJourneyManagement\": {\n              \"messageExecution\": " +
            "{\n                \"messageExecutionID\": \"16-Sept-postman\",\n                \"messageID\": \"567\",\n                \"journeyVersionID\": \"some-journeyVersionId\",\n                \"journeyVersionInstanceId\": \"someJourneyVersionInstanceId\"\n              }\n            }\n          }\n        }\n      }\n"
        let dict = ["eventType": "track.applicationOpened", "id": "123456", "applicationOpened": true, "adobe": aodbeData] as [String: Any]
        MobileCore.collectMessageInfo(messageInfo: dict)
    }
}

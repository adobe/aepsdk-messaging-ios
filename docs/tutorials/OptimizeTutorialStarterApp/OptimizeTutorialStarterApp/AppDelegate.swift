/*
Copyright 2022 Adobe. All rights reserved.
This file is licensed to you under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License. You may obtain a copy
of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under
the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
OF ANY KIND, either express or implied. See the License for the specific language
governing permissions and limitations under the License.
*/

/* Optimize Tutorial: CODE SECTION 1/10 BEGINS
import AEPCore
import AEPLifecycle
import AEPEdge
import AEPEdgeConsent
import AEPEdgeIdentity
import AEPAssurance
import AEPOptimize
// Optimize Tutorial: CODE SECTION 1 ENDS */
import SwiftUI

final class AppDelegate: NSObject, UIApplicationDelegate {
    private let DATA_COLLECTION_ENVIRONMENT_FILE_ID = ""
    private let OVERRIDE_DATASET_ID = ""
    
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
/* Optimize Tutorial: CODE SECTION 2/10 BEGINS
        MobileCore.setLogLevel(.trace)
        MobileCore.configureWith(appId: self.DATA_COLLECTION_ENVIRONMENT_FILE_ID)

        MobileCore.registerExtensions([
                Edge.self,
                AEPEdgeIdentity.Identity.self,
                Consent.self,
                Lifecycle.self,
                Optimize.self,
                Assurance.self ]) {
            
            // FOR DEMO PURPOSE ONLY: Update Configuration with reduced lifecycle timeout.
            MobileCore.updateConfigurationWith(configDict: ["lifecycle.sessionTimeout": 10])
 
            // Update Configuration with override dataset identifier
            // MobileCore.updateConfigurationWith(configDict: ["optimize.datasetId": self.OVERRIDE_DATASET_ID])
        }
// Optimize Tutorial: CODE SECTION 2 ENDS */
        return true
    }
}

@main
struct OptimizeTutotialStarterApp: App {
    @UIApplicationDelegateAdaptor var delegate: AppDelegate
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            HomeView()
/* Optimize Tutorial: CODE SECTION 4/10 BEGINS
                .onOpenURL{ url in
                    Assurance.startSession(url: url)
                }
// Optimize Tutorial: CODE SECTION 4 ENDS */
        }
/* Optimize Tutorial: CODE SECTION 3/10 BEGINS
        .onChange(of: scenePhase) { phase in
            switch phase {
                case .background:
                    print("Scene phase changed to background.")
                    MobileCore.lifecyclePause()
                case .active:
                    print("Scene phase changed to active.")
                    MobileCore.lifecycleStart(additionalContextData: nil)
                case .inactive:
                    print("Scene phase changed to inactive.")
                @unknown default:
                    print("Unknown scene phase.")
            }
        }
// Optimize Tutorial: CODE SECTION 3 ENDS */
    }
}

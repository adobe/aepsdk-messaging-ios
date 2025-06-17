/*
 Copyright 2024 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Testing
@testable import AEPCore
@testable import AEPMessaging
@testable import AEPEdge
@testable import AEPEdgeIdentity
@testable import AEPEdgeConsent
@testable import AEPServices
import AEPTestUtils

extension Tag {
    @Tag static var UITest : Self
    @Tag static var NetworkTest : Self
    @Tag static var SmallImageTemplate : Self
    @Tag static var LargeImageTemplate : Self
    @Tag static var TrackingTest : Self
}

class IntegrationTestBase {
    
    let mockNetwork: MockNetworkService = MockNetworkService()
    let homeSurface = Surface(path: "home")
    let invalidSurface = Surface(path: "invalid")
    let TIMEOUT: TimeInterval = 7
    
    init() {
        EventHub.reset()
        FileManager.default.clearCache()
        FileManager.default.clearDirectory()
        mockNetwork.clear()
        bootSDK()
    }
    
    /// Wrapper on getContentCardUI API designed to be used with Swift's async/await syntax.
    func getContentCardUI(_ surface : Surface,
                          customizer: ContentCardCustomizing? = nil,
                          listener : ContentCardUIEventListening? = nil,
                          shouldDownload: Bool = true) async throws -> [ContentCardUI] {
        if shouldDownload {
            Messaging.updatePropositionsForSurfaces([homeSurface])
        }
        return try await withCheckedThrowingContinuation { continuation in
            Messaging.getContentCardsUI(for: surface, customizer: customizer, listener: listener) { result in
                switch result {
                case .success(let contentCards):
                    continuation.resume(returning: contentCards)
                    break
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func setContentCardResponse(fromFile file: String) {
        let response = FileReader.readFromFile(file)
        mockNetwork.mock { request in
            guard request.url.absoluteString.starts(with: "https://adobe.dc.net/ee/v1/interact"),
                  let requestData = try? JSONSerialization.jsonObject(with: request.connectPayload, options: []) as? [String: Any],
                  let surfaces = self.mockNetwork.getSurfacesFromNetworkRequest(requestData),
                  surfaces.contains(self.homeSurface.uri) else {
                return nil
            }

            return response.data(using: .utf8)
        }
    }
    
    ///**************************************************************
    /// private  helper methods
    ///**************************************************************
    
    /// Boots the SDK by registering and configuring the required extension
    private func bootSDK() {
        ServiceProvider.shared.networkService = mockNetwork
        MobileCore.setLogLevel(.trace)
        MobileCore.registerExtensions([
            Identity.self,
            Messaging.self,
            Edge.self
        ])
        
        let waitForRegistration = CountDownLatch(1)
        let waitForNetworkCalls = CountDownLatch(1)
        mockNetwork.onEdgeNetworkRequest { request in
            waitForNetworkCalls.countDown()
        }
        MobileCore.registerExtensions([Messaging.self, Identity.self, Edge.self, Consent.self], {
            MobileCore.updateConfigurationWith(configDict: ["edge.configId": "edgeDomain",
                                                            "edge.domain" : "adobe.dc.net",
                                                            "consent.default" : [
                                                                "consents": [
                                                                    "collect": [
                                                                        "val": "y"
                                                                    ]
                                                                ]
                                                            ]])
            waitForRegistration.countDown()
        })
        // wait for registration and network call to download IAM be completed
        #expect(DispatchTimeoutResult.success == waitForRegistration.await(timeout: TIMEOUT))
        #expect(DispatchTimeoutResult.success == waitForNetworkCalls.await(timeout: TIMEOUT))
        mockNetwork.clear()
    }
}

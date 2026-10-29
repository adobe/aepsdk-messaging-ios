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
    @Tag static var ImageOnlyTemplate : Self
    @Tag static var TrackingTest : Self
}

class IntegrationTestBase {
    
    let mockNetwork: MockNetworkService = MockNetworkService()
    let homeSurface = Surface(path: "home")
    let invalidSurface = Surface(path: "invalid")
    let TIMEOUT: TimeInterval = 7
    
    init() {
        EventHub.reset()
        // Extensions shut down asynchronously after EventHub.reset(). Without a brief pause,
        // clearCache() deletes the Edge SQLite database while Edge still has it open, causing
        // "vnode unlinked while in use" and cascading disk I/O failures in subsequent tests.
        Thread.sleep(forTimeInterval: 0.5)
        closeCachedDataQueues()
        FileManager.default.clearCache()
        removeSQLiteSidecarFiles()
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
    
    private static let sqliteDatabases = ["com.adobe.edge", "com.adobe.edge.consent", "com.adobe.edge.identity"]

    /// The previous test's Edge still holds its cached SQLite queue open. Close it before its files are deleted, otherwise SQLite reports "vnode unlinked while in use" and can crash the test process.
    private func closeCachedDataQueues() {
        guard let dataQueueService = ServiceProvider.shared.dataQueueService as? DataQueueService else { return }
        for database in Self.sqliteDatabases {
            dataQueueService.store[database]?.close()
        }
    }

    /// Edge 5.2.0 and later open their hit queue in SQLite WAL mode. clearCache() only deletes the main database file, so the leftover -wal and -shm files make the next test's database fail with a disk I/O error and Edge never starts. Remove them too.
    private func removeSQLiteSidecarFiles() {
        guard let cachesUrl = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return }
        for database in Self.sqliteDatabases {
            for suffix in ["-wal", "-shm"] {
                try? FileManager.default.removeItem(at: cachesUrl.appendingPathComponent(database + suffix))
            }
        }
    }

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
                                                            "messaging.contentCardOfflineAvailable": true,
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

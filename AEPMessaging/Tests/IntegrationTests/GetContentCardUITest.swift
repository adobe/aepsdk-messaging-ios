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
import SwiftUI
@testable import AEPMessaging

@Suite("GetContentCardUI", .serialized)
class GetContentCardUITest : IntegrationTestBase {
    
    override init() {
        super.init()
    }
    
    @Test("when no cards available")
    func noCards() async throws {
        // setup
        setContentCardResponse(fromFile: "NoCard")
        
        // test and verify
        await #expect(throws: ContentCardUIError.dataUnavailable) {
            try await getContentCardUI(homeSurface)
        }
    }
        
    @Test("when multiple cards downloaded")
    func multipleCards() async throws {
        // setup
        setContentCardResponse(fromFile: "MultipleCards")
        
        // test
        let cards = try await getContentCardUI(homeSurface)
        
        // verify
        #expect(cards.count == 4)
    }
    
    @Test("for invalid surface")
    func invalidSurface() async throws {
        // setup
        setContentCardResponse(fromFile: "SmallImageCard")

        // test and verify
        await #expect(throws: ContentCardUIError.dataUnavailable) {
            try await getContentCardUI(invalidSurface)
        }
    }
}

/// Covers `getInboxUI(for:usePersistedContentCards:...)`'s disk-only read branch, which had zero
/// test coverage prior to this suite: it must never contact the network, must read the inbox
/// container-item + content cards back from the persisted disk cache when data exists, and must
/// reach an error state (not hang) when nothing has ever been persisted for the surface.
@Suite("GetInboxUIPersisted", .serialized)
class GetInboxUIPersistedTest: IntegrationTestBase {

    let inboxSurface = Surface(path: "inboxPersistedTest")
    let neverPersistedInboxSurface = Surface(path: "neverPersistedInboxTest")

    override init() {
        super.init()
    }

    @Test("persisted read serves inbox + content card from disk without contacting the network")
    func offlineReadServesFromDiskWithoutNetworkCall() async throws {
        // setup: seed disk with an inbox container-item + one content card for the surface via
        // a normal successful network update, waiting on the real completion handler (not a sleep).
        setInboxResponse(surface: inboxSurface)
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            Messaging.updatePropositionsForSurfacesWithCompletionHandler([inboxSurface]) { _ in
                continuation.resume()
            }
        }

        // Remove all mocked responses and snapshot the network call count. If the persisted-only
        // read below contacts the network at all, there is no resolver to answer it, and the
        // request-count assertion after would fail.
        mockNetwork.clear()
        let requestCountBeforePersistedRead = mockNetwork.edgeRequests.count

        let listener = TestInboxListener()
        let inbox = Messaging.getInboxUI(for: inboxSurface, usePersistedContentCards: true, listener: listener)
        await listener.waitForCompletion()

        // verify: no network call was made for the persisted-only read
        #expect(mockNetwork.edgeRequests.count == requestCountBeforePersistedRead,
               "usePersistedContentCards: true must not contact the network")

        // verify: content was actually read back from disk
        #expect(listener.onSuccessCallCount == 1)
        #expect(listener.onErrorCallCount == 0)
        #expect(inbox.inboxSchemaData != nil, "Inbox container-item should have hydrated from disk")
        if case .loaded(let cards) = inbox.state {
            #expect(cards.count == 1, "Expected exactly one content card hydrated from disk")
        } else {
            Issue.record("Expected InboxUI state to be .loaded, got \(inbox.state)")
        }
    }

    @Test("persisted read with nothing on disk reaches an error state without contacting the network")
    func offlineReadWithNoDiskDataReachesErrorState() async throws {
        // Nothing has ever been persisted for this surface, and no network mock is configured —
        // if the code incorrectly attempted a network call here, it would still get no response
        // and the test would time out, which the request-count assertion below also protects against.
        mockNetwork.clear()
        let requestCountBefore = mockNetwork.edgeRequests.count

        let listener = TestInboxListener()
        let inbox = Messaging.getInboxUI(for: neverPersistedInboxSurface, usePersistedContentCards: true, listener: listener)
        await listener.waitForCompletion()

        #expect(mockNetwork.edgeRequests.count == requestCountBefore,
               "usePersistedContentCards: true must not contact the network even on a disk miss")
        #expect(listener.onErrorCallCount == 1)
        #expect(listener.onSuccessCallCount == 0)
        if case .error = inbox.state {
            // expected
        } else {
            Issue.record("Expected InboxUI state to be .error, got \(inbox.state)")
        }
    }

    // MARK: - Helpers

    /// A minimal `InboxEventListening` spy that lets a test `await` the async completion
    /// (`onSuccess`/`onError`) of an `InboxUI` refresh, race-safe against completion firing
    /// before `waitForCompletion()` is called.
    private class TestInboxListener: InboxEventListening {
        private let lock = NSLock()
        private var didComplete = false
        private var pendingContinuation: CheckedContinuation<Void, Never>?

        var onSuccessCallCount = 0
        var onErrorCallCount = 0
        var lastError: Error?

        func onLoading(_ inbox: InboxUI) {}

        func onSuccess(_ inbox: InboxUI) {
            lock.lock()
            onSuccessCallCount += 1
            didComplete = true
            let continuation = pendingContinuation
            pendingContinuation = nil
            lock.unlock()
            continuation?.resume()
        }

        func onError(_ inbox: InboxUI, _ error: Error) {
            lock.lock()
            onErrorCallCount += 1
            lastError = error
            didComplete = true
            let continuation = pendingContinuation
            pendingContinuation = nil
            lock.unlock()
            continuation?.resume()
        }

        func onCardDismissed(_ card: ContentCardUI) {}
        func onCardDisplayed(_ card: ContentCardUI) {}
        func onCardInteracted(_ card: ContentCardUI, _ interactionId: String, actionURL: URL?) -> Bool { false }
        func onCardCreated(_ card: ContentCardUI) {}

        func waitForCompletion() async {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                lock.lock()
                if didComplete {
                    lock.unlock()
                    continuation.resume()
                    return
                }
                pendingContinuation = continuation
                lock.unlock()
            }
        }
    }

    /// Mocks an Edge personalization response containing both an inbox container-item
    /// (schema: message/inbox) and one content-card ruleset proposition, both scoped to `surface`.
    private func setInboxResponse(surface: Surface) {
        let scope = surface.uri
        let json = """
        {
          "requestId": "INBOX-PERSISTED-TEST-REQUEST-ID",
          "handle": [
            {
              "type": "personalization:decisions",
              "eventIndex": 0,
              "payload": [
                {
                  "id": "inbox-container-1",
                  "scope": "\(scope)",
                  "scopeDetails": {
                    "decisionProvider": "AJO",
                    "correlationID": "inbox-corr-1",
                    "activity": {
                      "id": "inbox-activity-1",
                      "matchedSurfaces": ["\(scope)"]
                    }
                  },
                  "items": [
                    {
                      "id": "inbox-item-1",
                      "schema": "https://ns.adobe.com/personalization/message/inbox",
                      "data": {
                        "content": {
                          "heading": {"content": "My Inbox"},
                          "layout": {"orientation": "vertical"},
                          "capacity": 10,
                          "emptyStateSettings": {"message": {"content": "No messages"}},
                          "isUnreadEnabled": true
                        }
                      }
                    }
                  ]
                },
                {
                  "id": "inbox-card-1",
                  "scope": "\(scope)",
                  "scopeDetails": {
                    "decisionProvider": "AJO",
                    "correlationID": "inbox-card-corr-1",
                    "activity": {
                      "id": "inbox-card-activity-1",
                      "matchedSurfaces": ["\(scope)"]
                    }
                  },
                  "items": [
                    {
                      "id": "inbox-card-item-1",
                      "schema": "https://ns.adobe.com/personalization/ruleset-item",
                      "data": {
                        "version": 1,
                        "rules": [
                          {
                            "condition": {
                              "definition": {
                                "conditions": [
                                  {"definition": {"key": "~timestampu", "matcher": "lt", "values": [2019715200]}, "type": "matcher"}
                                ],
                                "logic": "and"
                              },
                              "type": "group"
                            },
                            "consequences": [
                              {
                                "id": "inbox-card-consequence-1",
                                "type": "schema",
                                "detail": {
                                  "id": "inbox-card-consequence-1",
                                  "schema": "https://ns.adobe.com/personalization/message/content-card",
                                  "data": {
                                    "content": {
                                      "actionUrl": "",
                                      "body": {"content": "Test inbox card body"},
                                      "buttons": [],
                                      "image": {"alt": "", "url": "", "darkUrl": ""},
                                      "dismissBtn": {"style": "none"},
                                      "title": {"content": "Test inbox card title"}
                                    },
                                    "contentType": "application/json",
                                    "meta": {
                                      "adobe": {"template": "SmallImage"},
                                      "surface": "\(scope)"
                                    },
                                    "publishedDate": 1727206898,
                                    "expiryDate": 2019715200
                                  }
                                }
                              }
                            ]
                          }
                        ]
                      }
                    }
                  ]
                }
              ]
            }
          ]
        }
        """
        mockNetwork.mock { request in
            guard request.url.absoluteString.starts(with: "https://adobe.dc.net/ee/v1/interact"),
                  let requestData = try? JSONSerialization.jsonObject(with: request.connectPayload, options: []) as? [String: Any],
                  let surfaces = self.mockNetwork.getSurfacesFromNetworkRequest(requestData),
                  surfaces.contains(scope) else {
                return nil
            }
            return json.data(using: .utf8)
        }
    }
}

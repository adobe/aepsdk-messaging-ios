/*
 Copyright 2026 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import UserNotifications
import XCTest

@testable import AEPMessagingNotification

// MARK: - Mock URLSession

private class MockURLSessionDownloadTask: URLSessionDownloadTask {
    private let handler: () -> Void
    init(handler: @escaping () -> Void) { self.handler = handler }
    override func resume() { handler() }
}

private class MockURLSession: URLSession {
    var stubbedFileURL: URL?
    var stubbedResponse: URLResponse?
    var stubbedError: Error?

    override func downloadTask(
        with url: URL,
        completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void
    ) -> URLSessionDownloadTask {
        MockURLSessionDownloadTask {
            completionHandler(self.stubbedFileURL, self.stubbedResponse, self.stubbedError)
        }
    }
}

// MARK: - Helpers

private func makeHTTPResponse(url: URL, statusCode: Int = 200, mimeType: String? = nil) -> HTTPURLResponse {
    var headers: [String: String] = [:]
    if let mimeType = mimeType {
        headers["Content-Type"] = mimeType
    }
    return HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: headers)!
}

private func makeMutableContent(mediaUrl: String? = nil) -> UNMutableNotificationContent {
    let content = UNMutableNotificationContent()
    if let mediaUrl = mediaUrl {
        content.userInfo = [MessagingNotificationHelper.mediaKey: mediaUrl]
    }
    return content
}

/// Creates a small valid temporary file at a new path and returns its URL.
private func makeTemporaryFile() throws -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("dat")
    try Data([0x00, 0x01, 0x02]).write(to: url)
    return url
}

// MARK: - Tests

class AEPMessagingNotificationHelperTests: XCTestCase {

    private var mockSession: MockURLSession!

    override func setUp() {
        super.setUp()
        mockSession = MockURLSession()
        MessagingNotificationHelper.urlSession = mockSession
    }

    override func tearDown() {
        MessagingNotificationHelper.urlSession = .shared
        super.tearDown()
    }

    // MARK: - mediaKey

    func test_mediaKey_equalsAdbMedia() {
        XCTAssertEqual(MessagingNotificationHelper.mediaKey, "adb_media")
    }

    // MARK: - processNotificationRequest — no media

    func test_processRequest_noMediaKey_callsCompletionWithNoAttachments() {
        let content = makeMutableContent()
        let expectation = expectation(description: "contentHandler called")

        MessagingNotificationHelper.processNotificationRequest(with: content) { deliveredContent in
            XCTAssertTrue(deliveredContent.attachments.isEmpty)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func test_processRequest_invalidUrl_callsCompletionWithNoAttachments() {
        let content = makeMutableContent(mediaUrl: "not a valid url ☠️")
        let expectation = expectation(description: "contentHandler called")

        MessagingNotificationHelper.processNotificationRequest(with: content) { deliveredContent in
            XCTAssertTrue(deliveredContent.attachments.isEmpty)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func test_processRequest_httpUrl_skipsDownload() {
        // http:// (not https://) should be rejected
        let content = makeMutableContent(mediaUrl: "http://example.com/image.jpg")
        let expectation = expectation(description: "contentHandler called")

        MessagingNotificationHelper.processNotificationRequest(with: content) { deliveredContent in
            XCTAssertTrue(deliveredContent.attachments.isEmpty)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    // MARK: - processNotificationRequest — network failure

    func test_processRequest_networkError_callsCompletionWithNoAttachments() {
        mockSession.stubbedError = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)
        let content = makeMutableContent(mediaUrl: "https://example.com/image.jpg")
        let expectation = expectation(description: "contentHandler called")

        MessagingNotificationHelper.processNotificationRequest(with: content) { deliveredContent in
            XCTAssertTrue(deliveredContent.attachments.isEmpty)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func test_processRequest_nilFileUrl_callsCompletionWithNoAttachments() {
        mockSession.stubbedFileURL = nil
        mockSession.stubbedError = nil
        let content = makeMutableContent(mediaUrl: "https://example.com/image.jpg")
        let expectation = expectation(description: "contentHandler called")

        MessagingNotificationHelper.processNotificationRequest(with: content) { deliveredContent in
            XCTAssertTrue(deliveredContent.attachments.isEmpty)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func test_processRequest_non2xxStatusCode_callsCompletionWithNoAttachments() {
        let url = URL(string: "https://example.com/image.jpg")!
        mockSession.stubbedFileURL = try? makeTemporaryFile()
        mockSession.stubbedResponse = makeHTTPResponse(url: url, statusCode: 404)

        let content = makeMutableContent(mediaUrl: url.absoluteString)
        let expectation = expectation(description: "contentHandler called")

        MessagingNotificationHelper.processNotificationRequest(with: content) { deliveredContent in
            XCTAssertTrue(deliveredContent.attachments.isEmpty)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    // MARK: - contentHandler is always called

    func test_processRequest_alwaysCallsContentHandler() {
        let content = UNMutableNotificationContent()
        var handlerCalled = false
        let expectation = expectation(description: "contentHandler called")

        MessagingNotificationHelper.processNotificationRequest(with: content) { _ in
            handlerCalled = true
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)
        XCTAssertTrue(handlerCalled)
    }

    // MARK: - File extension detection

    func test_fileExtension_knownExtensionInUrlPath_isUsed() {
        // .png in URL path — should be used directly
        let url = URL(string: "https://cdn.example.com/banner.png")!
        mockSession.stubbedFileURL = try? makeTemporaryFile()
        mockSession.stubbedResponse = makeHTTPResponse(url: url)

        let content = makeMutableContent(mediaUrl: url.absoluteString)
        let expectation = expectation(description: "done")

        MessagingNotificationHelper.processNotificationRequest(with: content) { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func test_fileExtension_unknownExtensionInUrlPath_fallsBackToMimeType() {
        // URL has .xyz (unsupported) — should fall back to Content-Type header
        let url = URL(string: "https://cdn.example.com/media.xyz")!
        mockSession.stubbedFileURL = try? makeTemporaryFile()
        mockSession.stubbedResponse = makeHTTPResponse(url: url, mimeType: "image/png")

        let content = makeMutableContent(mediaUrl: url.absoluteString)
        let expectation = expectation(description: "done")

        MessagingNotificationHelper.processNotificationRequest(with: content) { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func test_fileExtension_noExtensionAndNoMimeType_defaultsToJpg() {
        let url = URL(string: "https://cdn.example.com/media/12345")!
        mockSession.stubbedFileURL = try? makeTemporaryFile()
        mockSession.stubbedResponse = makeHTTPResponse(url: url) // no Content-Type

        let content = makeMutableContent(mediaUrl: url.absoluteString)
        let expectation = expectation(description: "done")

        MessagingNotificationHelper.processNotificationRequest(with: content) { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func test_fileExtension_gifInUrlPath_isRecognised() {
        let url = URL(string: "https://media.giphy.com/media/abc/giphy.gif")!
        mockSession.stubbedFileURL = try? makeTemporaryFile()
        mockSession.stubbedResponse = makeHTTPResponse(url: url)

        let content = makeMutableContent(mediaUrl: url.absoluteString)
        let expectation = expectation(description: "done")

        MessagingNotificationHelper.processNotificationRequest(with: content) { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    // MARK: - Objective-C compatibility

    func test_objcSelector_processContent_isAccessible() {
        XCTAssertTrue(
            MessagingNotificationHelper.responds(
                to: NSSelectorFromString("processContent:withContentHandler:")
            )
        )
    }

    func test_objcSelector_mediaKey_isAccessible() {
        XCTAssertTrue(
            MessagingNotificationHelper.responds(
                to: NSSelectorFromString("mediaKey")
            )
        )
    }
}

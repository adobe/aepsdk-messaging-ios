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

import AEPServices
import Foundation

typealias NetworkResponseData = Data?
typealias RequestResolver = (NetworkRequest) -> NetworkResponseData?
typealias RequestListener = (NetworkRequest) -> Void

class MockNetworkService: Networking {
    
    var EDGE_URL = "https://adobe.dc.net/ee/v1/interact"
    var listener: RequestListener?
    var edgeRequests: [NetworkRequest] = []
    var resolvers: [RequestResolver] = []
    
    let validResponse = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
    
    func connectAsync(networkRequest: AEPServices.NetworkRequest, completionHandler: ((AEPServices.HttpConnection) -> Void)?) {
        /// Collect and mock only edge requests
        if !networkRequest.url.absoluteString.starts(with: EDGE_URL) {
            completionHandler?(HttpConnection(data: nil, response: validResponse, error: nil))
            return
        }
        
        edgeRequests.append(networkRequest)
        listener?(networkRequest)
        for resolver in resolvers {
            if let response = resolver(networkRequest) {
                completionHandler?(HttpConnection(data: response, response: validResponse, error: nil))
                return
            }
        }
        
        completionHandler?(HttpConnection(data: nil, response: validResponse, error: nil))
    }
    
    func mock(resolver: @escaping RequestResolver) {
        resolvers += [resolver]
    }
    
    func onEdgeNetworkRequest(listener: @escaping RequestListener) {
        self.listener = listener
    }
    
    func getEdgeRequestsWith(eventType: String) -> [NetworkRequest] {
        var filteredRequest: [NetworkRequest] = []
        
        for request in edgeRequests {
            if let payloadDict = try? JSONSerialization.jsonObject(with: request.connectPayload, options: []) as? [String: Any] {
                if let events = payloadDict["events"] as? [[String: Any]] {
                    for event in events {
                        if let xdm = event["xdm"] as? [String: Any],
                           let eventTypeValue = xdm["eventType"] as? String {
                            if eventTypeValue == eventType {
                                filteredRequest.append(request)
                            }
                        }
                    }
                }
            }
        }
        return filteredRequest
    }
    
    func getSurfacesFromNetworkRequest(_ requestData : [String: Any]) -> [String]? {
        if let eventsArray = requestData["events"] as? [[String: Any]],
           let firstEvent = eventsArray.first,
           let query = firstEvent["query"] as? [String: Any],
           let personalization = query["personalization"] as? [String: Any],
           let surfaces = personalization["surfaces"] as? [String] {
            return surfaces
        }
        return nil
    }
    
    func clear() {
        edgeRequests = []
        resolvers = []
        listener = nil
    }
}

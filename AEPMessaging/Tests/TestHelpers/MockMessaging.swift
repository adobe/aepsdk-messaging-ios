/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

@testable import AEPCore
@testable import AEPMessaging
import Foundation

class MockMessaging: Messaging {
    public var testableRuntime = TestableExtensionRuntime()

    required init?(runtime _: ExtensionRuntime) {
        super.init(runtime: testableRuntime)
    }
    
    var parsePropositionsCalled = false
    var paramParsePropositionsPropositions: [Proposition]?
    var paramParsePropositionsExpectedSurfaces: [Surface]?
    var paramParsePropositionsClearExisting: Bool?
    var paramParsePropositionsPersistChanges: Bool?
    var parsePropositionsReturnValue: [InboundType: [LaunchRule]]?
    override func parsePropositions(_ propositions: [Proposition]?, expectedSurfaces: [Surface], clearExisting: Bool, persistChanges: Bool = true) -> [InboundType: [LaunchRule]] {
        parsePropositionsCalled = true
        paramParsePropositionsPropositions = propositions
        paramParsePropositionsExpectedSurfaces = expectedSurfaces
        paramParsePropositionsClearExisting = clearExisting
        paramParsePropositionsPersistChanges = persistChanges
        return parsePropositionsReturnValue ?? [:]
    }

    var paramEventType: MessagingEdgeEventType?
    var paramInteraction: String?
    var paramMessage: Message?    
    var sendPropositionInteractionCalled = false
    
    var propositionInfoForMessageIdCalled = false
    var propositionInfoForMessageIdReturnValue: PropositionInfo?
    override func propositionInfoForMessageId(_ messageId: String) -> PropositionInfo? {
        propositionInfoForMessageIdCalled = true
        return propositionInfoForMessageIdReturnValue
    }
}

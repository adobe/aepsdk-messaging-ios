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

import Foundation
import AEPCore
import AEPServices
@_implementationOnly import AEPRulesEngine

class MessagingRulesEngine {
    private let debugging = false
    
    private let LOG_TAG = "Messaging Rules Engine"
    private static let LAUNCH_RULE_TOKEN_LEFT_DELIMITER = "{%"
    private static let LAUNCH_RULE_TOKEN_RIGHT_DELIMITER = "%}"
    private static let CONSEQUENCE_EVENT_NAME = "Rules Consequence Event"
    
    private let name: String
    private let transformer: Transforming
    private let extensionRuntime: ExtensionRuntime
    private let queue = DispatchQueue(label: MessagingConstants.RULES_ENGINE_NAME + ".processor")
    private var waitingEvents: [Event]?
    
    let evaluator: ConditionEvaluator
    let rulesEngine: RulesEngine<MessagingRule>
    
    init(name: String, extensionRuntime: ExtensionRuntime) {
        self.name = name
        self.transformer = Transformer()
        self.extensionRuntime = extensionRuntime
        self.evaluator = ConditionEvaluator(options: .caseInsensitive)
        
        // TODO: revisit once we figure out if we need a transformer
        self.rulesEngine = RulesEngine(evaluator: self.evaluator, transformer:self.transformer)
        
        if debugging {
            // TODO: enable logging
        }
    }
    
    /// if we have rules loaded, then we simply process the event.
    /// if rules are not yet loaded, add the event to the waitingEvents array to
    func process(event: Event) {
        queue.sync {
            // if our waitingEvents array is nil, we know we have rules registered and can skip to evaluation
            guard var waitingEvents = waitingEvents else {
                evaluateRules(for: event)
                return
            }
            
            // check if this is an event to kick processing of waitingEvents
            // otherwise, add the event to waitingEvents
            if event.name == name, event.source == EventSource.requestReset, event.type == EventType.rulesEngine {
                for currentEvent in waitingEvents {
                    evaluateRules(for: currentEvent)
                }
                self.waitingEvents = nil
            } else {
                waitingEvents.append(event)
            }
                        
            evaluateRules(for: event)
        }
    }
    
    func loadRules(rules: [String]?) {
        queue.sync {
            guard let rules = rules else {
                Log.trace(label: LOG_TAG, "loadRules was called with an empty array of rules.")
                return
            }
            
            var messagingRules: [MessagingRule] = []
            for rule in rules {
                
                guard let processedRule = JSONRulesParser.parse(rule) else {
                    continue
                }
                
                messagingRules.append(contentsOf: processedRule)
            }
            
            rulesEngine.addRules(rules: messagingRules)
            Log.trace(label: LOG_TAG, "Successfully loaded \(messagingRules.count) message(s) into the rules engine.")
        }
    }
    
    private func evaluateRules(for event: Event) {
        let tokenFinder = TokenFinder(event: event, extensionRuntime: extensionRuntime)
        
        // get an array of matched rules
        let matchedRules = rulesEngine.evaluate(data: tokenFinder)
                
        for matchedRule in matchedRules {
            for consequence in matchedRule.consequences {
                let finalConsequence = replaceToken(for: consequence, data: tokenFinder)
                if let consequenceEvent = generateConsequenceEvent(consequence: finalConsequence) {
                    Log.trace(label: LOG_TAG, "Generating consequence event: \(consequenceEvent)")
                    extensionRuntime.dispatch(event: consequenceEvent)
                }
            }
        }
    }
    
    /// Replace tokens inside the provided consequence with the right value
    /// - Parameters:
    ///   - consequence: the `Consequence` instance may contain tokens
    ///   - data: a `Traversable` collection with tokens and related values
    /// - Returns: a new instance of `Consequence`
    func replaceToken(for consequence: MessagingConsequence, data: Traversable) -> MessagingConsequence {
        let dict = replaceToken(in: consequence.details, data: data)
        return MessagingConsequence(id: consequence.id, type: consequence.type, details: dict)
    }
    
    private func replaceToken(in dict: [String: Any?], data: Traversable) -> [String: Any?] {
        var mutableDict = dict
        for (key, value) in mutableDict {
            switch value {
            case is String:
                mutableDict[key] = replaceToken(for: value as! String, data: data)
            case is [String: Any]:
                let valueDict = mutableDict[key] as! [String: Any]
                mutableDict[key] = replaceToken(in: valueDict, data: data)
            default:
                break
            }
        }
        return mutableDict
    }
    
    private func replaceToken(for value: String, data: Traversable) -> String {
        let template = Template(templateString: value, tagDelimiterPair: (MessagingRulesEngine.LAUNCH_RULE_TOKEN_LEFT_DELIMITER, MessagingRulesEngine.LAUNCH_RULE_TOKEN_RIGHT_DELIMITER))
        return template.render(data: data, transformers: transformer)
    }
    
    private func sendReprocessEventsRequest() {
        extensionRuntime.dispatch(event: Event(name: name, type: EventType.rulesEngine, source: EventSource.requestReset, data: nil))
    }
    
    /// Generate a consequence event with provided consequence data
    /// - Parameter consequence: a consequence of the rule
    /// - Returns: a consequence `Event`
    private func generateConsequenceEvent(consequence: MessagingConsequence) -> Event? {
        var consequenceEventData: [String: Any] = [:]
        consequenceEventData[MessagingConstants.EventDataKeys.DETAIL] = consequence.details
        consequenceEventData[MessagingConstants.EventDataKeys.ID] = consequence.id
        consequenceEventData[MessagingConstants.EventDataKeys.TYPE] = consequence.type
        return Event(name: MessagingRulesEngine.CONSEQUENCE_EVENT_NAME,
                     type: EventType.rulesEngine,
                     source: EventSource.responseContent,
                     data: [MessagingConstants.EventDataKeys.TRIGGERED_CONSEQUENCE: consequenceEventData])
    }
}

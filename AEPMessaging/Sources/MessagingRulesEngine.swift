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

import AEPCore
import AEPServices
import Foundation

/// Wrapper class around `LaunchRulesEngine` that provides a different implementation for loading rules
class MessagingRulesEngine {
    let rulesEngine: LaunchRulesEngine
    let runtime: ExtensionRuntime
    let cache: Cache
    let messagingCacheName = "com.adobe.messaging.cache"
    let cachedMessagesName = "messages"
    let cachedMessagesDelimiter = "||"

    /// Initialize this class, creating a new rules engine with the provided name and runtime
    init(name: String, extensionRuntime: ExtensionRuntime) {
        runtime = extensionRuntime
        rulesEngine = LaunchRulesEngine(name: name,
                                        extensionRuntime: extensionRuntime)
        cache = Cache(name: messagingCacheName)
        loadCachedMessages()
    }
    
    /// INTERNAL ONLY
    /// Initializer to provide a mock rules engine for testing
    init(extensionRuntime: ExtensionRuntime, rulesEngine: LaunchRulesEngine, cache: Cache) {
        self.runtime = extensionRuntime
        self.rulesEngine = rulesEngine
        self.cache = cache
    }

    /// if we have rules loaded, then we simply process the event.
    /// if rules are not yet loaded, add the event to the waitingEvents array to
    func process(event: Event) {
        _ = rulesEngine.process(event: event)
    }

    func loadRules(rules: [String]?) {
        guard let rules = rules else {
            Log.debug(label: MessagingConstants.LOG_TAG, "Unable to load messages, array of rules was empty.")
            return
        }

//        let rules = [self.tempRule]
        
        var messagingRules: [LaunchRule] = []
        for rule in rules {
            guard let processedRule = JSONRulesParser.parse(rule.data(using: .utf8) ?? Data(), runtime: runtime) else {
                continue
            }

            messagingRules.append(contentsOf: processedRule)
        }
        
        rulesEngine.replaceRules(with: messagingRules)
        Log.debug(label: MessagingConstants.LOG_TAG, "Successfully loaded \(messagingRules.count) message(s) into the rules engine.")
    }
    
    
    
    let tempRule = """
{"version":1,"rules":[
{"condition":{
    "type":"group",
    "definition":{
        "conditions":[
            {
                "definition":{
                    "key":"seahawks",
                    "matcher":"eq",
                    "values":["sad"]
                },
                "type":"matcher"
            }
        ],"logic":"and"}
    },
    "consequences":[{"id":"5fd06050-48c5-42a1-b71a-f5e2ee88a17d","type":"cjmiam","detail":{"mobileParameters":{"schemaVersion":"0.0.1","width":95,"height":17,"verticalAlign":"top","verticalInset":2,"horizontalAlign":"center","horizontalInset":0,"uiTakeover":false,"displayAnimation":"top","dismissAnimation":"top","gestures":{"swipeDown":"adbinapp://dismiss?interaction=swipeDown","swipeUp":"adbinapp://dismiss?interaction=swipeUp","swipeLeft":"adbinapp://dismiss?interaction=swipeLeft","swipeRight":"adbinapp://dismiss?interaction=swipeRight"}},
"html":"\(messageHtmlPt2)",
"_xdm":{"mixins":{"_experience":{"customerJourneyManagement":{"messageExecution":{"messageExecutionID":"UIA-11141958","messageID":"9fca03a7-c202-44ce-92b8-94a3f2645699","messagePublicationID":"2ca09a84-fc86-4035-a5f7-72692ff2ba34","ajoCampaignID":"5ba49bd9-b40c-4a32-90a9-4dbf7bea13e4","ajoCampaignVersionID":"1e612ce7-77a2-4f83-810b-d44b0cc1ac4b"},"messageProfile":{"channel":{"_id":"https://ns.adobe.com/xdm/channels/inapp"}}}}}}}}]}]}
"""
    
    static let messageHtml = """
<html><head><meta name=\\\"viewport\\\" content=\\\"width=device-width, initial-scale=1.0\\\"><style type=\\\"text/css\\\" id=\\\"editor-styles\\\"></style><style>html,body {margin: 0;padding: 0;text-align: center;width: 100%;height: 100%;font-family: adobe-clean, \\\"Source Sans Pro\\\", -apple-system, BlinkMacSystemFont, \\\"Segoe UI\\\", Roboto, sans-serif;}h3 {margin: .1rem auto;}p {margin: 0;}a {text-decoration: none;}.wrapper {background-color: #FFF;border-radius: .3125rem;color: #333333;width: 100%;min-height: 100%;display: flex;justify-content: center;flex-direction: column;position: relative;background-size: 'cover';}.content {height: 100vh;width: 100vw;display: flex;flex-direction: column;}.text {text-align: left;line-height: 1.25rem;font-size: 0.875rem;color: #333333;letter-spacing: 0;}.text:first-child {line-height: 1.3125rem;font-size: 1.025rem;}.btnClose {color: #000000;}.closeBtn {align-self: flex-start;}.image {height: 100%;width: auto;padding-right: .8rem; flex-direction: column; align-items: center;} .image img { max-height: 100%; max-width: 100%; }.body {flex-grow: 1;width: 100%;height: 1rem;display: flex;flex-direction: row;padding: .8rem;box-sizing: border-box;align-items: center;            justify-content: space-between;}.buttons {width: 100%;display: flex;flex-direction: column;font-size: 1rem;line-height: 1.3rem;text-decoration: none;text-align: center;box-sizing: border-box;padding: .8rem;padding-top: .4rem;}.button {flex-grow: 1;background-color: #1473E6;color: #FFFFFF;border-radius: .25rem;cursor: pointer;padding: .3rem;gap: .5rem;}</style></head><body><div class=\\\"wrapper\\\"><div class=\\\"content\\\"><div class=\\\"body\\\">        <div class=\\\"image\\\" data-uuid=\\\"46514c31-b883-4d1f-8f97-26f054309646\\\"><img src=\\\"https://yt3.ggpht.com/ZZwSBzlSCtokM14hjQTU7S_pJ2W8uUeLa0SU2q3NMZfo14nwTAGlTabCQ5UhCD44P6UCyJ69lWQ=s900-c-k-c0x00ffffff-no-rj\\\" alt=\\\"\\\"></div><div class=\\\"text\\\" data-uuid=\\\"0dd40275-c264-4ff0-9b75-01a240016df7\\\"><h3>Welcome to SFO!</h3><p>You're checked in! After TSA check, head straight to your gates.</p></div><div class=\\\"closeBtn\\\" data-btn-style=\\\"plain\\\" data-uuid=\\\"3de6f6ef-f98b-4981-9530-b3c47ae6984d\\\">  <a class=\\\"btnClose\\\" href=\\\"adbinapp://dismiss?interaction=cancel\\\">    <svg xmlns=\\\"http://www.w3.org/2000/svg\\\" height=\\\"18\\\" viewbox=\\\"0 0 18 18\\\" width=\\\"18\\\" class=\\\"close\\\">  <rect id=\\\"Canvas\\\" fill=\\\"#ffffff\\\" opacity=\\\"0\\\" width=\\\"18\\\" height=\\\"18\\\" />  <path fill=\\\"currentColor\\\" xmlns=\\\"http://www.w3.org/2000/svg\\\" d=\\\"M13.2425,3.343,9,7.586,4.7575,3.343a.5.5,0,0,0-.707,0L3.343,4.05a.5.5,0,0,0,0,.707L7.586,9,3.343,13.2425a.5.5,0,0,0,0,.707l.707.7075a.5.5,0,0,0,.707,0L9,10.414l4.2425,4.243a.5.5,0,0,0,.707,0l.7075-.707a.5.5,0,0,0,0-.707L10.414,9l4.243-4.2425a.5.5,0,0,0,0-.707L13.95,3.343a.5.5,0,0,0-.70711-.00039Z\\\" /></svg>  </a></div></div></div></div></body></html>
"""
    
    static let messageHtmlPt2 = """
<html><head><meta name=\\\"viewport\\\" content="width=device-width, initial-scale=1.0"><style type="text/css" id="editor-styles"></style><style>
    html,body {
        margin: 0;
        padding: 0;
        text-align: center;
        width: 100%;
        height: 100%;
        font-family: adobe-clean, "Source Sans Pro", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    }
    h3 {
        margin: .1rem auto;
    }
    p {
        margin: 0;
    }
    a {
        text-decoration: none;
    }
    .wrapper {
        background-color: #FFF;
        border-radius: .3125rem;
        color: #333333;
        width: 100%;
        min-height: 100%;
        display: flex;
        justify-content: center;
        flex-direction: column;
        position: relative;
        background-size: 'cover';
    }
    .content {
        height: 100vh;
        width: 100vw;
        display: flex;
        flex-direction: column;
    }
    .text {
        text-align: left;
        line-height: 1.25rem;
        font-size: 0.875rem;
        color: #333333;
        letter-spacing: 0;
    }
    .text:first-child {
        line-height: 1.3125rem;
        font-size: 1.025rem;
    }
    .btnClose {
        color: #000000;
    }
    .closeBtn {
        align-self: flex-start;
    }
    .image {
        height: 100%;
        width: auto;
        padding-right: .8rem;
        flex-direction: column;
        align-items: center;
    }
    .image img {
        max-height: 100%;
        max-width: 100%;
    }
    .body {
        flex-grow: 1;
        width: 100%;
        height: 1rem;
        display: flex;
        flex-direction: row;
        padding: .8rem;
        box-sizing: border-box;
        align-items: center;
        justify-content: space-between;
    }
    .buttons {
        width: 100%;
        display: flex;
        flex-direction: column;
        font-size: 1rem;
        line-height: 1.3rem;
        text-decoration: none;
        text-align: center;
        box-sizing: border-box;
        padding: .8rem;
        padding-top: .4rem;
    }
    .button {
        flex-grow: 1;
        background-color: #1473E6;
        color: #FFFFFF;
        border-radius: .25rem;
        cursor: pointer;
        padding: .3rem;
        gap: .5rem;
    }
    </style>
</head>
<body>
    <div class="wrapper">
        <div class="content">
            <div class="body">
                <div class="image" data-uuid="46514c31-b883-4d1f-8f97-26f054309646">
                    <img src="https://yt3.ggpht.com/ZZwSBzlSCtokM14hjQTU7S_pJ2W8uUeLa0SU2q3NMZfo14nwTAGlTabCQ5UhCD44P6UCyJ69lWQ=s900-c-k-c0x00ffffff-no-rj" undefined undefined alt="">
                </div>
                <div class="text" data-uuid="0dd40275-c264-4ff0-9b75-01a240016df7">
                    <h3>Welcome to SFO!</h3>
                    <p>You're checked in! After TSA check, head straight to your gates.</p>
                </div>
                <div class="closeBtn" data-btn-style="plain" data-uuid="3de6f6ef-f98b-4981-9530-b3c47ae6984d">
                    <a class="btnClose" href="adbinapp://dismiss?interaction=cancel">
                        <svg xmlns="http://www.w3.org/2000/svg" height="18" viewbox="0 0 18 18" width="18" class="close">
                            <rect id="Canvas" fill="#ffffff" opacity="0" width="18" height="18" />
                            <path fill="currentColor" xmlns="http://www.w3.org/2000/svg" d="M13.2425,3.343,9,7.586,4.7575,3.343a.5.5,0,0,0-.707,0L3.343,4.05a.5.5,0,0,0,0,.707L7.586,9,3.343,13.2425a.5.5,0,0,0,0,.707l.707.7075a.5.5,0,0,0,.707,0L9,10.414l4.2425,4.243a.5.5,0,0,0,.707,0l.7075-.707a.5.5,0,0,0,0-.707L10.414,9l4.243-4.2425a.5.5,0,0,0,0-.707L13.95,3.343a.5.5,0,0,0-.70711-.00039Z" />
                        </svg>
                    </a>
                </div>
            </div>
        </div>
    </div>
</body>
</html>

"""
}

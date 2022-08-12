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

    /// Initialize this class, creating a new rules engine with the provided name and runtime
    init(name: String, extensionRuntime: ExtensionRuntime) {
        runtime = extensionRuntime
        rulesEngine = LaunchRulesEngine(name: name,
                                        extensionRuntime: extensionRuntime)
        cache = Cache(name: MessagingConstants.Caches.CACHE_NAME)
        loadCachedMessages()
    }

    /// INTERNAL ONLY
    /// Initializer to provide a mock rules engine for testing
    init(extensionRuntime: ExtensionRuntime, rulesEngine: LaunchRulesEngine, cache: Cache) {
        runtime = extensionRuntime
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

        var messagingRules: [LaunchRule] = []
        for rule in rules {
            
//            guard let processedRule = JSONRulesParser.parse(testRule.data(using: .utf8) ?? Data(), runtime: runtime) else {
//                continue
//            }
            
            guard let processedRule = JSONRulesParser.parse(rule.data(using: .utf8) ?? Data(), runtime: runtime) else {
                continue
            }

            // pre-fetch the assets for this message if there are any defined
            cacheRemoteAssetsFor(processedRule)

            messagingRules.append(contentsOf: processedRule)
        }

        rulesEngine.replaceRules(with: messagingRules)
        Log.debug(label: MessagingConstants.LOG_TAG, "Successfully loaded \(messagingRules.count) message(s) into the rules engine.")
    }
    
//    let testRule = """
//{\"version\":1,\"rules\":[{\"condition\":{\"type\":\"group\",\"definition\":{\"logic\":\"and\",\"conditions\":[{\"type\":\"group\",\"definition\":{\"logic\":\"and\",\"conditions\":[{\"type\":\"matcher\",\"definition\":{\"key\":\"~source\",\"matcher\":\"eq\",\"values\":[\"com.adobe.eventSource.requestContent\"]}},{\"type\":\"matcher\",\"definition\":{\"key\":\"~type\",\"matcher\":\"eq\",\"values\":[\"com.adobe.eventType.generic.track\"]}},{\"type\":\"matcher\",\"definition\":{\"key\":\"action\",\"matcher\":\"eq\",\"values\":[\"inbound_test\"]}}]}}]}},\"consequences\":[{\"id\":\"daeff38d-823c-4a40-a814-20c0a1c82ccb\",\"type\":\"cjmiam\",\"detail\":{\"mobileParameters\":{\"verticalAlign\":\"center\",\"dismissAnimation\":\"top\",\"verticalInset\":0,\"backdropOpacity\":0.2,\"cornerRadius\":15,\"gestures\":{\"swipeUp\":\"adbinapp://dismiss?interaction=swipeUp\",\"swipeDown\":\"adbinapp://dismiss?interaction=swipeDown\",\"swipeLeft\":\"adbinapp://dismiss?interaction=swipeLeft\",\"swipeRight\":\"adbinapp://dismiss?interaction=swipeRight\",\"tapBackground\":\"adbinapp://dismiss?interaction=tapBackground\"},\"horizontalInset\":0,\"uiTakeover\":true,\"horizontalAlign\":\"center\",\"width\":80,\"displayAnimation\":\"top\",\"backdropColor\":\"#000000\",\"height\":60},\"html\":\"<html>\\n<head>\\n\\t<meta name=\\\"viewport\\\" content=\\\"width=device-width, initial-scale=1.0\\\">\\n\\t<meta charset=\\\"UTF-8\\\">\\n\\t<style>\\n\\t\\thtml,\\n\\t\\tbody {\\n\\t\\t\\tmargin: 0;\\n\\t\\t\\tpadding: 0;\\n\\t\\t\\ttext-align: center;\\n\\t\\t\\twidth: 100%;\\n\\t\\t\\theight: 100%;\\n\\t\\t\\tfont-family: adobe-clean, \\\"Source Sans Pro\\\", -apple-system, BlinkMacSystemFont, \\\"Segoe UI\\\", Roboto, sans-serif;\\n\\t\\t}\\n\\t\\th3 {\\n\\t\\t\\tmargin: .4rem auto;\\n\\t\\t}\\n\\t\\tp {\\n\\t\\t\\tmargin: .4rem auto;\\n\\t\\t}\\n\\n\\t\\t.body {\\n\\t\\t\\tdisplay: flex;\\n\\t\\t\\tflex-direction: column;\\n\\t\\t\\tbackground-color: #FFF;\\n\\t\\t\\tborder-radius: 0.3rem;\\n\\t\\t\\tcolor: #333333;\\n\\t\\t\\twidth: 100vw;\\n\\t\\t\\theight: 100vh;\\n\\t\\t\\ttext-align: center;\\n\\t\\t\\talign-items: center;\\n\\t\\t\\tbackground-size: \'cover\';\\n\\t\\t}\\n\\n\\t\\t.content {\\n\\t\\t\\twidth: 100%;\\n\\t\\t\\theight: 100%;\\n\\t\\t\\tdisplay: flex;\\n\\t\\t\\tjustify-content: center;\\n\\t\\t\\tflex-direction: column;\\n\\t\\t\\tposition: relative;\\n\\t\\t}\\n\\n\\t\\ta {\\n\\t\\t\\ttext-decoration: none;\\n\\t\\t}\\n\\n\\t\\t.image {\\n\\t\\t  height: 1rem;\\n\\t\\t  flex-grow: 4;\\n\\t\\t  flex-shrink: 1;\\n\\t\\t  display: flex;\\n\\t\\t  justify-content: center;\\n\\t\\t  width: 90%;\\n          flex-direction: column;\\n          align-items: center;\\n        }\\n        .image img {\\n          max-height: 100%;\\n          max-width: 100%;\\n        }\\n\\t\\t.text {\\n\\t\\t\\ttext-align: center;\\n\\t\\t\\tline-height: 1.3rem;\\n\\t\\t\\tfont-size: 0.9rem;\\n\\t\\t\\tcolor: #333333;\\n\\t\\t\\tline-height: 1.25rem;\\n\\t\\t\\tfont-size: 0.875rem;\\n\\t\\t\\tpadding: 0 0.8rem;\\n\\t\\t\\twidth: 100%;\\n\\t\\t\\tbox-sizing: border-box;\\n\\t\\t}\\n\\t\\t.title {\\n\\t\\t\\tline-height: 1.3125rem;\\n\\t\\t\\tfont-size: 1.025rem;\\n\\t\\t}\\n\\n\\t\\t.buttons {\\n\\t\\t\\twidth: 100%;\\n\\t\\t\\tdisplay: flex;\\n\\t\\t\\tflex-direction: column;\\n\\t\\t\\tfont-size: 1rem;\\n\\t\\t\\tline-height: 1.3rem;\\n\\t\\t\\ttext-decoration: none;\\n\\t\\t\\ttext-align: center;\\n\\t\\t\\tbox-sizing: border-box;\\n\\t\\t\\tpadding: .8rem;\\n\\t\\t\\tpadding-top: .4rem;\\n\\t\\t\\tgap: 0.3125rem;\\n\\t\\t}\\n\\n\\t\\t.button {\\n\\t\\t\\tflex-grow: 1;\\n\\t\\t\\tbackground-color: #1473E6;\\n\\t\\t\\tcolor: #FFFFFF;\\n\\t\\t\\tborder-radius: .25rem;\\n\\t\\t\\tcursor: pointer;\\n\\t\\t\\tpadding: .3rem;\\n\\t\\t\\tgap: .5rem;\\n\\t\\t}\\n\\n\\t\\t.btnClose {\\n\\t\\t\\tcolor: #000000;\\n\\t\\t}\\n\\n\\t\\t.closeBtn {\\n\\t\\t\\talign-self: flex-end;\\n\\t\\t\\tcolor: #000000;\\n\\t\\t\\twidth: 1.8rem;\\n\\t\\t\\theight: 1.8rem;\\n\\t\\t\\tmargin-top: 1rem;\\n\\t\\t\\tmargin-right: .3rem;\\n\\t\\t}\\n\\t</style>\\n\\t<style type=\\\"text/css\\\" id=\\\"editor-styles\\\">\\n\\n</style>\\n</head>\\n\\n<body>\\n\\t<div class=\\\"body\\\">\\n    <div class=\\\"closeBtn\\\" data-uuid=\\\"0ffee934-7abe-46e7-9c99-bb1351122545\\\" data-btn-style=\\\"plain\\\"><a aria-label=\\\"Close\\\" class=\\\"btnClose\\\" href=\\\"adbinapp://dismiss?interaction=cancel\\\"><svg xmlns=\\\"http://www.w3.org/2000/svg\\\" height=\\\"18\\\" viewbox=\\\"0 0 18 18\\\" width=\\\"18\\\" class=\\\"close\\\">\\n  <rect id=\\\"Canvas\\\" fill=\\\"#ffffff\\\" opacity=\\\"0\\\" width=\\\"18\\\" height=\\\"18\\\"></rect>\\n  <path fill=\\\"currentColor\\\" xmlns=\\\"http://www.w3.org/2000/svg\\\" d=\\\"M13.2425,3.343,9,7.586,4.7575,3.343a.5.5,0,0,0-.707,0L3.343,4.05a.5.5,0,0,0,0,.707L7.586,9,3.343,13.2425a.5.5,0,0,0,0,.707l.707.7075a.5.5,0,0,0,.707,0L9,10.414l4.2425,4.243a.5.5,0,0,0,.707,0l.7075-.707a.5.5,0,0,0,0-.707L10.414,9l4.243-4.2425a.5.5,0,0,0,0-.707L13.95,3.343a.5.5,0,0,0-.70711-.00039Z\\\"></path>\\n</svg></a></div><div class=\\\"image\\\" data-uuid=\\\"b60bbab4-2704-4bcd-9a83-a8286815837d\\\"><img src=\\\"https://exc-unifiedcontent.experience-stage.adobe.net/solutions/cjm-message-ui/static-assets/inapp/InAppBlockImageDefault.svg\\\" alt=\\\"\\\"></div><div class=\\\"text\\\" data-uuid=\\\"f74895d2-0f15-411b-805a-a63a6c73575f\\\"><h3>this message is from XAS</h3><p>and it\'s full of sass</p></div><div class=\\\"buttons\\\" data-uuid=\\\"f9eeb8f4-3448-402c-b50a-3311bb750b41\\\"><a class=\\\"button\\\" data-uuid=\\\"d242c6ed-9a8b-4180-babf-b1c22be61a88\\\" href=\\\"adbinapp://dismiss?interaction=confirm\\\">yay</a></div>\\n\\t</div>\\n\\n\\n</body></html>\",\"remoteAssets\":[\"https://exc-unifiedcontent.experience-stage.adobe.net/solutions/cjm-message-ui/static-assets/inapp/InAppBlockImageDefault.svg\"]}}]}]}
//"""
}

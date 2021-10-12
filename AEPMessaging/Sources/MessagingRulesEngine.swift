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
@_implementationOnly import AEPRulesEngine
import AEPServices
import Foundation

class MessagingRulesEngine {

    let rulesEngine: LaunchRulesEngine
    let runtime: ExtensionRuntime

    init(name: String, extensionRuntime: ExtensionRuntime) {
        self.runtime = extensionRuntime
        self.rulesEngine = LaunchRulesEngine(name: name,
                                             extensionRuntime: extensionRuntime)
    }

    /// if we have rules loaded, then we simply process the event.
    /// if rules are not yet loaded, add the event to the waitingEvents array to
    func process(event: Event) {
        _ = rulesEngine.process(event: event)
    }

    func loadRules(rules: [String]?) {
//        guard let rules = rules else {
//            Log.debug(label: MessagingConstants.LOG_TAG, "Unable to load messages, array of rules was empty.")
//            return
//        }

        // TEMP
        let rules = [testRuleString, testMultipleRuleString]
        
        var messagingRules: [LaunchRule] = []
        for rule in rules {
            guard let processedRule = JSONRulesParser.parse(rule.data(using: .utf8) ?? Data(), runtime: runtime) else {
                continue
            }

            // TODO: handle remote assets caching (here or in UIServices?)
            messagingRules.append(contentsOf: processedRule)
        }
        
        rulesEngine.replaceRules(with: messagingRules)
        Log.debug(label: MessagingConstants.LOG_TAG, "Successfully loaded \(messagingRules.count) message(s) into the rules engine.")
    }
    
    let testRuleString = """
{
    "version": 1,
    "rules": [
        {
            "condition": {
                "type": "group",
                "definition": {
                    "logic": "and",
                    "conditions": [
                        {
                            "definition": {
                                "key": "contextdata.testSteveModal",
                                "matcher": "eq",
                                "values": [
                                    "true"
                                ]
                            },
                            "type": "matcher"
                        },
                        {
                            "type": "historical",
                            "definition": {
                                "events": [
                                    {
                                        "xdm.eventType": "inapp.display",
                                        "xdm._experience.customerJourneyManagement.messageExecution.messageExecutionID": "sbtest"
                                    }
                                ],
                                "to": 1733599999999,
                                "from": 1633549434045,
                                "searchType": "any",
                                "matcher": "lt",
                                "value": 1
                            }
                        }
                    ]
                }
            },
            "consequences": [
                {
                    "id": "341800180",
                    "type": "cjmiam",
                    "detail": {
                        "remoteAssets": [],
                        "_xdm": {
                            "mixins": {
                                "_experience": {
                                    "customerJourneyManagement": {
                                        "messageExecution": {
                                            "messageExecutionID": "sbtest",
                                            "messageID": "567",
                                            "journeyVersionID": "",
                                            "journeyVersionInstanceId": ""
                                        }
                                    }
                                }
                            }
                        },
                        "mobileParameters": {
                            "schemaVersion": "1.0",
                            "width": 80,
                            "height": 50,
                            "verticalAlign": "center",
                            "verticalInset": 0,
                            "horizontalAlign": "center",
                            "horizontalInset": 0,
                            "uiTakeover": true,
                            "backdropColor": "000000",
                            "backdropOpacity": 0.5,
                            "cornerRadius": 15,
                            "displayAnimation": "left",
                            "dismissAnimation": "right",
                            "gestures": {
                                "swipeRight": "adbinapp://dismiss/?interaction=positive",
                                "swipeLeft": "adbinapp://dismiss/?interaction=negative"
                            }
                        },
                        "html": "\(marinersMessage)",
                        "template": "fullscreen"
                    }
                }
            ]
        }
    ]
}
"""
    
    let testMultipleRuleString = """
{
    "version": 1,
    "rules": [
        {
            "condition": {
                "type": "group",
                "definition": {
                    "logic": "and",
                    "conditions": [
                        {
                            "definition": {
                                "key": "checkSequence",
                                "matcher": "eq",
                                "values": [
                                    "true"
                                ]
                            },
                            "type": "matcher"
                        },
                        {
                            "type": "historical",
                            "definition": {
                                "events": [
                                    {
                                        "firstEvent" : "true"
                                    },
                                    {
                                        "secondEvent" : "true"
                                    },
                                    {
                                        "thirdEvent" : "true"
                                    }
                                ],
                                "to": 1733599999999,
                                "from": 1633549434045,
                                "searchType": "ordered",
                                "matcher": "eq",
                                "value": 1
                            }
                        }
                    ]
                }
            },
            "consequences": [
                {
                    "id": "341800180",
                    "type": "cjmiam",
                    "detail": {
                        "remoteAssets": [],
                        "_xdm": {
                            "mixins": {
                                "_experience": {
                                    "customerJourneyManagement": {
                                        "messageExecution": {
                                            "messageExecutionID": "sbtest",
                                            "messageID": "567",
                                            "journeyVersionID": "",
                                            "journeyVersionInstanceId": ""
                                        }
                                    }
                                }
                            }
                        },
                        "mobileParameters": {
                            "schemaVersion": "1.0",
                            "width": 80,
                            "height": 50,
                            "verticalAlign": "center",
                            "verticalInset": 0,
                            "horizontalAlign": "center",
                            "horizontalInset": 0,
                            "uiTakeover": true,
                            "backdropColor": "000000",
                            "backdropOpacity": 0.5,
                            "cornerRadius": 15,
                            "displayAnimation": "left",
                            "dismissAnimation": "right",
                            "gestures": {
                                "swipeRight": "adbinapp://dismiss/?interaction=positive",
                                "swipeLeft": "adbinapp://dismiss/?interaction=negative"
                            }
                        },
                        "html": "\(marinersMessage)",
                        "template": "fullscreen"
                    }
                }
            ]
        }
    ]
}
"""
    
    
    static let marinersMessage = """
<html><head><meta name=\\\"viewport\\\" content=\\\"width=device-width, initial-scale=1.0\\\"><style>html, body { margin: 0;padding: 0;text-align: center;width: 100%;height: 100%;font-family: adobe-clean, \\\"Source Sans Pro\\\", -apple-system, BlinkMacSystemFont, \\\"Segoe UI\\\", Roboto, sans-serif;}.body {display: flex;flex-direction: column;background-color: #FFF;border-radius: 5px;color: #333333;width: 100vw;height: 100vh;text-align: center;align-items: center;background-size: 'cover';}.content {width: 100%;height: 100%;display: flex;justify-content: center;flex-direction: column;position: relative;}a {text-decoration: none;}.image {height: 1rem;flex-grow: 4;flex-shrink: 1;display: flex;justify-content: center;width: 90%;flex-direction: column;align-items: center;}.image img {max-height: 100%;max-width: 100%;}.text {text-align: center;line-height: 20px;font-size: 14px;color: #333333;padding: 0 25px;line-height: 1.25rem;font-size: 0.875rem;}.title {line-height: 1.3125rem;font-size: 1.025rem;}.buttons {width: 100%;display: flex;flex-direction: column;font-size: 1rem;line-height: 1.3rem;text-decoration: none;text-align: center;box-sizing: border-box;padding: .8rem;padding-top: .4rem;gap: 0.3125rem;}.button {flex-grow: 1;background-color: #1473E6;color: #FFFFFF;border-radius: .25rem;cursor: pointer;padding: .3rem;gap: .5rem;}.btnClose {color: #000000;}.closeBtn {align-self: flex-end;color: #000000;width: 1.8rem;height: 1.8rem;margin-top: 1rem;margin-right: .3rem;}</style><style type=\\\"text/css\\\" id=\\\"editor-styles\\\">[data-uuid=\\\"92bdbef0-eb32-48d3-b27f-7c0fba796b5c\\\"]  {flex-direction: row !important;}[data-uuid=\\\"92bdbef0-eb32-48d3-b27f-7c0fba796b5c\\\"] [data-uuid=\\\"99931ca2-eb8b-4f0b-b43c-8048d6fce07d\\\"] {color: rgba(0, 0, 0, 1);background-color: rgba(214, 244, 255, 1);}</style></head><body><div class=\\\"body\\\"><div class=\\\"closeBtn\\\" data-btn-style=\\\"plain\\\" data-uuid=\\\"8ae601d7-436d-47be-8238-cdbc23033574\\\"><a class=\\\"btnClose\\\" href=\\\"adbinapp://dismiss\\\"><svg xmlns=\\\"http://www.w3.org/2000/svg\\\" height=\\\"18\\\" viewBox=\\\"0 0 18 18\\\" width=\\\"18\\\" class=\\\"close\\\"><rect id=\\\"Canvas\\\" fill=\\\"#ffffff\\\" opacity=\\\"0\\\" width=\\\"18\\\" height=\\\"18\\\"/><path fill=\\\"currentColor\\\" xmlns=\\\"http://www.w3.org/2000/svg\\\" d=\\\"M13.2425,3.343,9,7.586,4.7575,3.343a.5.5,0,0,0-.707,0L3.343,4.05a.5.5,0,0,0,0,.707L7.586,9,3.343,13.2425a.5.5,0,0,0,0,.707l.707.7075a.5.5,0,0,0,.707,0L9,10.414l4.2425,4.243a.5.5,0,0,0,.707,0l.7075-.707a.5.5,0,0,0,0-.707L10.414,9l4.243-4.2425a.5.5,0,0,0,0-.707L13.95,3.343a.5.5,0,0,0-.70711-.00039Z\\\" /></svg></a></div><div class=\\\"image\\\" data-uuid=\\\"b898e788-a595-44f0-bfce-3036fbd3b6b9\\\"><img src=\\\"https://upload.wikimedia.org/wikipedia/commons/0/0a/Seattle_Mariners_logo_1980_to_1986.png\\\" data-medialibrary-id=\\\"\\\" data-mediarepo-id=\\\"\\\" alt=\\\"\\\" /></div><div class=\\\"text\\\" data-uuid=\\\"90086eda-93dd-4278-b2f7-f61ede6666a7\\\"><h3>Steve is testing IAM</h3><p>Go Mariners!</p></div><div data-uuid=\\\"92bdbef0-eb32-48d3-b27f-7c0fba796b5c\\\" class=\\\"buttons\\\"><a class=\\\"button\\\" data-uuid=\\\"99931ca2-eb8b-4f0b-b43c-8048d6fce07d\\\" href=\\\"adbinapp://dismiss/?interaction&#x3D;sadness\\\">sadness</a><a class=\\\"button\\\" data-uuid=\\\"9539372b-faa8-4cde-8259-632d7db41d3b\\\" href=\\\"adbinapp://dismiss/?interaction&#x3D;joy\\\">yay!</a></div></div></body></html>
"""
    
    static let jpTestMessage = """
<!doctype html><html><head><style>html,body {margin: 0;padding: 0;text-align: center;width: 100%;height: 100%;font-family: adobe-clean, \\\"Source Sans Pro\\\", -apple-system, BlinkMacSystemFont, \\\"Segoe UI\\\", Roboto, sans-serif;}    h3 {margin: .1rem auto;}p {margin: 0;}.body {display: flex;flex-direction: column;background-color: #FFF;border-radius: 5px;color: #333333;width: 100vw;height: 100vh;text-align: center;align-items: center;background-size: 'cover';}a {text-decoration: none;}.image {  height: 1rem;  flex-grow: 4;  flex-shrink: 1;  display: flex;  justify-content: center;  width: 90%;      flex-direction: column;      align-items: center;}    .image img {      max-height: 100%;      max-width: 100%;    }.text {text-align: center;line-height: 20px;font-size: 14px;color: #333333;padding: 0 25px;line-height: 1.25rem;font-size: 0.875rem;}.title {line-height: 1.3125rem;font-size: 1.025rem;}.buttons {width: 100%;display: flex;flex-direction: column;font-size: 1rem;line-height: 1.3rem;text-decoration: none;text-align: center;box-sizing: border-box;padding: .8rem;padding-top: .4rem;gap: 0.3125rem;}.button {flex-grow: 1;background-color: #1473E6;color: #FFFFFF;border-radius: .25rem;cursor: pointer;padding: .3rem;gap: .5rem;}.btnClose {color: #000000;}.closeBtn {align-self: flex-end;width: 1.8rem;height: 1.8rem;margin-top: 1rem;margin-right: .3rem;}</style><style type=\\\"text/css\\\" id=\\\"editor-styles\\\"></style><meta type=\\\"templateProperties\\\" name=\\\"c34ba445-e088-4a45-9558-1641206bfad3\\\" label=\\\"Pool demo\\\" icon=\\\"https://i.ibb.co/H49brrN/lgovzcjnbnaehjzahsbq.png\\\"><meta type=\\\"templateZone\\\" name=\\\"default\\\" label=\\\"Default\\\" classname=\\\"body\\\" definition=\\\"[&quot;CloseBtn&quot;,&quot;Html&quot;,&quot;Buttons&quot;]\\\"><meta type=\\\"templateDefaultAnimations\\\" dismissanimation=\\\"bottom\\\" displayanimation=\\\"bottom\\\"><meta type=\\\"templateDefaultSize\\\" dismissanimation=\\\"100\\\" displayanimation=\\\"100\\\"><meta type=\\\"templateDefaultPosition\\\" verticalalign=\\\"center\\\" verticalinset=\\\"0\\\" horizontalalign=\\\"center\\\" horizontalinset=\\\"0\\\"><meta type=\\\"templateDefaultGesture\\\"><meta type=\\\"templateDefaultUiTakeover\\\" enable=\\\"true\\\"></head><body><div class=\\\"body\\\"><div class=\\\"closeBtn\\\" data-btn-style=\\\"circle\\\" data-uuid=\\\"e9cb6fd7-ca13-4ef0-bc41-efdc4c6c9946\\\">  <a class=\\\"btnClose\\\" href=\\\"adbinapp://cancel\\\">    <svg xmlns=\\\"http://www.w3.org/2000/svg\\\" height=\\\"18\\\" viewBox=\\\"0 0 18 18\\\" width=\\\"18\\\" class=\\\"close\\\">  <rect id=\\\"Canvas\\\" fill=\\\"#ffffff\\\" opacity=\\\"0\\\" width=\\\"18\\\" height=\\\"18\\\"></rect>  <path fill=\\\"currentColor\\\" d=\\\"M14.657,3.343a8,8,0,1,0-.00021,11.31371l.00021-.00021A8,8,0,0,0,14.657,3.343Zm-1.3435,9.265-.707.7055a.6.6,0,0,1-.84853.00147l-.00147-.00147L9,10.5555l-2.758,2.758a.6.6,0,0,1-.84853.00147L5.392,13.3135l-.7045-.7075a.6.6,0,0,1-.00147-.84853L4.6875,11.756,7.4445,9,4.6875,6.242A.6.6,0,0,1,4.686,5.39347L4.6875,5.392l.707-.707A.6.6,0,0,1,6.243,4.68353L6.2445,4.685,9,7.444l2.758-2.7575a.6.6,0,0,1,.84853-.00147l.00147.00147.707.707a.6.6,0,0,1,.00147.84853L13.315,6.2435,10.5555,9l2.758,2.758a.6.6,0,0,1,.00147.84853Z\\\"></path></svg>  </a></div><div data-uuid=\\\"6ed59935-26b3-4469-8ceb-035690ce6ff5\\\" height=\\\"80%\\\" style=\\\"overflow: hidden;\\\"><iframe width=\\\"300\\\" height=\\\"444\\\" src=\\\"https://strawpoll.com/embed/ju9awkvy9\\\" style=\\\"width: 100%; height: 444px;\\\" frameborder=\\\"0\\\" allowfullscreen=\\\"\\\"></iframe></div><div data-uuid=\\\"0285a2d6-5371-4f77-8f55-52087b40bd21\\\" class=\\\"buttons\\\">  <a class=\\\"button\\\" data-uuid=\\\"7b16ce7b-6f42-484f-b937-c880454a7d1e\\\" href=\\\"adbinapp://confirm/\\\">Skip</a></div></div></body></html>
"""
}



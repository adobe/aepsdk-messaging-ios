# Event Reference

## Events handled

The following events are dispatched by the Optimize extension:

### Optimize Request Content

This event is a request to the Optimize extension to prefetch, retrieve or track propositions. The event is generated in the following scenarios:

* When `updatePropositions` API is invoked to fetch propositions, from the Experience Platform Edge network, for an array of provided decision scopes.
* When `getPropositions` API is invoked to retrieve previously fetched propositions cached in the Optimize extension.
* When `displayed()` or `tapped()` methods are invoked on the `Offer` instance to track offer interactions.

#### Event details

| Event Type | Event Source |
| ---------- | ------------ |
| com.adobe.eventType.optimize | com.adobe.eventSource.requestContent |

#### Data payload definition

##### Update propositions

| Key | Data Type | Required | Description |
| --- | --------- | -------- | ----------- |
| requesttype | String | yes | A string containing `updatepropositions` value indicating to the Optimize extension that it is a request to fetch personalization decisions from the Experience Platform Edge network. |
| data | [String: Any] | no | A dictionary containing additional freeform data to be attached to the personalization query request. |
| xdm | [String: Any] | no | A dictionary containing additional XDM-formatted data to be attached to the personalization query request. |
| decisionscopes | [[String: Any]] | yes | An array of decision scopes to be sent in the personalization query request to the Experience Platform Edge network to fetch decision propositions. |

**Example**
```swift
[
    id: 206DB644-30E1-4044-98AC-80465E915265
    name: Optimize Update Propositions Request
    type: com.adobe.eventType.optimize
    source: com.adobe.eventSource.requestContent
    data: {
        "requesttype" : "updatepropositions",
        "data" : {
            "someKey" : "someValue"
        },
        "xdm" : {
            "xdmKey" : "xdmValue"
        },
        "decisionscopes" : [
            {
            "name" : "eyJ4ZG06YWN0aXZpdHlJZCI6Inhjb3JlOm9mZmVyLWFjdGl2aXR5OjEzNGNlY2MyMGU2NjljZWEiLCJ4ZG06cGxhY2VtZW50SWQiOiJ4Y29yZTpvZmZlci1wbGFjZW1lbnQ6MTJiOWEwMDA1NTUwNzM1NyJ9"
            }
        ]
    }
    timestamp: 2022-10-23 22:07:19 +0000
    responseId: nil
    mask: nil
]
```

##### Get propositions

| Key | Data Type | Required | Description |
| --- | --------- | -------- | ----------- |
| requesttype | String | yes | A string containing `getpropositions` value indicating to the Optimize extension that it is a request to retrieve previously cached propositions. |
| decisionscopes | [[String: Any]] | yes | An array of decision scopes for which propositions need to be retrieved from the Optimize extension's in-memory propositions cache. |

**Example**
```swift
[
    id: E4B85E46-5132-4B54-AD05-11E59416A797
    name: Optimize Get Propositions Request
    type: com.adobe.eventType.optimize
    source: com.adobe.eventSource.requestContent
    data: {
        "requesttype" : "getpropositions",
        "decisionscopes" : [
            {
            "name" : "eyJ4ZG06YWN0aXZpdHlJZCI6Inhjb3JlOm9mZmVyLWFjdGl2aXR5OjEzNGNlY2MyMGU2NjljZWEiLCJ4ZG06cGxhY2VtZW50SWQiOiJ4Y29yZTpvZmZlci1wbGFjZW1lbnQ6MTJiOWEwMDA1NTUwNzM1NyJ9"
            }
        ]
    }
    timestamp: 2022-10-23 22:50:28 +0000
    responseId: nil
    mask: nil
]
```

##### Track propositions

| Key | Data Type | Required | Description |
| --- | --------- | -------- | ----------- |
| requesttype | String | yes | A string containing `trackpropositions` value indicating to the Optimize extension that it is a request to track proposition offer interactions. |
| eventType | String | yes | A string containing `decisioning.propositionInteract` or `decisioning.propositionDisplay` value indicating the offer interaction type. |
| _experience | [String: Any] | yes | A dictionary containing the XDM data for the proposition interaction in the [Experience Event - Proposition Interactions](https://github.com/adobe/xdm/blob/master/docs/reference/adobe/experience/decisioning/experienceevent-proposition-interaction.schema.json) field group format. |

**Example**
```swift
[
    id: 3A1919FF-AAB3-441F-9828-746BA06AE3A0
    name: Optimize Track Propositions Request
    type: com.adobe.eventType.optimize
    source: com.adobe.eventSource.requestContent
    data: {
        "requesttype" : "trackpropositions",
        "propositioninteractions" : {
            "eventType" : "decisioning.propositionDisplay",
            "_experience" : {
                "decisioning" : {
                    "propositions" : [
                    {
                        "id" : "6762065a-8121-47a3-96d3-793ce6c41b1d",
                        "scope" : "eyJ4ZG06YWN0aXZpdHlJZCI6Inhjb3JlOm9mZmVyLWFjdGl2aXR5OjEzNGNlY2MyMGU2NjljZWEiLCJ4ZG06cGxhY2VtZW50SWQiOiJ4Y29yZTpvZmZlci1wbGFjZW1lbnQ6MTJiOWEwMDA1NTUwNzM1NyJ9",
                        "items" : [
                        {
                            "id" : "xcore:personalized-offer:134ce82e8a6201cc"
                        }
                        ],
                        "scopeDetails" : {
                        }
                    }
                    ]
                }
            }
        }
    }
    timestamp: 2022-10-23 22:07:21 +0000
    responseId: nil
    mask: nil
]
```

### Edge personalization decisions

This event is dispatched by the Edge network extension when it receives personalization decisions from the Experience Platform Edge network, following a personalization query request. When this event is received, the Optimize extension parses and caches the received propositions in an in-memory propositions dictionary keyed by the corresponding decision scope.

#### Event details

| Event Type | Event Source |
| ---------- | ------------ |
| com.adobe.eventType.edge | personalization:decisions |

#### Data payload definition

| Key | Data Type | Required | Description |
| --- | --------- | -------- | ----------- |
| requestEventId | String | yes | A string containing the event ID of the Edge request content event which triggered this personalization:decisions response. |
| type | String | yes | A string containing `personalization:decisions` value. |
| requestId | String | yes | A string containing the request ID of the personalization query request sent to the Experience Platform Edge network. |
| payload | [[String: Any]] | yes | An array containing the decision propositions for the requested scopes. |

**Example**
```swift
[
    id: A3B623EB-B006-409F-A32C-0F9B56A1947F
    name: AEP Response Event Handle
    type: com.adobe.eventType.edge
    source: personalization:decisions
    data: {
        "requestEventId" : "02171551-D1B1-414A-B662-3E0B934BECC4",
        "type" : "personalization:decisions",
        "requestId" : "F358D9E0-2CC2-4938-A82C-2DC5CCC89E5C",
        "payload" : [
            {
            "activity" : {
                "etag" : "2",
                "id" : "xcore:offer-activity:134cecc20e669cea"
            },
            "id" : "6762065a-8121-47a3-96d3-793ce6c41b1d",
            "placement" : {
                "etag" : "2",
                "id" : "xcore:offer-placement:12b9a00055507357"
            },
            "items" : [
                {
                "id" : "xcore:personalized-offer:134ce82e8a6201cc",
                "data" : {
                    "characteristics" : {
                        "testing" : "true"
                    },
                    "id" : "xcore:personalized-offer:134ce82e8a6201cc",
                    "content" : "Sale!! Sale!! Sale!!",
                    "language" : [
                        "en-us"
                    ],
                    "format" : "text\/plain"
                },
                "etag" : "4",
                "schema" : "https:\/\/ns.adobe.com\/experience\/offer-management\/content-component-text"
                }
            ],
            "scope" : "eyJ4ZG06YWN0aXZpdHlJZCI6Inhjb3JlOm9mZmVyLWFjdGl2aXR5OjEzNGNlY2MyMGU2NjljZWEiLCJ4ZG06cGxhY2VtZW50SWQiOiJ4Y29yZTpvZmZlci1wbGFjZW1lbnQ6MTJiOWEwMDA1NTUwNzM1NyJ9"
            }
        ]
    }
    timestamp: 2022-10-23 22:07:21 +0000
    responseId: nil
    mask: nil
]
```

### Edge error response content

This event is dispatched by the Edge network extension when it receives an error response from the Experience Platform Edge network, following a personalization query request. When this event is received, the Optimize extension logs error related information specifying error type along with a detailed message.

#### Event details

| Event Type | Event Source |
| ---------- | ------------ |
| com.adobe.eventType.edge | com.adobe.eventSource.errorResponseContent |

#### Data payload definition

| Key | Data Type | Required | Description |
| --- | --------- | -------- | ----------- |
| requestEventId | String | yes | A string containing the event ID of the Edge request content event which triggered this error response. | 
| requestId | String | yes | A string containing the request ID of the personalization query request sent to the Experience Platform Edge network. |
| type | String | yes | A URI reference that identifies the problem type. |
| status | String | yes | The HTTP status code generated by the server for this problem. |
| title | String | yes | A short, humable-readable summary of the problem type. |
| detail | String | yes | A short, humable-readable description of the problem type. |
| report | [String: Any] | yes | A dictionary of additional properties that aid in debugging. E.g. a list of validation errors. |

> [!NOTE]
> All error responses have a `type`, `status`, `title`, `detail` and `report` message properties so that the API client can identify the problem.

```swift
[
    id: 767FF9C1-B121-4688-8815-6AE5079BE48C
    name: AEP Error Response
    type: com.adobe.eventType.edge
    source: com.adobe.eventSource.errorResponseContent
    data: {
        "detail" : "The following scope was not found: xcore:offer-activity:134cecc20e669cea\/xcore:offer-placement:12b9a00055507357",
        "status" : 404,
        "report" : {
        },
        "requestId" : "06D07BDB-0956-4F8C-969D-729CD79CD6D4",
        "requestEventId" : "FAC163B4-38D6-438E-A15E-772A82F4CA72",
        "type" : "https:\/\/ns.adobe.com\/aep\/errors\/ODE-0001-404",
        "title" : "Not Found"
    }
    timestamp: 2022-05-31 18:10:32 +0000
    responseId: nil
    mask: nil
]
```

### Optimize request reset

This event is dispatched when Optimize extension's `clearCachedPropositions` API is invoked. When this event is received, the Optimize extension clears all the previous cached propositions from the in-memory propositions cache.

#### Event details

| Event Type | Event Source |
| ---------- | ------------ |
| com.adobe.eventType.optimize | com.adobe.eventSource.requestReset |

#### Data payload definition

N/A

**Example**
```swift
[
    id: BC92C074-2037-4D31-9606-7F30933A32CF
    name: Optimize Clear Propositions Request
    type: com.adobe.eventType.optimize
    source: com.adobe.eventSource.requestReset
    data: 
    timestamp: 2022-10-23 22:59:21 +0000
    responseId: nil
    mask: nil
]
```

### Generic identity request reset

This event is dispatched when the Mobile Core's `resetIdentities` API is invoked. When this event is received, the Optimize extension clears all the previous cached propositions from the in-memory propositions cache.

#### Event details

| Event Type | Event Source |
| ---------- | ------------ |
| com.adobe.eventType.generic.identity | com.adobe.eventSource.requestReset |

#### Data payload definition

N/A

**Example**
```swift
[
    id: 025E98D8-D90F-4CFE-A4BE-A2F6815A9195
    name: Reset Identities Request
    type: com.adobe.eventType.generic.identity
    source: com.adobe.eventSource.requestReset
    data: 
    timestamp: 2022-10-23 23:01:54 +0000
    responseId: nil
    mask: nil
]
```

## Events dispatched

### Edge request content

This event is a request to the Edge network extension to send a request to the Experience Platform Edge network to:

* Fetch personalization decisions from Adobe Target or Offer Decisioning services; or
* Inform of an offer interaction e.g. display or tap interaction 

This event is dispatched by the Optimize extension when it's `updatePropositions` API is invoked; or when `display()` or `tapped()` methods are invoked on the `Offer` instance.

#### Event details

| Event Type | Event Source |
| ---------- | ------------ |
| com.adobe.eventType.edge | com.adobe.eventSource.requestContent |

#### Data payload definition

#### Update propositions

| Key | Data Type | Required | Description |
| --- | --------- | -------- | ----------- |
| query | [String: Any] | yes | A dictionary containing the personalization query request with the scopes for which personalization decisions need to be fetched from the Experience Platform Edge network. |
| datasetId | String | no | A string containing the override dataset ID where all subsequent Experience Events need to be sent. |
| data | [String: Any] | no | A dictionary containing the freeform data to be attached to the personalization query request. |
| xdm | [String: Any] | no | A dictionary containing the XDM-formatted data to be attached to the personalization query request. |

**Example**
```swift
[
    id: 02171551-D1B1-414A-B662-3E0B934BECC4
    name: Edge Optimize Personalization Request
    type: com.adobe.eventType.edge
    source: com.adobe.eventSource.requestContent
    data: {
        "query" : {
            "personalization" : {
                "decisionScopes" : [
                    "eyJ4ZG06YWN0aXZpdHlJZCI6Inhjb3JlOm9mZmVyLWFjdGl2aXR5OjEzNGNlY2MyMGU2NjljZWEiLCJ4ZG06cGxhY2VtZW50SWQiOiJ4Y29yZTpvZmZlci1wbGFjZW1lbnQ6MTJiOWEwMDA1NTUwNzM1NyJ9"
                ],
                "schemas" : [
                    "https:\/\/ns.adobe.com\/personalization\/html-content-item",
                    "https:\/\/ns.adobe.com\/personalization\/json-content-item",
                    "https:\/\/ns.adobe.com\/personalization\/default-content-item",
                    "https:\/\/ns.adobe.com\/experience\/offer-management\/content-component-html",
                    "https:\/\/ns.adobe.com\/experience\/offer-management\/content-component-json",
                    "https:\/\/ns.adobe.com\/experience\/offer-management\/content-component-imagelink",
                    "https:\/\/ns.adobe.com\/experience\/offer-management\/content-component-text"
                ]
            }
        },
        "datasetId" : "",
        "data" : {
            "someKey" : "someValue"
        },
        "xdm" : {
            "eventType" : "personalization.request",
            "xdmKey" : "xdmValue"
        }
    }
    timestamp: 2022-10-23 22:07:19 +0000
    responseId: nil
    mask: nil
]
```

#### Track propositions

| Key | Data Type | Required | Description |
| --- | --------- | -------- | ----------- |
| datasetId | String | no | A string containing the override dataset ID where all subsequent Experience Events need to be sent. |
| xdm | [String: Any] | yes | A dictionary containing the XDM data for the proposition interaction in the [Experience Event - Proposition Interactions](https://github.com/adobe/xdm/blob/master/docs/reference/adobe/experience/decisioning/experienceevent-proposition-interaction.schema.json) field group format. |

```swift
[
    id: E69CCAB5-D13F-44E6-9E86-04FBD6CDE36B
    name: Edge Optimize Proposition Interaction Request
    type: com.adobe.eventType.edge
    source: com.adobe.eventSource.requestContent
    data: {
        "datasetId" : "",
        "xdm" : {
            "_experience" : {
                "decisioning" : {
                    "propositions" : [
                    {
                        "scope" : "eyJ4ZG06YWN0aXZpdHlJZCI6Inhjb3JlOm9mZmVyLWFjdGl2aXR5OjEzNGNlY2MyMGU2NjljZWEiLCJ4ZG06cGxhY2VtZW50SWQiOiJ4Y29yZTpvZmZlci1wbGFjZW1lbnQ6MTJiOWEwMDA1NTUwNzM1NyJ9",
                        "id" : "fcfceb6c-c7e0-4297-a2b1-d0a50c3fe499",
                        "scopeDetails" : {

                        },
                        "items" : [
                        {
                            "id" : "xcore:personalized-offer:13ac4007a6c4e3d0"
                        }
                        ]
                    }
                    ]
                }
            },
            "eventType" : "decisioning.propositionInteract"
        }
    }
    timestamp: 2022-10-24 01:18:41 +0000
    responseId: nil
    mask: nil
]
```


### Optimize notification 

This event is a notification by the Optimize extension that it has received personalization decisions from the Experience Platform Edge network. The event is dispatched when an Edge personalization:decisions event is processed by the Optimize extension and the received propositions are cached in memory.  

#### Event details

| Event Type | Event Source |
| ---------- | ------------ |
| com.adobe.eventType.optimize | com.adobe.eventSource.notification |

#### Data payload definition

| Key | Data Type | Required | Description |
| --- | --------- | -------- | ----------- |
| propositions | [[String: Any]] | yes | An array containing the decision propositions for the requested scopes. |

**Example**
```swift
[
    id: 0BFE32FC-806C-4266-9CA5-5C36D1333BC5
    name: Optimize Notification
    type: com.adobe.eventType.optimize
    source: com.adobe.eventSource.notification
    data: {
        "propositions" : [
            {
            "name" : "eyJ4ZG06YWN0aXZpdHlJZCI6Inhjb3JlOm9mZmVyLWFjdGl2aXR5OjEzNGNlY2MyMGU2NjljZWEiLCJ4ZG06cGxhY2VtZW50SWQiOiJ4Y29yZTpvZmZlci1wbGFjZW1lbnQ6MTJiOWEwMDA1NTUwNzM1NyJ9"
            },
            {
            "id" : "6762065a-8121-47a3-96d3-793ce6c41b1d",
            "scope" : "eyJ4ZG06YWN0aXZpdHlJZCI6Inhjb3JlOm9mZmVyLWFjdGl2aXR5OjEzNGNlY2MyMGU2NjljZWEiLCJ4ZG06cGxhY2VtZW50SWQiOiJ4Y29yZTpvZmZlci1wbGFjZW1lbnQ6MTJiOWEwMDA1NTUwNzM1NyJ9",
            "scopeDetails" : {

            },
            "items" : [
                {
                "id" : "xcore:personalized-offer:134ce82e8a6201cc",
                "etag" : "4",
                "score" : 0,
                "schema" : "https:\/\/ns.adobe.com\/experience\/offer-management\/content-component-text",
                "meta" : null,
                "data" : {
                    "language" : [
                        "en-us"
                    ],
                    "id" : "xcore:personalized-offer:134ce82e8a6201cc",
                    "content" : "Sale!! Sale!! Sale!!",
                    "characteristics" : {
                        "testing" : "true"
                    },
                    "type" : 2
                }
                }
            ]
            }
        ]
    }
    timestamp: 2022-10-23 22:07:21 +0000
    responseId: nil
    mask: nil
]
```

### Optimize response content

This is a response event dispatched when Optimize extension's `getPropositions` API is invoked to retrieve decision propositions. It returns previously cached propositions for the provided array of decision scopes. 

> [!NOTE]
> This event is a paired response event for the Optimize request content event, dispatched upon a `getPropositions` API call.

#### Event details

| Event Type | Event Source |
| ---------- | ------------ |
| com.adobe.eventType.optimize | com.adobe.eventSource.responseContent |

#### Data payload definition

| Key | Data Type | Required | Description |
| --- | --------- | -------- | ----------- |
| propositions | [[String: Any]] | yes | An array containing the decision propositions for the requested scopes. |

**Example**
```swift
[
    id: 584850BB-9EA6-4256-B1F9-DF50BC47127F
    name: Optimize Response
    type: com.adobe.eventType.optimize
    source: com.adobe.eventSource.responseContent
    data: {
        "propositions" : [
            {
            "name" : "eyJ4ZG06YWN0aXZpdHlJZCI6Inhjb3JlOm9mZmVyLWFjdGl2aXR5OjEzNGNlY2MyMGU2NjljZWEiLCJ4ZG06cGxhY2VtZW50SWQiOiJ4Y29yZTpvZmZlci1wbGFjZW1lbnQ6MTJiOWEwMDA1NTUwNzM1NyJ9"
            },
            {
            "id" : "6762065a-8121-47a3-96d3-793ce6c41b1d",
            "scope" : "eyJ4ZG06YWN0aXZpdHlJZCI6Inhjb3JlOm9mZmVyLWFjdGl2aXR5OjEzNGNlY2MyMGU2NjljZWEiLCJ4ZG06cGxhY2VtZW50SWQiOiJ4Y29yZTpvZmZlci1wbGFjZW1lbnQ6MTJiOWEwMDA1NTUwNzM1NyJ9",
            "scopeDetails" : {

            },
            "items" : [
                {
                "id" : "xcore:personalized-offer:134ce82e8a6201cc",
                "etag" : "4",
                "score" : 0,
                "schema" : "https:\/\/ns.adobe.com\/experience\/offer-management\/content-component-text",
                "meta" : null,
                "data" : {
                    "language" : [
                    "en-us"
                    ],
                    "id" : "xcore:personalized-offer:134ce82e8a6201cc",
                    "content" : "Sale!! Sale!! Sale!!",
                    "characteristics" : {
                    "testing" : "true"
                    },
                    "type" : 2
                }
                }
            ]
            }
        ]
    }
    timestamp: 2022-10-23 22:50:28 +0000
    responseId: Optional("E4B85E46-5132-4B54-AD05-11E59416A797")
    mask: nil
]
```

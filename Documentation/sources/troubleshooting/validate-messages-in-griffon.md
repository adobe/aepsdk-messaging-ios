# Validate messaging configuration using Assurance and Griffon

This guide will walk you through steps necessary to ensure your app is properly configured for in-app messaging with Adobe Journey Optimizer (AJO). Perform the following steps:

- [Complete prerequisites for your app](#prerequisites)
- [Validate the correct extensions are registered](#validate-the-correct-extensions-are-registered)
- [Validate the event requesting message definitions](#validate-the-event-requesting-message-definitions)
- [Validate the event with message definition response](#validate-the-event-with-message-definition-response)

### Prerequisites

Hook up to assurance.

Launch the app

### Validate the correct extensions are registered

Completing this section will validate that your app has registered all the AEP SDK extensions required to support in-app messaging. Perform validation by doing the following:

1. Launch your application with an **AEPAssurance** session active

1. In the Griffon UI, click on **Shared States** in the left-rail navigation

1. Click the **+** button next to the row with a **State Path** of **com.adobe.module.eventhub**

1. Open the **extensions** object, and validate that each of the required extensions exist, and meet the minimum version requirements. The table below shows the minimum versions required for in-app messaging dependencies:

    | Extension       | Min version |
    | --------------- | ----------: |
    | AEPCore         | 3.4.2       |
    | AEPEdge         | 1.3.0       |
    | AEPEdgeConsent  | 1.0.0       |
    | AEPEdgeIdentity | 1.0.1       |
    | AEPMessaging    | 1.1.0       |
    | AEPOptimize     | 1.0.0       |

Below is an example of what the view in Griffon may look like:

![correct extensions registered](./../../assets/message_configuration.png)

### Validate the event requesting message definitions

When the AEPMessaging extension has finished registration with the AEP SDK and a valid configuration exists, it will automatically initiate a network request to fetch message definitions from the remote.

Completing the following steps will validate that your app is making the necessary request to retrieve in-app message definitions:

1. Launch your application with an **AEPAssurance** session active

1. In the Griffon UI, click on **Events** in the left-rail navigation

1. In the event list, select the event with type **Edge Optimize Personalization Request**

    ![Edge Optimize Personalization Request](./../../assets/message_request.png)

1. Expand the **Payload** section in the right window and ensure the correct **decisionScope** is being used. The **decisionScope** is a base64 representation of a JSON payload that should contain your app's bundle identifier. You can use an [online base64 decoder](https://www.base64decode.org/) to decode the text. Verifying the request is using the correct **decisionScope** is important, since there may be multiple events with the same event type.

The below example demonstrates validating a **decisionScope** for an app with bundle identifier `com.adobe.demosystem.dxdemo`:
- **decisionScope** == `eyJ4ZG06bmFtZSI6ImNvbS5hZG9iZS5kZW1vc3lzdGVtLmR4ZGVtbyJ9`
- Base64 decoded representation of **decisionScope** == `{"xdm:name":"com.adobe.demosystem.dxdemo"}`
- `com.adobe.demosystem.dxdemo` matches the application's bundle identifier

    ![Edge Optimize Personalization Request Payload](./../../assets/message_request_payload.png)

### Validate the event with message definition response

After the request verified in the previous step returns, the AEPEdge extension will dispatch a response Event containing the data returned by the remote server.

Complete the following steps to validate a response containing in-app messages:

1. Launch your application with an **AEPAssurance** session active

1. In the Griffon UI, click on **Events** in the left-rail navigation

1. In the event list, select the event with type **AEP Response Event Handle**. There will likely be several events with this type - ensure the one selected has an `AEPExtensionEventSource` of **personalization:decisions**

    ![AEP Response Event Handle](./../../assets/message_response.png)

1. Expand the **Payload** section in the right window, and drill-down the tree until you find the **items** array. The full path to **items** is: `ACPExtensionEventData.payload.0.items`. This array contains an entry for each of this app's published messages. As shown in the screenshot below, the message is fully defined in the **content** property of each item's **data** object:

    ![AEP Response Event Handle Payload](./../../assets/message_response_payload.png)

### Use the In-App Messaging Griffon plugin

#### FAQs

Q: I don't see the XYZ event. Now what?
A:

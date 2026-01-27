# AEPMessaging Documentation

## Installation

- [Installing AEPMesssaging extension](./sources/installation/getting-started.md)
- [Configure Adobe Data Collection and Adobe Experience Platform](./sources/shared/prerequisites/edge-and-launch-configuration.md)

## Push messaging

- Prerequisites
  - [Enable push notifications in your app](./sources/push-messaging/prerequisites/enable-push-notifications.md)

- Developer documentation
  - [API usage](./sources/push-messaging/developer-documentation/api-usage.md)
  - [PushTrackingStatus](./sources/push-messaging/developer-documentation/enum-push-tracking-status.md)

- Guides
  - [Displaying Rich Push Notification](./sources/push-messaging/guides/display-rich-push-notification.md)

## Live Activities

- Prerequisites
  - [Enable push notifications in your app](./sources/push-messaging/prerequisites/enable-push-notifications.md)

- Developer documentation
  - [API usage](./sources/live-activities/developer-documentation/api-usage.md)
  - Public classes
    - [LiveActivityData](./sources/live-activities/developer-documentation/classes/live-activity-data.md)
    - [LiveActivityAttributes](./sources/live-activities/developer-documentation/classes/live-activity-attributes.md)
    - [LiveActivityOrigin](./sources/live-activities/developer-documentation/classes/live-activity-origin.md)
    - [LiveActivityAssuranceDebuggable](./sources/live-activities/developer-documentation/classes/live-activity-assurance-debuggable.md)

## In-App messaging

- Developer documentation
  - [API usage](./sources/inapp-messaging/developer-documentation/api-usage.md)
  - [Message](./sources/inapp-messaging/developer-documentation/message.md)

- Advanced guides
  - [Programmatically control the display of in-app messages](./sources/inapp-messaging/advanced-guides/how-to-messaging-delegate.md)
  - [Call native code from the Javascript of an in-app message](./sources/inapp-messaging/advanced-guides/how-to-call-native-from-javascript.md)
  - [Execute Javascript code in an in-app message from native code](./sources/inapp-messaging/advanced-guides/how-to-call-javascript-from-native.md)
  - [Handle URL clicks from an in-app message](./sources/inapp-messaging/advanced-guides/how-to-handle-url-clicks.md)

- Troubleshooting
  - [Validate In-App Messaging using Assurance](./sources/inapp-messaging/troubleshooting/validate-messages-in-griffon.md)

## Code-based experiences and content cards

- Developer documentation
  - [API usage](./sources/propositions/developer-documentation/api-usage.md)
  - Public classes
    - [ContentCard - DEPRECATED](./sources/propositions/developer-documentation/classes/content-card.md)
    - [Proposition](./sources/propositions/developer-documentation/classes/proposition.md)
    - [PropositionItem](./sources/propositions/developer-documentation/classes/proposition-item.md)
    - [Surface](./sources/propositions/developer-documentation/classes/surface.md)
    - Schema classes
      - [ContentType](./sources/propositions/developer-documentation/classes/schemas/content-type.md)
      - [ContentCardSchemaData](./sources/propositions/developer-documentation/classes/schemas/content-card-schema-data.md)
      - [HtmlContentSchemaData](./sources/propositions/developer-documentation/classes/schemas/html-content-schema-data.md)
      - [InAppSchemaData](./sources/propositions/developer-documentation/classes/schemas/inapp-schema-data.md)
      - [JsonContentSchemaData](./sources/propositions/developer-documentation/classes/schemas/json-content-schema-data.md)

## Content cards with UI

- Developer documentation 

    - [API Usage](./sources/content-card-ui/api-usage.md)

- Public Classes, Enums, and Protocols

    - [ContentCardUI](./sources/content-card-ui/public-classes/contentcardui.md)
    - [ContentCardCustomizing](./sources/content-card-ui/public-classes/contentcardcustomizing.md)
    - [ContentCardUIEventListening](./sources/content-card-ui/public-classes/contentcarduieventlistening.md)

- Templates

    - [SmallImageTemplate](./sources/content-card-ui/public-classes/Template/smallimage-template.md)

- UI Elements

    - [AEPText](./sources/content-card-ui/public-classes/UIElements/aeptext.md)
    - [AEPButton](./sources/content-card-ui/public-classes/UIElements/aepbutton.md)
    - [AEPImage](./sources/content-card-ui/public-classes/UIElements/aepimage.md)
    - [AEPStack](./sources/content-card-ui/public-classes/UIElements/aepstack.md)
    - [AEPDismissButton](./sources/content-card-ui/public-classes/UIElements/aepdismissbutton.md)
 
- Tutorials

    - [Fetch and Display Content Cards](./sources/content-card-ui/tutorial/displaying-content-cards.md) 
    - [Customizing Content Card Templates](./sources/content-card-ui/tutorial/customizing-content-card-templates.md)
    - [Listening to Content Card Events](./sources/content-card-ui/tutorial/listening-content-card-events.md)


## Common public classes, methods, and enums

- [MessagingEdgeEventType](./sources/shared/enums/enum-messaging-edge-event-type.md)

## Event tracking in Adobe Experience Platform

- [How event tracking for propositions works](./sources/shared/event-tracking.md)
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
    - [ContentCard](./sources/propositions/developer-documentation/classes/content-card.md)
    - [Proposition](./sources/propositions/developer-documentation/classes/proposition.md)
    - [PropositionItem](./sources/propositions/developer-documentation/classes/proposition-item.md)
    - [Surface](./sources/propositions/developer-documentation/classes/surface.md)
    - Schema classes
      - [ContentCardSchemaData](./sources/propositions/developer-documentation/classes/schemas/content-card-schema-data.md)
      - [HtmlContentSchemaData](./sources/propositions/developer-documentation/classes/schemas/html-content-schema-data.md)
      - [InAppSchemaData](./sources/propositions/developer-documentation/classes/schemas/inapp-schema-data.md)
      - [JsonContentSchemaData](./sources/propositions/developer-documentation/classes/schemas/json-content-schema-data.md)

## Common public classes, methods, and enums

- [MessagingEdgeEventType](./sources/shared/enums/enum-messaging-edge-event-type.md)

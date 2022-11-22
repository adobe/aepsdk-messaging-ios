# AEPMessaging Public APIs and Classes

This document details how to use the APIs provided by the AEPMessaging framework.

For more in-depth information about the Messaging extension, visit the [official SDK documentation for Adobe Journey Optimizer Messaging extension](https://developer.adobe.com/client-sdks/documentation/iam/).

## In-App Messaging APIs

#### Programmatically refresh in-app message definitions from the remote

By default, the SDK will automatically fetch in-app message definitions from the remote at the time the Messaging extension is registered. This generally happens once per app lifecycle, in the `application(_: didFinishLaunchingWithOptions:)` method of the `AppDelegate`.

Some use cases may require the client to request an update from the remote more frequently. Calling the following API will force the Messaging extension to get an updated definition of messages from the remote:

```swift
Messaging.refreshInAppMessages()
```

## Message (class)

The `Message` class contains the definition of an in-app message and controls its tracking via Experience Edge events.

`Message` objects are only created by the AEPMessaging extension, and passed as the `message` parameter in `MessagingDelegate` protocol methods.

### Public variables

#### id

Identifier of the `Message`.

```swift
public var id: String
```

#### autoTrack

If set to `true` (default), Experience Edge events will automatically be generated when this `Message` is triggered, displayed, or dismissed.

```swift
public var autoTrack: Bool = true
```

#### view

Holds a reference to the message's `WKWebView` instance, if it exists.

```swift
public var view: UIView? {
    fullscreenMessage?.webView
}
```

### Public functions

#### show

Signals to the UIService (in `AEPServices`) that the message should be shown.

If `autoTrack` is true, calling this method will result in an "decisioning.propositionTrigger" Edge Event being dispatched.

```swift
public func show()
```

#### dismiss(suppressAutoTrack:)

Signals to the UIService that the message should be removed from the UI.

If `autoTrack` is true, calling this method will result in an "decisioning.propositionDismiss" Edge Event being dispatched.

```swift
public func dismiss(suppressAutoTrack: Bool? = false)
```

###### Parameters

- _suppressAutoTrack_ - if set to `true`, the "decisioning.propositionDismiss" Edge Event will not be sent regardless of the `autoTrack` setting.

#### track(_:withEdgeEventType:)

Generates and dispatches an Edge Event for the provided `interaction` and `eventType`.

```swift
public func track(_ interaction: String?, withEdgeEventType eventType: MessagingEdgeEventType)
```

###### Parameters

- _interaction_ - a custom `String` value to be recorded in the interaction
- _eventType_ - the [`MessagingEdgeEventType`](./enum-messaging-edge-event-type.md) to be used for the ensuing Edge Event

#### handleJavascriptMessage(_:withHandler:)

Adds a handler for named Javascript messages sent from the message's `WKWebView`.

The parameter passed to `handler` will contain the body of the message passed from the `WKWebView`'s Javascript.

```swift
public func handleJavascriptMessage(_ name: String, withHandler handler: @escaping (Any?) -> Void)
```

###### Parameters

- _name_ - the name of the message that should be handled by `handler`
- _handler_ - the method or closure to be called with the body of the message created in Message's Javascript

For more information on how to use `handleJavascriptMessage`, read [Call native code from the Javascript of an in-app message](./how-to-call-native-from-javascript.md).

## MessagingEdgeEventType (enum)

Provides mapping to XDM EventType strings needed for Experience Event requests.

This enum is used in conjunction with the [`track(_:withEdgeEventType:)`](./class-message.md#track_withedgeeventtype) method of a `Message` object.

### Definition

```swift
@objc(AEPMessagingEdgeEventType)
public enum MessagingEdgeEventType: Int {
    case inappDismiss = 0
    case inappInteract = 1
    case inappTrigger = 2
    case inappDisplay = 3
    case pushApplicationOpened = 4
    case pushCustomAction = 5

    public func toString() -> String {
        switch self {
        case .inappDismiss:
            return MessagingConstants.XDM.IAM.EventType.DISMISS
        case .inappTrigger:
            return MessagingConstants.XDM.IAM.EventType.TRIGGER
        case .inappInteract:
            return MessagingConstants.XDM.IAM.EventType.INTERACT
        case .inappDisplay:
            return MessagingConstants.XDM.IAM.EventType.DISPLAY
        case .pushCustomAction:
            return MessagingConstants.XDM.Push.EventType.CUSTOM_ACTION
        case .pushApplicationOpened:
            return MessagingConstants.XDM.Push.EventType.APPLICATION_OPENED
        }
    }
}
```

### String values

Below is the table of values returned by calling the `toString` method for each case:

| Case                  | String value                      |
|-----------------------|-----------------------------------|
| inappDismiss          | `decisioning.propositionDismiss`  |
| inappInteract         | `decisioning.propositionInteract` |
| inappTrigger          | `decisioning.propositionTrigger`  |
| inappDisplay          | `decisioning.propositionDisplay`  |
| pushApplicationOpened | `pushTracking.applicationOpened`  |
| pushCustomAction      | `pushTracking.customAction`       |
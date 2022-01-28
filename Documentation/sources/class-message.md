# Message

The `Message` class contains the definition of an in-app message and controls its tracking via Experience Edge events.

`Message` objects are only created by the AEPMessaging extension, and passed as the `message` parameter in `MessagingDelegate` protocol methods.

# Public variables

## id

Identifier of the `Message`.

```swift
public var id: String
```

## autoTrack

If set to `true` (default), Experience Edge events will automatically be generated when this `Message` is triggered, displayed, and dismissed.

```swift
public var autoTrack: Bool = true
```

## view

Holds a reference to the message's `WKWebView` instance, if it exists.

```swift
public var view: UIView? {
    fullscreenMessage?.webView
}
```

# Public functions

## show

Signals to the UIService (in `AEPServices`) that the message should be shown.

If `autoTrack` is true, calling this method will result in an "inapp.trigger" Edge Event being dispatched.

```swift
public func show()
```

## dismiss

Signals to the UIService that the message should be removed from the UI.

If `autoTrack` is true, calling this method will result in an "inapp.dismiss" Edge Event being dispatched.

```swift
public func dismiss(suppressAutoTrack: Bool? = false)
```

###### Parameters

- _suppressAutoTrack_ - if set to `true`, the "inapp.dismiss" Edge Event will not be sent regardless of the `autoTrack` setting.

## track

Generates and dispatches an Edge Event for the provided `interaction` and `eventType`.

```swift
public func track(_ interaction: String?, withEdgeEventType eventType: MessagingEdgeEventType)
```

###### Parameters

- _interaction_ - a custom `String` value to be recorded in the interaction
- _eventType_ - the [`MessagingEdgeEventType`](./enum-messaging-edge-event-type.md) to be used for the ensuing Edge Event

## handleJavascriptMessage

Adds a handler for named Javascript messages sent from the message's `WKWebView`.

The parameter passed to `handler` will contain the body of the message passed from the `WKWebView`'s Javascript.

```swift
public func handleJavascriptMessage(_ name: String, withHandler handler: @escaping (Any?) -> Void)
```

###### Parameters

- _name_ - the name of the message that should be handled by `handler`
- _handler_ - the method or closure to be called with the body of the message created in Message's Javascript

For more information on how to use `handleJavascriptMessage`, read [Call native code from the Javascript of an in-app message](./how-to-call-native-from-javascript.md).

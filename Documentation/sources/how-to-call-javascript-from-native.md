# Execute JavaScript code in an in-app message from native code

It is possible to execute JavaScript in an in-app message from native code.  To do this, complete the following steps:

- [Implement and assign a `MessagingDelegate`](#implement-and-assign-a-messagingdelegate)
- [Obtain a reference to the `WKWebView`](#obtain-a-reference-to-the-wkwebview)
- [Call the JavaScript method](#call-the-JavaScript-method)

## Implement and assign a `MessagingDelegate`

To register a JavaScript event handler with a `Message` object, the developer will first need to implement and set a `MessagingDelegate`.

[This page describes how to implement and use a MessagingDelegate](./how-to-messaging-delegate.md).

## Obtain a reference to the `WKWebView`

In the `shouldShowMessage` function of the `MessagingDelegate`, get a reference to the `WKWebView` used by the message.  

```swift
func shouldShowMessage(message: Showable) -> Bool {
    // access to the whole message from the parent
    let fullscreenMessage = message as? FullscreenMessage
    let message = fullscreenMessage?.parent

    let messageWebView = message?.view as? WKWebView

    ...
}
```

## Call the JavaScript method

With a reference to the `WKWebView`, the instance method `evaluateJavaScript(_:completionHandler:)` can now be leveraged to call a JavaScript method.

Further details of this API are explained in the [Apple documentation](https://developer.apple.com/documentation/webkit/wkwebview/1415017-evaluateJavaScript) - the example below is provided for the purpose of demonstration:

```swift
func shouldShowMessage(message: Showable) -> Bool {
    // access to the whole message from the parent
    let fullscreenMessage = message as? FullscreenMessage
    let message = fullscreenMessage?.parent

    // the `shouldShowMessage` delegate method is called on a background thread.
    // need to dispatch code that uses the webview back to the main thread.
    DispatchQueue.main.async {
        let messageWebView = message?.view as? WKWebView

        messageWebView?.evaluateJavaScript("startTimer();") { result, error in
            if error != nil {
                // handle error
                return
            }

            if result != nil {
                // do something with the result
            }
        }                
    }

    ...
}
```

## Examples

The test apps in this repository demonstrate executing JavaScript code from an in-app message's webview:

- [Swift](./../../TestApps/MessagingDemoApp/)
- [Objective-c](./../../TestApps/MessagingDemoAppObjC/)
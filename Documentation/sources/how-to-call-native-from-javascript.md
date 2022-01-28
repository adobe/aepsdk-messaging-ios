# Call native code from the Javascript of an in-app message

It is now possible to handle events from in-app message interactions in the native code of your application. This can be achieved by completing the following steps:

- Implement and assign a `MessagingDelegate`
- Register a Javascript handler for your In-App Message
- Post the Javascript message from your In-App Message

### Implement and assign a `MessagingDelegate`

To register a Javascript event handler with a `Message` object, the developer will need to implement and set a `MessagingDelegate`.

[This page describes how to implement a MessagingDelegate](./how-to-messaging-delegate.md).

### Register a Javascript handler for your In-App Message

In the `shouldShowMessage` function of the `MessagingDelegate`, call [`handleJavascriptMessage(_:withHandler)`](./class-message.md#handlejavascriptmessage(_:withhandler)) to register your handler.

The name of the message you intend to pass from the Javascript side should be specified in the first parameter.

The below example shows a handler that dispatches an "inapp.interact" Experience Event natively when the Javascript of the in-app message posts a "myInappCallback" message:

```swift
func shouldShowMessage(message: Showable) -> Bool {    
    let fullscreenMessage = message as? FullscreenMessage
    let message = fullscreenMessage?.parent

    // in-line handling of javascript calls
    message?.handleJavascriptMessage("myInappCallback") { content in
        print("javascript body passed to native callback: \(content ?? "empty")")
        message?.track(content as? String, withEdgeEventType: .inappInteract)
    }

    return true
}
```

### Post the Javascript message from your In-App Message

Now that the in-app message has been displayed, the final step is to post the javascript message.

Continuing from the previous example, the developer is going to post the "myInappCallback" message from their HTML, which will in turn call the handler previously configured:

(The HTML in this example is intended only to demonstrate how the functionality works.)

```html
<html>
    <head>
        <script type="text/javascript">
            function callNative(action) {
                try {
                    // the name of the message handler is the same name that must be registered in native code.
                    // in this case the message name is "myInappCallback"
                    webkit.messageHandlers.myInappCallback.postMessage(action);
                } catch(err) {
                    console.log('The native context does not exist yet'); }
                }
            </script>
    </head>
    <body>
        <button onclick="callNative('native callbacks are cool!')">Native callback!</button>
    </body>
</html>
```

When the user clicks the button inside of this in-app message, the handler configured in the previous step will be called. The handler will send an Experience Event tracking the interaction, and print the following message to the console: 

    javascript body passed to native callback: native callbacks are cool!

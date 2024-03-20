# In-App Messaging APIs

This document details how to use the APIs provided by the AEPMessaging framework for displaying In-App Messages.

For more in-depth information about the Messaging extension, visit the [official SDK documentation for Adobe Journey Optimizer Messaging extension](https://aep-sdks.gitbook.io/docs/using-mobile-extensions/adobe-journey-optimizer).


#### Programmatically refresh in-app message definitions from the remote

By default, the SDK will automatically fetch in-app message definitions from the remote at the time the Messaging extension is registered. This generally happens once per app lifecycle, in the `application(_: didFinishLaunchingWithOptions:)` method of the `AppDelegate`.

Some use cases may require the client to request an update from the remote more frequently. Calling the following API will force the Messaging extension to get an updated definition of messages from the remote:

```swift
Messaging.refreshInAppMessages()
```

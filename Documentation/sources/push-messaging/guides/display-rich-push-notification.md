# Display rich push notifications

You must use a Notification Service app extension to download images or other media attachments for the notification before displaying it on user's iOS device.

Follow Apple's documentation to [Add a Notification Service app extension to your project](https://developer.apple.com/documentation/usernotifications/modifying_content_in_newly_delivered_notifications#2942063).

## Installation

The `AEPMessagingNotification` package is a lightweight extension-safe library with no dependency on `AEPCore` or `AEPServices`. It is safe to import inside a `UNNotificationServiceExtension` target.

**Swift Package Manager**

Add `AEPMessagingNotification` as a dependency in your `Package.swift` or via Xcode's **File > Add Packages** menu.

**CocoaPods**

Add the pod to your Notification Service Extension target in your `Podfile`:

```ruby
target 'NotificationService' do
  pod 'AEPMessagingNotification'
end
```

## MessagingNotificationHelper

`MessagingNotificationHelper` (Objective-C: `AEPMessagingNotificationHelper`) handles downloading the media from the `adb_media` key in the push payload and attaching it to the notification content.

| Feature | Detail |
|---|---|
| Supported media | Images (JPG, PNG, GIF), Video (MP4), Audio (MP3, WAV, AIFF, M4A) |
| URL scheme | HTTPS only |
| Fallback | Notification delivers without attachment if download fails |

## Notification Service Extension Implementation

### Swift

```swift
import AEPMessagingNotification
import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest,
                             withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent

        guard let content = bestAttemptContent else {
            contentHandler(request.content)
            return
        }

        MessagingNotificationHelper.processNotificationRequest(with: content, contentHandler: contentHandler)
    }

    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Deliver the best attempt at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}
```

### Objective-C

```objc
#import <AEPMessagingNotification/AEPMessagingNotification-Swift.h>
#import <UserNotifications/UserNotifications.h>

@interface NotificationService : UNNotificationServiceExtension
@property (nonatomic, copy) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;
@end

@implementation NotificationService

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request
                   withContentHandler:(void (^)(UNNotificationContent *))contentHandler {
    self.contentHandler = contentHandler;
    self.bestAttemptContent = [request.content mutableCopy];

    if (self.bestAttemptContent) {
        [AEPMessagingNotificationHelper processContent:self.bestAttemptContent
                                   withContentHandler:contentHandler];
    } else {
        contentHandler(request.content);
    }
}

- (void)serviceExtensionTimeWillExpire {
    // Called just before the extension will be terminated by the system.
    // Deliver the best attempt at modified content, otherwise the original push payload will be used.
    if (self.contentHandler && self.bestAttemptContent) {
        self.contentHandler(self.bestAttemptContent);
    }
}

@end
```

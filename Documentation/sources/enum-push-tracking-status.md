# PushTrackingStatus

Enum representing the status of push tracking.

### Definition

```java
@objc(AEPPushTrackingStatus)
public enum PushTrackingStatus: Int {
    case trackingInitiated
    case noDatasetConfigured
    case noTrackingData
    case invalidMessageId
    case unknownError
}
```


| Enum                    | Description                       |
| ----------------------- | --------------------------------- |
| trackingInitiated          | This status is returned when all the required data for tracking is available and tracking is initiated.  |
| noDatasetConfigured         | This status is returned when tracking is not initiated because no tracking dataset is configured. |
| noTrackingData          | This status is returned when tracking is not initiated because the intent does not contain tracking data.|
| invalidMessageId | This status is returned when tracking is not initiated because the message id is invalid.  |
| unknownError      | This status is returned when tracking is not initiated because of an unknown error.      |

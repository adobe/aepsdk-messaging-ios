# Review SDK installation instructions

In this section is for reference only.  It covers how to get access to the **AEPMessaging** SDK extension that supports in-app messaging in AJO. 

The screenshots taken in this section are from the [SDK documentation](https://developer.adobe.com/client-sdks/documentation/iam/setup/) during the AEPMessaging beta. Ignore the part about pointing to the `staging` branch of the repo, as that is no longer a requirement.

### Install the AEPMessaging extension

To install the **AEPMessaging** beta SDK, use the following in your Cocoapods `Podfile`:

    pod 'AEPMessaging'

| ![Installing the Messaging extension](assets/docs-install.png?raw=true) |
| :---: |
| **Installing the Messaging extension** |

> [!TIP]
> For details on installation using SPM or XCFrameworks, [refer to this page](./../../getting-started/install-sdk-extensions.md).

### Register the AEPMessaging extension

To initialize the **AEPMessaging** extension in your app, `import` it and include `Messaging.self` in your list of extensions.

> [!NOTE]
> When the AEPMessaging extension is registered by the Adobe AEP SDK, it will automatically attempt to fetch in-app messages for the device based on the app configuration.

| ![Registering the Messaging extension](assets/docs-register.png?raw=true) |
| :---: |
| **Registering the Messaging extension** |

# Assurance Validation

Optimize extension, and mobile SDK extensions in general, integrate with [Assurance](https://experience.adobe.com/assurance) which helps to:

* Inspect and validate SDK events
* Verify extension versions and configuration
* View SDK logs, device information and much more...

## Create Assurance Session

Follow the steps below to create an Assurance session:

1. Navigate to the Data Collection UI by selecting the nine-dot menu in the top right (**1**), and selecting `Data Collection` (**2**).

| ![Navigating to Data Collection](assets/nav-dc.png?raw=true) |
| :---: |
| **Navigating to Data Collection** |

1. Navigate to Assurance.

| ![Navigating to Data Collection](assets/assurance-nav.png?raw=true) |
| :---: |
| **Navigating to Data Collection** |

1. Click on **Create Session**.

| ![Create Assurance Session](assets/assurance-create-session.png?raw=true) |
| :---: |
| **Create Assurance Session** |

2. In the **Create New Session** dialog, click on **Start (1)**.

| ![Create Assurance Session - Start](assets/assurance-start-session.png?raw=true) |
| :---: |
| **Create Assurance Session - Start** |

3. Next, provide the **Session Name (1)** as `Optimize Tutorial Session` and the **Base URL (2)** as `optimizetutorial://`. Click **Next (3)**.

| ![Create Assurance Session - Provide Details](assets/assurance-session-info.png?raw=true) |
| :---: |
| **Create Assurance Session - Provide Details** |

>[!NOTE]
> For more details on `BASE URL`, see article [Defining custom URL scheme for your app](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app).

4. A new Assurance session is created and the provided QR Code or Link can be used to connect to the session. Select **Copy Link (1)** and 
click on the copy icon (2) to select the link. Make a note of the the <small>PIN</small> (3). Click **Done (4)**.

|![Assurance Session - QR Code](assets/assurance-copy-link-pin.png?raw=true) | ![Assurance Session - Link](assets/assurance-app-enter-pin.png?raw=true) |
| :---: | :---: |
|**Assurance Session - QR Code** | **Assurance Session - Link** |






5. You will notice that the created `Optimize Tutorial Session` has **0 Clients Connected (1)** at this time!

| ![Assurance Session - No Client Connected](assets/assurance-install-messaging-plugin.png?raw=true) |
| :---: |
| **Assurance Session - No Client Connected** |

| ![Assurance Session - No Client Connected](assets/assurance-messaging-plugin.png?raw=true) |
| :---: |
| **Assurance Session - No Client Connected** |

> [!NOTE]
> Assurance sessions are deleted after a period of 30 days.


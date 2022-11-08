# Assurance Validation

Optimize extension, and mobile SDK extensions in general, integrate with [Assurance](https://experience.adobe.com/assurance) which helps to:

* Inspect and validate SDK events
* Verify extension versions and configuration
* View SDK logs, device information and much more...

## Create Assurance Session

Follow the steps below to create an Assurance session:

1. In the browser, navigate to https://experience.adobe.com/assurance. Click on **Create Session**.

| ![Create Assurance Session](../assets/assurance-session-create.png?raw=true) |
| :---: |
| **Create Assurance Session** |

2. In the **Create New Session** dialog, click on **Start (1)**.

| ![Create Assurance Session - Start](../assets/assurance-session-create-start.png?raw=true) |
| :---: |
| **Create Assurance Session - Start** |

3. Next, provide the **Session Name (1)** as `Optimize Tutorial Session` and the **Base URL (2)** as `optimizetutorial://`. Click **Next (3)**.

| ![Create Assurance Session - Provide Details](../assets/assurance-session-create-details.png?raw=true) |
| :---: |
| **Create Assurance Session - Provide Details** |

>[!NOTE]
> For more details on `BASE URL`, see article [Defining custom URL scheme for your app](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app).

4. A new Assurance session is created and the provided QR Code or Link can be used to connect to the session. Select **Copy Link (1)** and 
click on the copy icon (2) to select the link. Make a note of the the <small>PIN</small> (3). Click **Done (4)**.

|![Assurance Session - QR Code](../assets/assurance-session-qrcode.png?raw=true) | ![Assurance Session - Link](../assets/assurance-session-link.png?raw=true) |
| :---: | :---: |
|**Assurance Session - QR Code** | **Assurance Session - Link** |

5. You will notice that the created `Optimize Tutorial Session` has **0 Clients Connected (1)** at this time!

| ![Assurance Session - No Client Connected](../assets/assurance-session-no-client.png?raw=true) |
| :---: |
| **Assurance Session - No Client Connected** |

> [!NOTE]
> Assurance sessions are deleted after a period of 30 days.

## Connect to the Assurance Session

Follow the setps below to connect to a created Assurance Session:

1. Open the browser on the simulator (or device), paste the Assurance Session Link in the search bar (1) and press return. A dialog requesting to open the page in the tutorial app should show. Click **Open (2)**.

| ![Assurance Link - Open in browser](../assets/assurance-link-browser.png?raw=true) | ![Assurance Link - App Open](../assets/assurance-link-app-open.png?raw=true)
| :---: | :---: |
| **Assurance Link - Open in browser** | **Assurance Link - App Open** |

2. The app should open and the PIN authentication screen should show. Enter the <small>PIN</small> (1) noted previously (or read it again by clicking **Session Details** in the created Assurance Session) and click **Connect (2)**. Once connected, a green dot will appear next to the Experience Platform icon (3) indicating that the connection was successful.

|![Assurance Session - Pin Authentication](../assets/assurance-session-pin-auth.png?raw=true)  | ![Assurance Session - Connection Successful](../assets/assurance-session-connection-successful.png?raw=true) |
| :---: | :---: |
| **Assurance Session - Pin Authentication** | **Assurance Session - Connection Successful** |

3. You can verify that the Assurance session `Optimize Tutorial Session` now shows **1 Client Connected (1)**!

| ![Assurance Session - Client Connected](../assets/assurance-session-client-connected.png?raw=true) |
| :---: |
| **Assurance Session - Client Connected** |

## SDK Events Validation

### Edge Transactions View

Select the **Event Transactions (1)** view under <small>ADOBE EXPERIENCE PLATFORM EDGE</small> in the left navigation bar. This view helps visualize the events as they flow from Client Side -> Edge Network -> Upstream Services.

| ![Assurance Edge Transactions View - Personalization Query](../assets/assurance-edge-transactions-personalization-query.png?raw=true) |
| :---: |
| **Assurance Edge Transactions View - Personalization Query** |

The example above illustrates a personalization query request (sent usually upon `updatePropositions` API call) from the client-side (2) was successfully received and processed by the Edge Network (3). It passed the streaming validation (3) and the upstream request sent to Target returned a successful response (4). Also, the `AEP response Event Handle`s (1) containing `personalization:decisions` were successfully received by the client.

### Events View

The raw **Events (1)** view can be used to inspect and verify the SDK events dispatched by the various extensions. You can also use the search bar to filter and inspect any events of interest.

| ![Assurance Events View - Optimize Update Propositions Request](../assets/assurance-events-update-propositions.png?raw=true) |
| :---: |
| **Assurance Events View - Optimize Update Propositions Request** |

The example above illustrates use of search bar to search for `Update Propositions` request (2). The view filters and displays the corresponding event(s) (3). Clicking on the event displays the event details in the right panel. The arrow next to <small>RAW EVENT</small> can be clicked (4), to display the event data for verification.

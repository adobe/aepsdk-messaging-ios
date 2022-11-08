# Optimize Tutorial: Fetch and track Target Offers

## Getting Started

Follow the steps below to download the Optimize Tutorial Starter App from the [Optimize GitHub repository](https://github.com/adobe/aepsdk-optimize-ios).

1. Navigate to the GitHub repository using the URL https://github.com/adobe/aepsdk-optimize-ios/tree/optimize-target-tutorial.

2. Click on **Code (1)** then select **Download ZIP (2)** from the pop-up dialog.

| ![Optimize Extension Code](../../assets/optimize-github-code.png?raw=true) |
| :---: |
| **Optimize GitHub Code** |

3. Copy the `aepsdk-optimize-ios-optimize-target-tutorial.zip` file from Downloads directory to another appropriate location. For example, your home directory

**Command-line command**
```text
mv ~/Downloads/aepsdk-optimize-ios-optimize-target-tutorial.zip ~/
```

4. Unzip the file in the target location.

**Command-line command**
```text
cd ~/
unzip aepsdk-optimize-ios-optimize-target-tutorial.zip
```

5. Change directory to the `OptimizeTutorialStarterApp`

**Command-line command**
```text
cd aepsdk-optimize-ios-optimize-target-tutorial/docs/tutorials/OptimizeTutotialStarterApp
```

6. Open Xcode workspace file `OptimizeTutorialStarterApp.xcworkspace` in Xcode.

**Command-line command**
```text
open OptimizeTutorialStarterApp.xcworkspace
```

## Install AEPOptimize SDK Extension in your mobile application

Follow the steps in [Install SDK Extensions guide](https://opensource.adobe.com/aepsdk-optimize-ios/#/tutorials/mobile-app/install-sdk-extensions) to install AEPOptimize SDK extension and its dependencies in your mobile application.

For this tutorial, the `OptimizeTutorialStarterApp` uses [CocoaPods](https://guides.cocoapods.org/using/getting-started.html) for dependency management. The `Podfile` is already integrated in the workspace and the pod dependencies are installed. Verify `Podfile.lock` to inspect the dependency versions.

## Initialize the mobile SDK

Follow the steps in [Initialize SDK guide](https://opensource.adobe.com/aepsdk-optimize-ios/#/tutorials/mobile-app/init-sdk) to initialize the Experience Platform mobile SDK by registering the SDK extensions with `Mobile Core`.

For this tutorial, initlization code is already implemented in `OptimizeTutorialStarterApp`.

## Enable Optimize API implementation code

Follow the steps below to enable the SDK implementation code:

1. In Xcode, expand `OptimizeTutorialStarterApp` project. You will see all the `.swift` source files in `OptimizeTutorialStarterApp` folder. Select `AppDelegate.swift` file and provide your `DATA_COLLECTION_ENVIRONMENT_FILE_ID` value. For more details, see [Getting the Environment File ID guide](https://opensource.adobe.com/aepsdk-optimize-ios/#/tutorials/setup/create-tag-property?id=getting-the-environment-file-id).

| ![AppDelegate - Configure Data Collection Environment File ID](../../assets/mobile-app-appdelegate.png?raw=true) |
| :---: |
| **AppDelegate - Configure Data Collection Environment File ID** |

2. Click on the search icon (1) and enter text `Optimize Tutorial: CODE SECTION` in the search bar (2). It will list all the code implementation sections for this tutorial. The code sections follow the below format:

```text
/* Optimize Tutorial: CODE SECTION n/m BEGINS
...
Code Implementation
...
// Optimize Tutorial: CODE SECTION n ENDS */
```
where n = Current section number, m = Total number of sections in the mobile app

| ![Mobile App - Code Implementation Search](../../assets/mobile-app-code-section-search.png?raw=true) |
| :---: |
| **Mobile App - Code Implementation Search** |


3. Enable all the code sections sequentially, simply by adding a forward slash (/) at the beginning of every `/* Optimize Tutorial: CODE SECTION n/m BEGINS` statement:

```text
//* Optimize Tutorial: CODE SECTION n/m BEGINS
```

| ![Mobile App - Code Implementation Enable](../../assets/mobile-app-code-section-enable.png?raw=true) |
| :---: |
| **Mobile App - Code Implementation Enable** |

## Run the mobile application

Follow the steps below to run the `OptimizeTutorialStarterApp` app:

1. Select the mobile app target **OptimizeTutorialStarterApp (1)** and the destination device e.g. iPhone 11 Pro Max simulator (2). Click on Play icon (3).

| ![Run Mobile App](../../assets/mobile-app-run.png?raw=true) |
| :---: |
| **Run Mobile App** |

2. You should see the mobile app running on your simulator device.

|![Offers View](../../assets/mobile-app-offers-view.png?raw=true) | ![Settings View](../../assets/mobile-app-settings-view.png?raw=true) |
| :---------: | :------------: |
| **Offers View** |  **Settings View** |
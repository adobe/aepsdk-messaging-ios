// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

/*
 Copyright 2020 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import PackageDescription

let package = Package(
    name: "AEPMessaging",
    platforms: [.iOS(.v10)],
    products: [
        .library(name: "AEPMessaging", targets: ["AEPMessaging"]),
        .library(name: "AEPMessagingStatic", type: .static, targets: ["AEPMessaging"]),
        .library(name: "AEPMessagingDynamic", type: .dynamic, targets: ["AEPMessaging"])
    ],
    dependencies: [
        .package(url: "https://github.com/adobe/aepsdk-core-ios.git", .branch("main")),
        .package(url: "https://github.com/adobe/aepsdk-edge-ios.git", .branch("dev"))
    ],
    targets: [
        .target(name: "AEPMessaging",
                dependencies: ["AEPCore", "AEPEdge"],
                path: "Sources"),
        .testTarget(name: "MessagingDemoApp",
                    dependencies: ["AEPMessaging", "AEPEdge", "AEPCore", "AEPIdentity", "AEPLifecycle", "AEPSignal"],
                    path: "SampleApps/MessagingDemoApp"),
        .testTarget(name: "UnitTests",
                    dependencies: ["AEPMessaging"],
                    path: "Tests/UnitTests")
    ]
)

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
    name: "ACPMessaging",
    platforms: [.iOS(.v10)],
    products: [
        .library(name: "ACPMessaging", targets: ["ACPMessaging"]),
        .library(name: "AEPExperiencePlatformStatic", type: .static, targets: ["ACPMessaging"]),
        .library(name: "AEPExperiencePlatformDynamic", type: .dynamic, targets: ["ACPMessaging"]),
    ],
    dependencies: [
        .package(url: "https://github.com/adobe/aepsdk-core-ios.git", .branch("main")),
        //.package(url: "https://github.com/adobe/aepsdk-platform-ios.git", .branch("dev"))
        .package(url: "https://github.com/kevinlind/platform-extension-ios.git", .branch("amsdk-10442-cleanup"))
    ],
    targets: [
        .target(name: "ACPMessaging",
                dependencies: ["AEPCore", "AEPExperiencePlatform"],
                path: "code/src"),
        .testTarget(name: "MessagingDemoApp",
                    dependencies: ["ACPMessaging", "AEPExperiencePlatform", "AEPCore"],
                    path: "demo/MessagingDemoApp"),
        .testTarget(name: "unitTests",
                    dependencies: ["ACPMessaging"],
                    path: "code/unitTests")
    ]
)
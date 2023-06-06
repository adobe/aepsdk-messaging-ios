# Aligning major version releases for the Adobe iOS SDK

### Why are we getting another major update already?

Apple has started doing an annual requirement to increase the minimum version of Xcode used when submitting to the App Store.  Each Xcode version only supports back to a specific minimum version of iOS.  Loosly speaking, Xcode version and _minimum_ iOS version are correlated.  

https://developer.apple.com/ios/submit/

In order to align with Apple's changing requirements, Adobe will also be doing an annual major release of its iOS SDKs.  In this yearly major update, you can expect the following changes:
  - Increasing the minimum supported version of iOS.
  - Increasing the minimum supported version of Xcode.
  - Possible increase to minimum supported version of Swift.

### Why are all the extensions updating to major version 4?

The main goal is to simplify the Adobe SDK distibution.  Aliging all extesions on the same major version allows us to create predictability.  For example:
  - All Adobe-owned SDK extensions that share a major version are compatible with one another.
  - Each major version of an Adobe-owned SDK extension has a designated minimum OS version.

### Why did some of the extensions skip major versions?

You may be wondering "what happened to versions 2 and 3 of AEPEdge?"  Our apologies for any confusion this may cause.  In order to achieve our goal of unifying major versions, some extensions, AEPEdge for example, had to skip one or more major versions.  Hopefully the our explaination above has shed light on this anomoly.

### What will happen with new extensions?

A new extension - that is, an extension getting its first public release - will be released with the same major version as AEPCore.  As part of this major update we are introducing a new extension, AEPEdgeMedia.  As you would expect, the first version of this extension will be AEPEdgeMedia v4.0.0

### Will I have to re-implement the SDK?

Unlike our previous major version updates, this is not a major re-write.  You should expect all of your API calls in the previous major version of the SDK to continue working with the new version (with the exception of previously deprecated APIs - more on that later).

While we don't have plans for another major rewrite any time soon, if a need for one comes up, we will be sure to let you know with plenty of lead time.

### How does this impact the SDK going forward?

For starters, having more frequent updates allows us to better take advantage of new frameworks and APIs introduced by Apple.  This will help us achieve a more modern SDK.

A more subtle benefit of regular major releases is that we can safely remove deprecated APIs from the SDK.  Over time, our API footprint can become bloated as requirements change internally.  Methods that were no longer preferred would get marked as deprecated, but would have to remain in the public API to preserve backwards compatibility within a major version.  Starting with version 4.x of Adobe's iOS SDKs, you can expect any public API that has been marked for deprecation to be removed in the following major release.  This means less confusion for your developers, and less maintainence for the team managing the Adobe SDKs - win/win.

### What about Android?

Google has been making regular requirements to [increase target API levels for Google Play apps](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en#).  While this requirement is not technically a change that breaks backwards compatibility, aligning major version updates of the Adobe Android SDKs with their deadlines gives us the opportunity to take advantage of the same benefits described above.  With that in mind, you can plan to see yearly major releases for Adobe's Android SDK extensions as well.`
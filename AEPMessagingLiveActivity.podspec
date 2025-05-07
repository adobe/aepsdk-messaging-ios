Pod::Spec.new do |s|
  s.name         = "AEPMessagingLiveActivity"
  s.version      = "5.7.0"
  s.summary      = "MessagingLiveActivity extension for Adobe Experience Cloud SDK. Written and maintained by Adobe."
  s.description  = <<-DESC
                   The MessagingLiveActivity extension is used in conjunction AEPMessaging to support live activities for Adobe Journey Optimizer.
                   DESC

  s.homepage     = "https://github.com/adobe/aepsdk-messaging-ios.git"
  s.license      = { :type => "Apache License, Version 2.0", :file => "LICENSE" }
  s.author       = "Adobe Experience Platform Messaging SDK Team"
  s.source       = { :git => 'https://github.com/adobe/aepsdk-messaging-ios.git', :tag => s.version.to_s }
  
  s.platform = :ios, "12.0"
  s.swift_version = '5.1'

  s.source_files = 'AEPMessagingLiveActivity/Sources/**/*.swift'

  s.pod_target_xcconfig = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES' }

end

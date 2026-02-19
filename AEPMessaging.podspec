Pod::Spec.new do |s|
  s.name         = "AEPMessaging"
  s.version      = "5.10.0"
  s.summary      = "Messaging extension for Adobe Experience Cloud SDK. Written and maintained by Adobe."
  s.description  = <<-DESC
                   The Messaging extension is used in conjunction with Adobe Journey Optimizer and Adobe Experience Platform to deliver in-app and push messages.
                   DESC

  s.homepage     = "https://github.com/adobe/aepsdk-messaging-ios.git"
  s.license      = { :type => "Apache License, Version 2.0", :file => "LICENSE" }
  s.author       = "Adobe Experience Platform Messaging SDK Team"
  s.source       = { :git => 'https://github.com/adobe/aepsdk-messaging-ios.git', :tag => s.version.to_s }
  
  s.platform = :ios, "12.0"
  s.swift_version = '5.1'

  s.pod_target_xcconfig = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES' }
  s.dependency 'AEPCore', '>= 5.8.0', '< 6.0.0'
  s.dependency 'AEPServices', '>= 5.8.0', '< 6.0.0'
  s.dependency 'AEPEdge', '>= 5.0.2', '< 6.0.0'
  s.dependency 'AEPEdgeIdentity', '>= 5.0.0', '< 6.0.0'

  s.source_files = 'AEPMessaging/Sources/**/*.swift'

end

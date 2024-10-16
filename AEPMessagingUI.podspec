Pod::Spec.new do |s|
  s.name         = "AEPMessagingUI"
  s.version      = "5.5.0"
  s.summary      = "AEPMessagingUI library for Adobe Experience Cloud SDK. Written and maintained by Adobe."
  s.description  = <<-DESC
                   The AEPMessagingUI library offers UI for building content cards and integrates with messaging extensions.
                   DESC
  s.homepage     = "https://github.com/adobe/aepsdk-messaging-ios.git"
  s.license      = { :type => "Apache License, Version 2.0", :file => "LICENSE" }
  s.author       = "Adobe Experience Platform SDK Team"
  s.source       = { :git => 'https://github.com/adobe/aepsdk-messaging-ios.git', :tag => s.version.to_s }
  
  s.platform = :ios, "12.0"
  s.swift_version = '5.1'

  s.source_files = 'AEPMessagingUI/Sources/**/*.swift'

  s.pod_target_xcconfig = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES' }
  s.dependency 'AEPMessaging', '>= 5.5.0', '< 6.0.0'

end


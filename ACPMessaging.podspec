Pod::Spec.new do |s|
  s.name         = "ACPMessaging"
  s.version      = "1.0.0-alpha-2"
  s.summary      = "Messaging extension for Adobe Experience Cloud SDK. Written and maintained by Adobe."
  s.description  = <<-DESC
                   The Messaging extension is used in conjunction with Adobe Experience Platform to deliver in-app and push messages.
                   DESC

  s.homepage     = "https://github.com/adobe/aepsdk-messaging-ios.git"
  s.license      = { :type => "Apache License, Version 2.0", :file => "LICENSE" }
  s.author       = "Adobe Experience Platform Messaging SDK Team"
  s.source       = { :git => 'https://github.com/adobe/aepsdk-messaging-ios.git', :tag => "v#{s.version}-#{s.name}" }
  s.platform = :ios, "10.0"
  s.swift_version = '5.0'

  s.pod_target_xcconfig = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES' }
  s.dependency 'AEPCore'
  s.dependency 'AEPServices'
  s.dependency 'AEPExperiencePlatform'
  
  s.source_files = 'code/src/**/*.swift'

end

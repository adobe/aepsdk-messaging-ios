Pod::Spec.new do |s|
  s.name         = "ACPMessaging"
  s.version      = "0.0.1"
  s.summary      = "Messaging extension for Adobe Experience Cloud SDK. Written and maintained by Adobe."
  s.description  = <<-DESC
                   The Messaging extension is used in conjunction with Adobe Experience Platform to deliver in-app and push messages.
                   DESC

  s.homepage     = "https://github.com/adobe/ACPPlacesMonitor"

  s.license      = "Apache License, Version 2.0"
  s.author       = "Adobe Experience Platform SDK Team"
  s.source       = { :git => 'https://github.com/adobe/aepsdk-messaging-ios.git', :tag => "v#{s.version}-#{s.name}" }
  s.platform = :ios, "10.0"
  s.requires_arc = true

  s.default_subspec = "iOS"

  s.static_framework = true

  s.dependency "ACPCore", ">= 2.6.0"

  s.subspec "iOS" do |ios|
    ios.public_header_files = "ACPMessaging/ACPMessaging.h"
    ios.source_files = "ACPMessaging/*.{h,m}"    
  end

end

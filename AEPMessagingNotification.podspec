Pod::Spec.new do |s|
  s.name         = 'AEPMessagingNotification'
  s.version      = '5.14.0'
  s.summary      = 'Lightweight helper for rich push notifications in Adobe Experience Platform Mobile SDK.'
  s.description  = <<-DESC
                   AEPMessagingNotification provides a lightweight helper for processing rich push notifications
                   in Notification Service Extensions. This module has no dependencies on AEPCore or AEPServices,
                   making it suitable for use in app extensions.
                   DESC

  s.homepage     = 'https://github.com/adobe/aepsdk-messaging-ios.git'
  s.license      = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
  s.author       = 'Adobe Experience Platform Messaging SDK Team'
  s.source       = { :git => 'https://github.com/adobe/aepsdk-messaging-ios.git', :tag => s.version.to_s }

  s.platform     = :ios, '12.0'
  s.swift_version = '5.1'

  s.pod_target_xcconfig = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES' }

  s.source_files = 'AEPMessagingNotification/Sources/**/*.swift'
end

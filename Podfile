# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

# Comment the next line if you don't want to use dynamic frameworks
use_frameworks!

workspace 'AEPMessaging'
project 'AEPMessaging.xcodeproj'

target 'AEPMessaging' do
  pod 'AEPCore'
  pod 'AEPServices'
  pod 'AEPRulesEngine'
end

target 'MessagingDemoApp' do
  pod 'AEPCore'
  pod 'AEPServices'
  pod 'AEPRulesEngine'
  pod 'AEPLifecycle'
  pod 'AEPIdentity'
  pod 'AEPEdge'
  pod 'AEPSignal'
  pod 'ACPCore', :git => 'https://github.com/adobe/aep-sdk-compatibility-ios.git', :branch => 'main'
  pod 'AEPAssurance'
end

target 'UnitTests' do
  pod 'AEPCore'
  pod 'AEPServices'
  pod 'AEPRulesEngine'
end

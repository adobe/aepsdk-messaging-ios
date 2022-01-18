# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

# Comment the next line if you don't want to use dynamic frameworks
use_frameworks!

# don't warn me
install! 'cocoapods', :warn_for_unused_master_specs_repo => false

workspace 'AEPMessaging'
project 'AEPMessaging.xcodeproj'

pod 'SwiftLint', '0.44.0'

# ==================
# SHARED POD GROUPS
# ==================
def core_main
    pod 'AEPCore'
    pod 'AEPServices'
    pod 'AEPLifecycle'
    pod 'AEPRulesEngine'
    pod 'AEPSignal'
    pod 'AEPEdge'
    pod 'AEPEdgeConsent'
    pod 'AEPEdgeIdentity'
    # optimize has source copied locally until its public release
    # pod 'AEPOptimize', :git => 'https://github.com/adobe/aepsdk-optimize-ios.git', :branch => 'dev'
end

def core_dev
    pod 'AEPCore', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'feature-iam'
    pod 'AEPServices', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'feature-iam'
    pod 'AEPLifecycle', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'feature-iam'
    pod 'AEPSignal', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'feature-iam'
    pod 'AEPRulesEngine', :git => 'https://github.com/adobe/aepsdk-rulesengine-ios.git', :branch => 'main'
    pod 'AEPEdge', :git => 'https://github.com/adobe/aepsdk-edge-ios.git', :branch => 'main'
    pod 'AEPEdgeConsent'
    pod 'AEPEdgeIdentity', :git => 'https://github.com/adobe/aepsdk-edgeidentity-ios.git', :branch => 'main'
    # optimize has source copied locally until its public release
    # pod 'AEPOptimize', :git => 'https://github.com/adobe/aepsdk-optimize-ios.git', :branch => 'dev'
    pod 'AEPAnalytics'
end

def griffon_main
  pod 'AEPAssurance'
end

def griffon_dev
    pod 'AEPAssurance', :git => 'https://github.com/adobe/aepsdk-assurance-ios.git', :branch => 'dev'
end

# ==================
# TARGET DEFINITIONS
# ==================
target 'AEPMessaging' do
    core_dev
end

target 'MessagingDemoApp' do
    core_dev
    griffon_main
end

target 'UnitTests' do
    core_dev
end

target 'FunctionalTests' do
    core_dev
end

target 'E2EFunctionalTests' do
    core_dev
end

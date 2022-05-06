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
def lib_main
    pod 'AEPCore'
    pod 'AEPServices'
    pod 'AEPRulesEngine'
    pod 'AEPOptimize', :git => 'https://github.com/adobe/aepsdk-optimize-ios.git', :branch => 'staging'
end

def lib_dev
    pod 'AEPCore', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v3.5.1'
    pod 'AEPServices', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v3.5.1'
    pod 'AEPRulesEngine', :git => 'https://github.com/adobe/aepsdk-rulesengine-ios.git', :branch => 'main'
    pod 'AEPOptimize', :git => 'https://github.com/adobe/aepsdk-optimize-ios.git', :branch => 'staging'
end

def app_main
    pod 'AEPCore'
    pod 'AEPServices'
    pod 'AEPLifecycle'
    pod 'AEPRulesEngine'
    pod 'AEPSignal'
    pod 'AEPEdge'
    pod 'AEPEdgeConsent'
    pod 'AEPEdgeIdentity'
    pod 'AEPAssurance'
    pod 'AEPOptimize', :git => 'https://github.com/adobe/aepsdk-optimize-ios.git', :branch => 'staging'
end

def app_dev
    pod 'AEPCore', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v3.5.1'
    pod 'AEPServices', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v3.5.1'
    pod 'AEPLifecycle', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v3.5.1'
    pod 'AEPSignal', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v3.5.1'
    pod 'AEPRulesEngine', :git => 'https://github.com/adobe/aepsdk-rulesengine-ios.git', :branch => 'main'
    pod 'AEPEdge', :git => 'https://github.com/adobe/aepsdk-edge-ios.git', :branch => 'main'
    pod 'AEPEdgeConsent'
    pod 'AEPEdgeIdentity', :git => 'https://github.com/adobe/aepsdk-edgeidentity-ios.git', :branch => 'main'
    pod 'AEPOptimize', :git => 'https://github.com/adobe/aepsdk-optimize-ios.git', :branch => 'staging'
    pod 'AEPAnalytics'
    pod 'AEPAssurance', :git => 'https://github.com/adobe/aepsdk-assurance-ios.git', :branch => 'main'
end

# ==================
# TARGET DEFINITIONS
# ==================
target 'AEPMessaging' do
    lib_dev
end

target 'MessagingDemoApp' do
    app_dev
end

target 'UnitTests' do
    lib_dev
end

target 'FunctionalTests' do
    app_dev
end

target 'E2EFunctionalTests' do
    app_dev
end

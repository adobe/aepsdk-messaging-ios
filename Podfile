# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

# Comment the next line if you don't want to use dynamic frameworks
use_frameworks!

# don't warn me
install! 'cocoapods', :warn_for_unused_master_specs_repo => false

workspace 'AEPMessaging'
project 'AEPMessaging.xcodeproj'

# ==================
# SHARED POD GROUPS
# ==================
def core_main
#    pod 'AEPCore'
    pod 'AEPCore', :git => 'https://github.com/sbenedicadb/aepsdk-core-ios.git', :branch => 'refactor-historical'
    pod 'AEPServices', :git => 'https://github.com/sbenedicadb/aepsdk-core-ios.git', :branch => 'refactor-historical'
    pod 'AEPLifecycle'
    pod 'AEPRulesEngine', :git => 'https://github.com/adobe/aepsdk-rulesengine-ios.git', :branch => 'dev-v1.1.0'
    pod 'AEPSignal'
    pod 'AEPEdge'
    pod 'AEPEdgeConsent'
    pod 'AEPEdgeIdentity'
    pod 'AEPOptimize', :git => 'https://github.com/adobe/aepsdk-optimize-ios.git', :branch => 'dev'
end

def griffon_main
    pod 'AEPAssurance'
end

def core_dev
    pod 'AEPCore', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v3.2.1'
    pod 'AEPServices', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v3.2.1'
    pod 'AEPLifecycle', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v3.2.1'
    pod 'AEPSignal', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v3.2.1'
    pod 'AEPRulesEngine'#, :git => 'https://github.com/adobe/aepsdk-rulesengine-ios.git', :branch => 'dev-v1.0.0'
    pod 'AEPEdge', :git => 'https://github.com/adobe/aepsdk-edge-ios.git', :branch => 'main'
    pod 'AEPEdgeConsent'
    pod 'AEPEdgeIdentity', :git => 'https://github.com/adobe/aepsdk-edgeidentity-ios.git', :branch => 'main'
    pod 'AEPOptimize', :git => 'https://github.com/adobe/aepsdk-optimize-ios.git', :branch => 'dev'
end

def griffon_dev
    pod 'AEPAssurance', :git => 'https://github.com/adobe/aepsdk-assurance-ios.git', :branch => 'dev'
end

# ==================
# TARGET DEFINITIONS
# ==================
target 'AEPMessaging' do
    core_main
end

target 'MessagingDemoApp' do
    core_main
    griffon_main
end

target 'UnitTests' do
    core_main
end

target 'FunctionalTests' do
    core_main
end

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
    pod 'AEPCore'
    pod 'AEPServices'
    pod 'AEPLifecycle'
    pod 'AEPIdentity'
    pod 'AEPRulesEngine'
    pod 'AEPSignal'
    pod 'AEPEdge'
    pod 'AEPOfferDecisioning', :git => 'git@github.com:adobe/aepsdk-offer-ios.git', :branch => 'main'
end

def griffon_main
    pod 'AEPAssurance'
    pod 'ACPCore', :git => 'https://github.com/adobe/aep-sdk-compatibility-ios.git', :branch => 'main'
end

def core_dev
    pod 'AEPCore', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v3.1.4'
    pod 'AEPServices', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v3.1.4'
    pod 'AEPLifecycle', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v3.1.4'
    pod 'AEPIdentity', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v3.1.4'
    pod 'AEPSignal', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v3.1.4'
    pod 'AEPRulesEngine'#, :git => 'https://github.com/adobe/aepsdk-rulesengine-ios.git', :branch => 'dev-v1.0.0'
    pod 'AEPEdge', :git => 'https://github.com/adobe/aepsdk-edge-ios.git', :branch => 'main'
    pod 'AEPOfferDecisioning', :git => 'git@github.com:adobe/aepsdk-offer-ios.git', :branch => 'dev-v1.0.1'
end

def griffon_dev
    pod 'AEPAssurance' #todo - get a link to this repo once it's public
    pod 'ACPCore', :git => 'https://github.com/adobe/aep-sdk-compatibility-ios.git', :branch => 'main'
end

# ==================
# TARGET DEFINITIONS
# ==================
target 'AEPMessaging' do
    core_dev
end

target 'MessagingDemoApp' do
    core_dev
    griffon_dev
end

target 'UnitTests' do
    core_dev
end

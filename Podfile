source 'https://cdn.cocoapods.org/'

# Uncomment the next line to define a global platform for your project
platform :ios, '12.0'

# Comment the next line if you don't want to use dynamic frameworks
use_frameworks!

# don't warn me
install! 'cocoapods', :warn_for_unused_master_specs_repo => false

workspace 'AEPMessaging'
project 'AEPMessaging.xcodeproj'

pod 'SwiftLint', '0.52.0'

$dev_repo = 'https://github.com/sbenedicadb/aepsdk-core-ios.git'
$dev_branch = 'dev-v5.5.0'

# ==================
# SHARED POD GROUPS
# ==================
def lib_main
    pod 'AEPCore'
    pod 'AEPServices'
    pod 'AEPRulesEngine'
end

def lib_dev
    pod 'AEPCore', :git => $dev_repo, :branch => $dev_branch
    pod 'AEPServices', :git => $dev_repo, :branch => $dev_branch
    pod 'AEPRulesEngine', :git => 'https://github.com/adobe/aepsdk-rulesengine-ios.git', :branch => 'staging'
end

def app_main
    lib_main
    pod 'AEPLifecycle'
    pod 'AEPSignal'
    pod 'AEPEdge'
    pod 'AEPEdgeIdentity'
    pod 'AEPEdgeConsent'
    pod 'AEPAssurance'
end

def app_dev
    lib_dev
    pod 'AEPLifecycle', :git => $dev_repo, :branch => $dev_branch
    pod 'AEPSignal', :git => $dev_repo, :branch => $dev_branch
    pod 'AEPEdge', :git => 'https://github.com/adobe/aepsdk-edge-ios.git', :branch => 'staging'
    pod 'AEPEdgeIdentity', :git => 'https://github.com/adobe/aepsdk-edgeidentity-ios.git', :branch => 'staging'
    pod 'AEPEdgeConsent', :git => 'https://github.com/adobe/aepsdk-edgeconsent-ios.git', :branch => 'staging'
    pod 'AEPAssurance', :git => 'https://github.com/adobe/aepsdk-assurance-ios.git', :branch => 'staging'
end

def test_utils
     pod 'AEPTestUtils', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :tag => 'testutils-5.6.0'

end

# ==================
# TARGET DEFINITIONS
# ==================
target 'AEPMessaging' do
  lib_main
end

target 'MessagingDemoApp' do
  app_main
end

target 'MessagingDemoAppObjC' do
  app_main
end

target 'MessagingDemoAppSwiftUI' do
  app_main
end

target 'UnitTests' do
  lib_main
  test_utils
end

target 'FunctionalTests' do
  app_main
  test_utils
end

target 'IntegrationTests' do
  app_main
  test_utils
end

target 'E2EFunctionalTests' do
  app_main
  test_utils
end

target 'FunctionalTestApp' do
  app_main
  test_utils
end

target 'E2EFunctionalTestApp' do
  app_main
  test_utils
end

export EXTENSION_NAME = AEPMessaging
export APP_NAME = MessagingDemoApp
CURRENT_DIRECTORY := ${CURDIR}
PROJECT_NAME = $(EXTENSION_NAME)
TARGET_NAME_XCFRAMEWORK = $(EXTENSION_NAME).xcframework
SCHEME_NAME_XCFRAMEWORK = AEPMessagingXCF

SIMULATOR_ARCHIVE_PATH = $(CURRENT_DIRECTORY)/build/ios_simulator.xcarchive/Products/Library/Frameworks/
SIMULATOR_ARCHIVE_DSYM_PATH = $(CURRENT_DIRECTORY)/build/ios_simulator.xcarchive/dSYMs/
IOS_ARCHIVE_PATH = $(CURRENT_DIRECTORY)/build/ios.xcarchive/Products/Library/Frameworks/
IOS_ARCHIVE_DSYM_PATH = $(CURRENT_DIRECTORY)/build/ios.xcarchive/dSYMs/
IOS_DESTINATION = 'platform=iOS Simulator,name=iPhone 14'

E2E_PROJECT_PLIST_FILE = $(CURRENT_DIRECTORY)/AEPMessaging/Tests/E2EFunctionalTests/E2EFunctionalTestApp/Info.plist

setup:
	(pod install)
	(cd TestApps/$(APP_NAME) && pod install)

setup-tools: install-githook

pod-repo-update:
	(pod repo update)
	(cd TestApps/$(APP_NAME) && pod repo update)

# pod repo update may fail if there is no repo (issue fixed in v1.8.4). Use pod install --repo-update instead
pod-install:
	(pod install --repo-update)
	(cd TestApps/$(APP_NAME) && pod install --repo-update)

ci-pod-install:
	(bundle exec pod install --repo-update)
	(cd TestApps/$(APP_NAME) && bundle exec pod install --repo-update)

pod-update: pod-repo-update
	(pod update)
	(cd TestApps/$(APP_NAME) && pod update)

open:
	open $(PROJECT_NAME).xcworkspace

open-app:
	open ./TestApps/$(APP_NAME)/*.xcworkspace

clean:
	(rm -rf build)

archive: clean pod-install build
	xcodebuild -create-xcframework \
		-framework $(SIMULATOR_ARCHIVE_PATH)$(EXTENSION_NAME).framework -debug-symbols $(SIMULATOR_ARCHIVE_DSYM_PATH)$(EXTENSION_NAME).framework.dSYM \
		-framework $(IOS_ARCHIVE_PATH)$(EXTENSION_NAME).framework -debug-symbols $(IOS_ARCHIVE_DSYM_PATH)$(EXTENSION_NAME).framework.dSYM \
		-output ./build/$(TARGET_NAME_XCFRAMEWORK)

build:
	xcodebuild archive -workspace $(PROJECT_NAME).xcworkspace -scheme $(SCHEME_NAME_XCFRAMEWORK) -archivePath "./build/ios.xcarchive" -sdk iphoneos -destination="iOS" SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES
	xcodebuild archive -workspace $(PROJECT_NAME).xcworkspace -scheme $(SCHEME_NAME_XCFRAMEWORK) -archivePath "./build/ios_simulator.xcarchive" -sdk iphonesimulator -destination="iOS Simulator" SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES

zip:
	cd build && zip -r -X $(PROJECT_NAME).xcframework.zip $(PROJECT_NAME).xcframework/
	swift package compute-checksum build/$(PROJECT_NAME).xcframework.zip

test: clean
	@echo "######################################################################"
	@echo "### Testing iOS"
	@echo "######################################################################"
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme $(PROJECT_NAME) -destination $(IOS_DESTINATION) -derivedDataPath build/out -resultBundlePath build/$(PROJECT_NAME).xcresult -enableCodeCoverage YES

install-githook:
	./tools/git-hooks/setup.sh

format: lint-autocorrect swift-format

check-format:
	(swiftformat --lint $(PROJECT_NAME)/Sources --swiftversion 5.1)

install-swiftformat:
	(brew install swiftformat)

swift-format:
	(swiftformat $(PROJECT_NAME)/Sources --swiftversion 5.1)

lint-autocorrect:
	($(CURRENT_DIRECTORY)/Pods/SwiftLint/swiftlint --fix)

lint:
	(./Pods/SwiftLint/swiftlint lint $(PROJECT_NAME)/Sources)

check-version:
	(sh ./Script/version.sh $(VERSION))

test-SPM-integration:
	(sh ./Script/test-SPM.sh)

test-podspec:
	(sh ./Script/test-podspec.sh)

functional-test: pod-install
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme E2EFunctionalTests -destination 'platform=iOS Simulator,name=iPhone 12' -derivedDataPath build/out

# usage - 
# make set-environment ENV=[environment]
set-environment:
	@echo "Setting E2E functional testing to run in environment '$(ENV)'"
	plutil -replace ADOBE_ENVIRONMENT -string $(ENV) $(E2E_PROJECT_PLIST_FILE)

# used to test update-versions.sh script locally
test-versions:
	(sh ./Script/update-versions.sh -n Messaging -v 4.0.0 -d "AEPCore 4.0.0, AEPServices 4.0.0, AEPEdge 4.0.0, AEPEdgeIdentity 4.0.0")

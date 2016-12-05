# Set bash script to exit immediately if any commands fail.
set -e

# Setup some constants for use later on.
task="$1"
PATH="$2"
PROJECT_NAME="$3"
FRAMEWORK_NAME="$4"
SCHEME_NAME="$5"
WORKSPACE_NAME="${PROJECT_NAME}.xcworkspace"

cd ${PATH}

pod cache clean --all
pod install

if [ "$task" == "-b" ]; then
  #xcodebuild clean test -workspace "${WORKSPACE_NAME}" -scheme "${SCHEME_NAME}" -sdk "iphonesimulator10.0" -destination "OS=10.0,name=iPhone 6 Plus" -configuration Debug
  xcodebuild clean build -workspace "${WORKSPACE_NAME}" -scheme "${SCHEME_NAME}"
fi

if [ "$task" == "-d" ]; then
  # Build fat framework
  xcodebuild -workspace "${WORKSPACE_NAME}" -scheme "${SCHEME_NAME}" -configuration Release -arch arm64 -arch armv7 -arch armv7s only_active_arch=no defines_module=yes -sdk "iphoneos" -derivedDataPath "${SRCROOT}/build"
  xcodebuild -workspace "${WORKSPACE_NAME}" -scheme "${SCHEME_NAME}" -configuration Release -arch x86_64 -arch i386 only_active_arch=no defines_module=yes -sdk "iphonesimulator" -derivedDataPath "${SRCROOT}/build"
  cp -r "${SRCROOT}/build/Build/Products/Release-iphoneos/${FRAMEWORK_NAME}.framework" "./${FRAMEWORK_NAME}.framework"

  # Replace the framework executable within the framework with a new version created by merging the device and simulator frameworks' executables with lipo.
  lipo -create -output "./${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}" "${SRCROOT}/build/Build/Products/Release-iphoneos/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}" "${SRCROOT}/build/Build/Products/Release-iphonesimulator/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}"

  # Create binary
  zip -r ./${FRAMEWORK_NAME}.zip "${FRAMEWORK_NAME}.framework"

  # Delete the most recent build.
  if [ -d "${SRCROOT}/${FRAMEWORK_NAME}.framework" ]; then
    rm -rf "${SRCROOT}/${FRAMEWORK_NAME}.framework"
  fi

  if [ -d "${SRCROOT}/build" ]; then
    rm -rf "${SRCROOT}/build"
  fi
fi

pod spec lint ${PROJECT_NAME}.podspec --use-libraries --allow-warnings --verbose

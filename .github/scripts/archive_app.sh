#!/bin/bash

set -eo pipefail

cd MediaUploader
pod install
xcodebuild -workspace MediaUploader.xcworkspace \
            -scheme MediaUploader \
            -archivePath $PWD/build/MediaUploader.xcarchive \
            clean archive | xcpretty

#!/bin/bash
set -euo pipefail
mkdir -p build
result="build/Workflow-$(date +%s).xcresult"
xcodebuild -project 'Service Desk Assistant.xcodeproj' -scheme 'Service Desk Assistant' -destination "${DESK_DESTINATION:-platform=iOS Simulator,name=iPhone 18 Pro}" -derivedDataPath build/DerivedData test -collect-test-diagnostics never -resultBundlePath "$result"
xcrun xcresulttool export attachments --path "$result" --output-path build/Screenshots

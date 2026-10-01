#!/bin/bash
set -euo pipefail
mkdir -p build
architecture="$(uname -m)"
xcrun swiftc -swift-version 6 -target "$architecture-apple-macos27.0" Sources/Core/DeskStore.swift Sources/App/DeskAssistant.swift Scripts/ModelSmokeTest.swift -o build/ModelSmokeTest
build/ModelSmokeTest

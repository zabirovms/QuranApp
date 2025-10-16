#!/bin/bash

# Add Flutter to PATH
export PATH="/home/runner/flutter/bin:$PATH"
export PATH="/home/runner/flutter/bin/cache/dart-sdk/bin:$PATH"

# Run Flutter web server on port 5000 with all hosts allowed
flutter run -d web-server --web-port=5000 --web-hostname=0.0.0.0

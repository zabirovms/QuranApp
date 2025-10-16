#!/bin/bash

# Add Flutter to PATH
export PATH="/home/runner/flutter/bin:$PATH"
export PATH="/home/runner/flutter/bin/cache/dart-sdk/bin:$PATH"

# Enable Flutter web
flutter config --enable-web --no-analytics

# Create web directory if it doesn't exist
if [ ! -d "web" ]; then
  flutter create . --platforms=web
fi

# Get dependencies
flutter pub get

echo "Flutter setup complete!"

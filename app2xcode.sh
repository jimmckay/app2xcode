#!/bin/zsh

# Check if an argument was provided
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <path-to-app-bundle>"
    exit 1
fi

APP_PATH="$1"

# Check if the path exists
if [[ ! -e "$APP_PATH" ]]; then
    echo "Error: Path '$APP_PATH' does not exist"
    exit 1
fi

# Check if it's an app bundle (directory ending in .app)
if [[ ! -d "$APP_PATH" ]] || [[ ! "$APP_PATH" =~ \.app$ ]]; then
    echo "Error: '$APP_PATH' is not an app bundle"
    exit 1
fi

# Get the app name without .app extension
APP_NAME=$(basename "$APP_PATH" .app)

# Create timestamp in format YYYY-MM-DD_HHMMSS
TIMESTAMP=$(date '+%Y-%m-%d_%H%M%S')

# Create archive name
ARCHIVE_NAME="${APP_NAME}_${TIMESTAMP}.xcarchive"

# Create full path for archive in system temp directory
ARCHIVE_PATH="/tmp/$ARCHIVE_NAME"

# Create directory structure
mkdir -p "$ARCHIVE_PATH/Products/Applications"

# Copy the app bundle to the Applications directory
cp -R "$APP_PATH" "$ARCHIVE_PATH/Products/Applications/"

# Check if copy was successful
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to copy app bundle to archive"
    rm -rf "$ARCHIVE_PATH"
    exit 1
fi

# Get the main executable path within the app bundle
EXECUTABLE_NAME=$(defaults read "$APP_PATH/Contents/Info" CFBundleExecutable)
EXECUTABLE_PATH="$APP_PATH/Contents/MacOS/$EXECUTABLE_NAME"

# Get architectures using the arch command
ARCHS=($(lipo -archs "$EXECUTABLE_PATH"))

# Get bundle information
BUNDLE_ID=$(defaults read "$APP_PATH/Contents/Info" CFBundleIdentifier)
BUNDLE_VERSION=$(defaults read "$APP_PATH/Contents/Info" CFBundleVersion)
BUNDLE_SHORT_VERSION=$(defaults read "$APP_PATH/Contents/Info" CFBundleShortVersionString)

# Get signing information
SIGNING_INFO=$(codesign -dvv "$APP_PATH" 2>&1)
SIGNING_IDENTITY=$(echo "$SIGNING_INFO" | grep "Authority" | head -1 | sed 's/.*Authority=//g')
TEAM_ID=$(echo "$SIGNING_INFO" | grep "TeamIdentifier" | sed 's/.*TeamIdentifier=//g')

# Create Info.plist using plutil
APP_BUNDLE_NAME=$(basename "$APP_PATH")
plutil -create xml1 "$ARCHIVE_PATH/Info.plist"

plutil -insert ArchiveVersion -integer "2" "$ARCHIVE_PATH/Info.plist"
plutil -insert CreationDate -date $(date -u +"%Y-%m-%dT%H:%M:%SZ") "$ARCHIVE_PATH/Info.plist"
plutil -insert Name -string $(basename "$APP_PATH" .app) "$ARCHIVE_PATH/Info.plist"

# Create ApplicationProperties dictionary
plutil -insert ApplicationProperties -json "{}" "$ARCHIVE_PATH/Info.plist"

# Add all properties inside ApplicationProperties
plutil -insert ApplicationProperties.ApplicationPath -string "Applications/$APP_BUNDLE_NAME" "$ARCHIVE_PATH/Info.plist"
plutil -insert ApplicationProperties.CFBundleIdentifier -string "$BUNDLE_ID" "$ARCHIVE_PATH/Info.plist"
plutil -insert ApplicationProperties.CFBundleShortVersionString -string "$BUNDLE_SHORT_VERSION" "$ARCHIVE_PATH/Info.plist"
plutil -insert ApplicationProperties.CFBundleVersion -string "$BUNDLE_VERSION" "$ARCHIVE_PATH/Info.plist"

# Add signing information if available
if [[ -n "$SIGNING_IDENTITY" ]]; then
    plutil -insert ApplicationProperties.SigningIdentity -string "$SIGNING_IDENTITY" "$ARCHIVE_PATH/Info.plist"
fi

if [[ -n "$TEAM_ID" ]]; then
    plutil -insert ApplicationProperties.Team -string "$TEAM_ID" "$ARCHIVE_PATH/Info.plist"
fi

# Add architectures array inside ApplicationProperties
plutil -insert ApplicationProperties.Architectures -json "[]" "$ARCHIVE_PATH/Info.plist"
for arch in $ARCHS; do
    plutil -insert ApplicationProperties.Architectures.0 -string "$arch" "$ARCHIVE_PATH/Info.plist"
done

# Verify Info.plist was created successfully
if [[ $? -eq 0 ]]; then
    echo "Successfully created archive at: $ARCHIVE_PATH"
    echo "Archive structure:"
    find "$ARCHIVE_PATH" -type d ! -path '*.app/*' -exec ls -G -d {} \;
    echo "\nInfo.plist contents:"
    plutil -p "$ARCHIVE_PATH/Info.plist"
    open "$ARCHIVE_PATH"
else
    echo "Error: Failed to create Info.plist"
    rm -rf "$ARCHIVE_PATH"
    exit 1
fi

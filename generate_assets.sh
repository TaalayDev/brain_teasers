#!/bin/bash

# Constants
DEFAULT_ASSETS_DIR="assets"
DEFAULT_OUTPUT_FILE="lib/constants/app_assets.dart"
DEFAULT_CLASS_NAME="AppAssets"
PUBSPEC_FILE="pubspec.yaml"

# Helper functions
die() {
    echo "$1" >&2
    exit 1
}

to_camel_case() {
    echo "$1" | awk '
    BEGIN { FS = "_"; OFS = "" }
    { 
        for (i=1; i<=NF; i++) {
            if (i == 1) {
                $i = tolower($i)
            } else {
                $i = toupper(substr($i,1,1)) tolower(substr($i,2))
            }
        }
        print
    }' | sed 's/\*//g'
}

# Check if we're in a Flutter project
[ -f "$PUBSPEC_FILE" ] || die "Error: pubspec.yaml not found. Are you in a Flutter project root?"

# Read values from pubspec.yaml or use defaults
ASSETS_DIR=$(grep -m 1 "assets_dir:" "$PUBSPEC_FILE" | awk '{print $2}' | tr -d '"' || echo "$DEFAULT_ASSETS_DIR")
OUTPUT_FILE=$(grep -m 1 "assets_output_file:" "$PUBSPEC_FILE" | awk '{print $2}' | tr -d '"' || echo "$DEFAULT_OUTPUT_FILE")
CLASS_NAME=$(grep -m 1 "assets_class_name:" "$PUBSPEC_FILE" | awk '{print $2}' | tr -d '"' || echo "$DEFAULT_CLASS_NAME")

# Create the output directory if it doesn't exist
mkdir -p "$(dirname "$OUTPUT_FILE")"

# Start writing the Dart file
cat > "$OUTPUT_FILE" << EOL
/// This file is auto-generated. Do not edit manually.

class $CLASS_NAME {
  const ${CLASS_NAME}._();

EOL

# Function to process assets in a directory
process_directory() {
    local dir="$1"
    local record_name=$(to_camel_case "$(basename "$dir")")
    
    echo "  static const $record_name = (" >> "$OUTPUT_FILE"

    for asset in "$dir"/*; do
        if [ -f "$asset" ]; then
            local name=$(basename "$asset")
            local varname=$(to_camel_case "${name%.*}")
            varname=$(echo "$varname" | tr '-' '_')
            echo "    $varname: '$asset'," >> "$OUTPUT_FILE"
        fi
    done

    echo "  );" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
}

# Process all directories in assets
for dir in "$ASSETS_DIR"/*; do
    if [ -d "$dir" ]; then
        process_directory "$dir"
    fi
done

# Close the class
echo "}" >> "$OUTPUT_FILE"

echo "Asset records generated at $OUTPUT_FILE"

# Optionally format the Dart file if dart format is available
if command -v dart format >/dev/null 2>&1; then
    dart format "$OUTPUT_FILE"
    echo "Dart file formatted."
else
    echo "Note: 'dart format' not found. The generated file may need manual formatting."
fi
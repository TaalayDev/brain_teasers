#!/bin/bash

# Flutter Assets Generator
# Generates a Dart constants file from asset directories

# Constants
DEFAULT_ASSETS_DIR="assets"
DEFAULT_OUTPUT_FILE="lib/constants/app_assets.dart"
DEFAULT_CLASS_NAME="AppAssets"
PUBSPEC_FILE="pubspec.yaml"

# Command line argument parsing
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --assets-dir=*)
                ASSETS_DIR="${1#*=}"
                shift
                ;;
            --output=*)
                OUTPUT_FILE="${1#*=}"
                shift
                ;;
            --class-name=*)
                CLASS_NAME="${1#*=}"
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [options]"
                echo "Options:"
                echo "  --assets-dir=DIR    Directory containing assets (default: from pubspec.yaml or 'assets')"
                echo "  --output=FILE       Output Dart file path (default: from pubspec.yaml or 'lib/constants/app_assets.dart')"
                echo "  --class-name=NAME   Name of generated Dart class (default: from pubspec.yaml or 'AppAssets')"
                echo "  --help, -h          Show this help message"
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                exit 1
                ;;
        esac
    done
}

# Error handling
die() {
    echo "ERROR: $1" >&2
    exit 1
}

log_info() {
    echo "INFO: $1"
}

log_warning() {
    echo "WARNING: $1" >&2
}

# Improved camel case conversion
to_camel_case() {
    local input="$1"
    
    # Replace non-alphanumeric characters with underscores
    input=$(echo "$input" | sed 's/[^a-zA-Z0-9]/_/g')
    
    # Handle digits at the beginning
    if [[ $input =~ ^[0-9] ]]; then
        input="n$input"
    fi
    
    # Convert to camelCase
    echo "$input" | awk '
    BEGIN { FS = "_"; OFS = "" }
    { 
        result = ""
        for (i=1; i<=NF; i++) {
            if (length($i) == 0) continue
            if (i == 1) {
                result = result tolower(substr($i,1,1)) substr($i,2)
            } else {
                result = result toupper(substr($i,1,1)) substr($i,2)
            }
        }
        print result
    }'
}

# Generate valid Dart identifier
to_dart_identifier() {
    local input="$1"
    local camel_case=$(to_camel_case "$input")
    
    # Reserved keywords in Dart
    local keywords=("abstract" "dynamic" "implements" "show" "as" "else" "import" "static" "assert" "enum" 
                   "in" "super" "async" "export" "interface" "switch" "await" "extends" "is" "sync" "break" 
                   "external" "library" "this" "case" "factory" "mixin" "throw" "catch" "false" "new" "true" 
                   "class" "final" "null" "try" "const" "finally" "on" "typedef" "continue" "for" "operator" 
                   "var" "covariant" "Function" "part" "void" "default" "get" "rethrow" "while" "deferred" 
                   "hide" "return" "with" "do" "if" "set" "yield")
    
    # Check if the identifier is a reserved keyword
    for keyword in "${keywords[@]}"; do
        if [[ "$camel_case" == "$keyword" ]]; then
            camel_case="${camel_case}Value"
            break
        fi
    done
    
    echo "$camel_case"
}

# Create path for Dart string
create_dart_path() {
    echo "${1#./}" | sed 's/\\/\\\\/g'
}

# Generate file list for a directory
get_file_list() {
    local dir="$1"
    local values=""
    local first=true
    
    for asset in "$dir"/*; do
        if [ -f "$asset" ] && [[ "$(basename "$asset")" != .* ]]; then
            local path=$(create_dart_path "$asset")
            if $first; then
                values="'$path'"
                first=false
            else
                values="$values, '$path'"
            fi
        fi
    done
    
    echo "$values"
}

# Generate Dart record entries recursively
process_directory_recursive() {
    local dir="$1"
    local indent="$2"
    local files=()
    local subdirs=()
    local has_entries=false
    
    # First pass: collect files and subdirectories
    for asset in "$dir"/*; do
        if [ -f "$asset" ]; then
            # Skip .DS_Store and other hidden files
            if [[ "$(basename "$asset")" == .* ]]; then
                continue
            fi
            files+=("$asset")
            has_entries=true
        elif [ -d "$asset" ]; then
            subdirs+=("$asset")
            has_entries=true
        fi
    done
    
    # If directory is empty, return early
    if ! $has_entries; then
        return
    fi
    
    # Add values list for all files in this directory
    if [ ${#files[@]} -gt 0 ]; then
        local file_list=$(get_file_list "$dir")
        echo "${indent}\$values: [$file_list]," >> "$OUTPUT_FILE"
    fi
    
    # Print all files in this directory
    for asset in "${files[@]}"; do
        local name=$(basename "$asset")
        local varname=$(to_dart_identifier "${name%.*}")
        local path=$(create_dart_path "$asset")
        echo "${indent}${varname}: '$path'," >> "$OUTPUT_FILE"
    done
    
    # Handle subdirectories
    for subdir in "${subdirs[@]}"; do
        local dir_name=$(basename "$subdir")
        local record_name=$(to_dart_identifier "$dir_name")
        
        echo "${indent}${record_name}: (" >> "$OUTPUT_FILE"
        process_directory_recursive "$subdir" "${indent}  "
        echo "${indent})," >> "$OUTPUT_FILE"
    done
}

# Main function to write the asset constants
write_asset_constants() {
    # Create the output directory if it doesn't exist
    mkdir -p "$(dirname "$OUTPUT_FILE")" || die "Failed to create output directory"
    
    # Start writing the Dart file
    cat > "$OUTPUT_FILE" << EOL
// This file is auto-generated. Do not edit manually.
// Generated on $(date)

/// Assets constants for the application
class $CLASS_NAME {
  const ${CLASS_NAME}._();

EOL
    
    # Process all assets in the assets directory
    
    # First collect top-level files
    local top_files=()
    for asset in "$ASSETS_DIR"/*; do
        if [ -f "$asset" ] && [[ "$(basename "$asset")" != .* ]]; then
            top_files+=("$asset")
        fi
    done
    
    # Add top-level files record if there are any
    if [ ${#top_files[@]} -gt 0 ]; then
        echo "  /// Top-level assets" >> "$OUTPUT_FILE"
        echo "  static const root = (" >> "$OUTPUT_FILE"
        
        # Add values list with all files in top directory
        local file_list=$(get_file_list "$ASSETS_DIR")
        echo "    \$values: [$file_list]," >> "$OUTPUT_FILE"
        
        # Add individual file entries
        for asset in "${top_files[@]}"; do
            local name=$(basename "$asset")
            local varname=$(to_dart_identifier "${name%.*}")
            local path=$(create_dart_path "$asset")
            echo "    ${varname}: '$path'," >> "$OUTPUT_FILE"
        done
        
        echo "  );" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    fi
    
    # Process all top-level directories in assets
    for dir in "$ASSETS_DIR"/*; do
        if [ -d "$dir" ]; then
            local dir_name=$(basename "$dir")
            local record_name=$(to_dart_identifier "$dir_name")
            
            echo "  /// Assets from '$dir_name' directory" >> "$OUTPUT_FILE"
            echo "  static const $record_name = (" >> "$OUTPUT_FILE"
            
            process_directory_recursive "$dir" "    "
            
            echo "  );" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
        fi
    done
    
    # End of class
    echo "}" >> "$OUTPUT_FILE"

    # Add comment explaining the values field
    cat >> "$OUTPUT_FILE" << EOL

/*
 * Example usage:
 *
 * // Access specific asset
 * Image.asset(AppAssets.images.logo);
 * 
 * // Access all assets in a directory
 * for (final path in AppAssets.images.\$values) {
 *   Image.asset(path);
 * }
 */
EOL
}

# Entry point
main() {
    # Parse command line arguments
    parse_args "$@"
    
    # Check if we're in a Flutter project
    [ -f "$PUBSPEC_FILE" ] || die "pubspec.yaml not found. Are you in a Flutter project root?"
    
    # Read values from pubspec.yaml or use defaults if not specified on command line
    if [ -z "${ASSETS_DIR+x}" ]; then
        ASSETS_DIR=$(grep -m 1 "assets_dir:" "$PUBSPEC_FILE" | awk '{print $2}' | tr -d '"' || echo "$DEFAULT_ASSETS_DIR")
    fi
    
    if [ -z "${OUTPUT_FILE+x}" ]; then
        OUTPUT_FILE=$(grep -m 1 "assets_output_file:" "$PUBSPEC_FILE" | awk '{print $2}' | tr -d '"' || echo "$DEFAULT_OUTPUT_FILE")
    fi
    
    if [ -z "${CLASS_NAME+x}" ]; then
        CLASS_NAME=$(grep -m 1 "assets_class_name:" "$PUBSPEC_FILE" | awk '{print $2}' | tr -d '"' || echo "$DEFAULT_CLASS_NAME")
    fi
    
    # Check if assets directory exists
    [ -d "$ASSETS_DIR" ] || die "Assets directory '$ASSETS_DIR' not found"
    
    # Generate the constants file
    write_asset_constants
    
    log_info "Asset records generated at $OUTPUT_FILE"
    
    # Format the Dart file if dart format is available
    if command -v dart format >/dev/null 2>&1; then
        dart format "$OUTPUT_FILE" > /dev/null || log_warning "Failed to format Dart file"
        log_info "Dart file formatted."
    else
        log_warning "'dart format' not found. The generated file may need manual formatting."
    fi
}

# Execute the script
main "$@"
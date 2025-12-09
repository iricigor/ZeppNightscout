#!/bin/bash
# Generate Zeus Preview QR Code
# This script automates the zeus preview command to generate a QR code for app installation

set -e

echo "Installing required tools (qrencode, imagemagick, expect, python3-pip, libzbar0 for QR decoding)..."
if ! sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq > /dev/null 2>&1; then
  echo "::error::Failed to update package lists"
  exit 1
fi
if ! sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq qrencode imagemagick expect python3-pip python3-pil libzbar0 > /dev/null 2>&1; then
  echo "::error::Failed to install required tools"
  exit 1
fi
echo "Installing Python QR code libraries..."
if ! pip3 install -q qrcode pyzbar pillow > /dev/null 2>&1; then
  echo "::warning::Failed to install Python QR libraries, will try alternative methods"
fi
echo "✅ Tools installed successfully"

# Note: expect automates the interactive device selection in 'zeus preview'
# (Zeus CLI doesn't provide a command-line option for this)

# Run zeus preview and capture output
echo "Running zeus preview to generate QR code..."

# Use timeout wrapper to prevent indefinite hanging (45 seconds max)
# This provides a hard limit even if expect script itself hangs
# Use expect to automate the device selection and capture all output
set +e  # Temporarily disable exit-on-error to capture exit code

# Write expect script to temp file to avoid bash interpretation issues
EXPECT_SCRIPT=$(mktemp)
cat > "$EXPECT_SCRIPT" <<'EOF'
# Set timeout to 30 seconds - sufficient for device selection and QR code generation
set timeout 30
log_user 1
log_file -noappend /tmp/zeus_preview.log

spawn zeus preview

# Wait for device selection prompt and select Amazfit Balance (second option)
expect {
  -re {Which device would you like to preview\?} {
    # Wait a moment for the list to fully render
    sleep 0.5
    # Send down arrow to move from "Amazfit GTR 3" (default/first) to "Amazfit Balance" (second)
    # This selects the primary target device for the app
    send "\033\[B"
    sleep 0.5
    # Send enter to confirm selection
    send "\r"
    # Wait for the build and QR code generation to complete
    # The QR code is displayed as ASCII art, so we just wait for completion
    expect {
      timeout {
        puts "\nWaiting for QR code generation to complete..."
      }
      eof {
        puts "\nCommand completed (EOF)"
      }
    }
  }
  timeout {
    puts "\nTimeout waiting for device selection prompt"
  }
  eof {
    puts "\nCommand completed (no device selection needed)"
  }
}

# Give the command a moment to finish outputting everything
sleep 1

# Force exit to prevent hanging
catch {
  # Try to close the spawned process gracefully
  close
}
catch {
  wait
}
exit 0
EOF

PREVIEW_OUTPUT=$(timeout 45 expect "$EXPECT_SCRIPT" 2>&1)
EXPECT_EXIT_CODE=$?
rm -f "$EXPECT_SCRIPT"  # Clean up temp file
set -e  # Re-enable exit-on-error

# Check if the command timed out (timeout command returns exit code 124)
if [ $EXPECT_EXIT_CODE -eq 124 ]; then
  echo "::warning::Zeus preview command timed out after 45 seconds"
fi

echo "Preview output:"
echo "$PREVIEW_OUTPUT"

# Also show the log file if it exists
if [ -f /tmp/zeus_preview.log ]; then
  echo "Full log file contents:"
  cat /tmp/zeus_preview.log
fi

# Helper function to extract URL from text
extract_url() {
  local text="$1"
  # First try zepp:// deep link format (preferred)
  local url=$(echo "$text" | grep -oP 'zepp://[^\s\r\n"]+' | head -1 || echo "")
  # If no zepp:// URL found, try https:// format
  if [ -z "$url" ]; then
    url=$(echo "$text" | grep -oP 'https://[a-zA-Z0-9./?&=_:#-]+' | head -1 || echo "")
  fi
  echo "$url"
}

# Helper function to extract and decode ASCII QR code
extract_qr_from_ascii() {
  local text="$1"
  
  # Check if QR code exists in output
  if ! echo "$text" | grep -q "^▄▄▄▄▄"; then
    echo "::debug::No ASCII QR code block found in output"
    return 1
  fi
  
  echo "::debug::Found ASCII QR code block, attempting to decode..."
  
  # Save output to temp file for Python script
  local temp_file=$(mktemp)
  echo "$text" > "$temp_file"
  
  # Try to decode using Python script
  local decoded_url=$(python3 scripts/decode-ascii-qr.py "$temp_file" 2>/dev/null || echo "")
  
  # Clean up
  rm -f "$temp_file"
  
  if [ -n "$decoded_url" ]; then
    echo "::debug::Successfully decoded QR code: $decoded_url"
    echo "$decoded_url"
    return 0
  else
    echo "::debug::Failed to decode QR code using Python script"
    return 1
  fi
}

# Try to extract the preview URL from output
PREVIEW_URL=$(extract_url "$PREVIEW_OUTPUT")

# Also check the log file if URL not found in stdout
if [ -z "$PREVIEW_URL" ] && [ -f /tmp/zeus_preview.log ]; then
  PREVIEW_URL=$(extract_url "$(cat /tmp/zeus_preview.log)")
fi

# If still no URL found, try to decode ASCII QR code
if [ -z "$PREVIEW_URL" ]; then
  echo "No URL text found in output, attempting to decode ASCII QR code..."
  echo "::debug::ASCII QR decoding is experimental and may not work reliably"
  
  # Try from stdout first - disable exit on error temporarily
  set +e
  PREVIEW_URL=$(extract_qr_from_ascii "$PREVIEW_OUTPUT")
  set -e
  
  # If not found, try from log file
  if [ -z "$PREVIEW_URL" ] && [ -f /tmp/zeus_preview.log ]; then
    echo "Trying to decode QR from log file..."
    set +e
    PREVIEW_URL=$(extract_qr_from_ascii "$(cat /tmp/zeus_preview.log)")
    set -e
  fi
  
  # If still no URL, provide helpful information
  if [ -z "$PREVIEW_URL" ]; then
    echo "::notice::ASCII QR code decoding is experimental and currently unable to extract the URL"
    echo "::notice::The QR code is displayed above for manual scanning with the Zepp app"
    echo "::notice::To scan: Open Zepp App → Profile → Your Device → Developer Mode → Scan"
  fi
fi

if [ -n "$PREVIEW_URL" ]; then
  if [ -n "$GITHUB_OUTPUT" ]; then
    echo "PREVIEW_URL=$PREVIEW_URL" >> "$GITHUB_OUTPUT"
  fi
  echo "✅ Zeus preview URL generated: $PREVIEW_URL"
  
  # Generate QR code image from the preview URL
  qrencode -s 10 -o zeus_preview_qr.png "$PREVIEW_URL"
  if [ -n "$GITHUB_OUTPUT" ]; then
    echo "ZEUS_QR_GENERATED=true" >> "$GITHUB_OUTPUT"
  fi
  echo "✅ QR code image saved to zeus_preview_qr.png"
else
  echo "::warning::Could not extract preview URL from zeus preview output"
  if [ -n "$GITHUB_OUTPUT" ]; then
    echo "ZEUS_QR_GENERATED=false" >> "$GITHUB_OUTPUT"
  fi
fi

# Always exit successfully - QR code decoding is optional
exit 0

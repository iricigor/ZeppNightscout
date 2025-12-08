#!/bin/bash
# Generate Zeus Preview QR Code
# This script automates the zeus preview command to generate a QR code for app installation

set -e

echo "Installing required tools (qrencode, imagemagick, expect)..."
if ! sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq > /dev/null 2>&1; then
  echo "::error::Failed to update package lists"
  exit 1
fi
if ! sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq qrencode imagemagick expect > /dev/null 2>&1; then
  echo "::error::Failed to install required tools"
  exit 1
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
# Set timeout to 30 seconds - sufficient for device selection and URL generation
set timeout 30
log_user 1
log_file -noappend /tmp/zeus_preview.log

spawn zeus preview

# Handle device selection and URL generation
# Two scenarios: 1) Device selection prompt appears, 2) Direct URL output
expect {
  "Select a target device" {
    send "1\r"
    # After selecting device, wait for the URL or completion
    expect {
      -re {(zepp://[^ \t\r\n"]+|https://[a-zA-Z0-9./?&=_:#-]+)} {
        # Give it a moment to output the full URL
        sleep 1
        puts "\nURL detected, exiting..."
      }
      timeout {
        puts "\nTimeout after device selection"
      }
      eof {
        puts "\nCommand completed (EOF)"
      }
    }
  }
  -re {(zepp://[^ \t\r\n"]+|https://[a-zA-Z0-9./?&=_:#-]+)} {
    # URL appeared without device selection prompt
    sleep 1
    puts "\nURL detected without device selection, exiting..."
  }
  timeout {
    puts "\nTimeout waiting for device selection prompt"
  }
  eof {
    puts "\nCommand completed (no device selection needed)"
  }
}

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
    url=$(echo "$text" | grep -oP 'https://[a-zA-Z0-9./?&=_-]+' | head -1 || echo "")
  fi
  echo "$url"
}

# Try to extract the preview URL from output
PREVIEW_URL=$(extract_url "$PREVIEW_OUTPUT")

# Also check the log file if URL not found in stdout
if [ -z "$PREVIEW_URL" ] && [ -f /tmp/zeus_preview.log ]; then
  PREVIEW_URL=$(extract_url "$(cat /tmp/zeus_preview.log)")
fi

if [ -n "$PREVIEW_URL" ]; then
  echo "PREVIEW_URL=$PREVIEW_URL" >> "$GITHUB_OUTPUT"
  echo "✅ Zeus preview URL generated: $PREVIEW_URL"
  
  # Generate QR code image from the preview URL
  qrencode -s 10 -o zeus_preview_qr.png "$PREVIEW_URL"
  echo "ZEUS_QR_GENERATED=true" >> "$GITHUB_OUTPUT"
  echo "✅ QR code image saved to zeus_preview_qr.png"
else
  echo "::warning::Could not extract preview URL from zeus preview output"
  echo "ZEUS_QR_GENERATED=false" >> "$GITHUB_OUTPUT"
fi

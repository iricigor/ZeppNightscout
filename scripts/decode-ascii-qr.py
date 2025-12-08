#!/usr/bin/env python3
"""
Decode QR code from ASCII art output by zeus preview command.
"""
import sys
import re
from PIL import Image

def extract_qr_ascii(text):
    """Extract the ASCII QR code block from text."""
    lines = text.split('\n')
    qr_lines = []
    in_qr = False
    start_pattern_found = False
    
    for line in lines:
        # QR codes start with a line that's mostly ▄ characters
        if not start_pattern_found and line.startswith('▄' * 10):
            in_qr = True
            start_pattern_found = True
            qr_lines.append(line)
        elif in_qr:
            # Continue collecting lines until we hit another border line or empty line
            if line.startswith('▄' * 10):
                qr_lines.append(line)
                break  # End of QR code (bottom border)
            elif line.strip() and any(c in line for c in ['█', '▀', '▄', ' ']):
                qr_lines.append(line)
            elif not line.strip():
                # Empty line might indicate end of QR
                break
    
    return qr_lines

def ascii_qr_to_image(qr_lines, output_path='qr_temp.png'):
    """Convert ASCII QR code to an image.
    
    The QR code uses Unicode block characters where each character represents
    TWO vertical pixels (rows) using half-blocks:
    - █ (U+2588) = both pixels black
    - ▀ (U+2580) = top pixel black, bottom pixel white
    - ▄ (U+2584) = top pixel white, bottom pixel black
    - (space) = both pixels white
    """
    if not qr_lines:
        return None
    
    # Module size (each QR code module will be this many pixels)
    module_size = 4
    
    # Find the maximum line length
    max_width = max(len(line) for line in qr_lines)
    
    # Each line represents 2 rows of QR modules (due to half-block characters)
    qr_width = max_width * module_size
    qr_height = len(qr_lines) * 2 * module_size  # *2 because each char = 2 vertical modules
    
    # Add quiet zone (white border) - QR codes need this
    quiet_zone = 4 * module_size
    img_width = qr_width + 2 * quiet_zone
    img_height = qr_height + 2 * quiet_zone
    
    img = Image.new('1', (img_width, img_height), 1)  # Binary image: 1=white, 0=black
    
    for y, line in enumerate(qr_lines):
        for x, char in enumerate(line):
            # Determine which pixels are black based on the character
            # Each character represents 2 vertical pixels
            top_black = False
            bottom_black = False
            
            if char == '█':  # U+2588 - Full block
                top_black = True
                bottom_black = True
            elif char == '▀':  # U+2580 - Upper half block
                top_black = True
                bottom_black = False
            elif char == '▄':  # U+2584 - Lower half block
                top_black = False
                bottom_black = True
            # else: space or other = both white
            
            # Draw the modules (with quiet zone offset)
            x_start = quiet_zone + x * module_size
            y_top_start = quiet_zone + y * 2 * module_size
            y_bottom_start = quiet_zone + (y * 2 + 1) * module_size
            
            # Draw top module
            if top_black:
                for dx in range(module_size):
                    for dy in range(module_size):
                        img.putpixel((x_start + dx, y_top_start + dy), 0)
            
            # Draw bottom module
            if bottom_black:
                for dx in range(module_size):
                    for dy in range(module_size):
                        img.putpixel((x_start + dx, y_bottom_start + dy), 0)
    
    # Scale up the image for better recognition
    img = img.resize((img_width * 2, img_height * 2), Image.Resampling.NEAREST)
    img.save(output_path)
    return output_path

def decode_qr_image(image_path):
    """Decode QR code from image using pyzbar."""
    try:
        from pyzbar.pyzbar import decode
        img = Image.open(image_path)
        decoded_objects = decode(img)
        if decoded_objects:
            return decoded_objects[0].data.decode('utf-8')
    except ImportError:
        print("pyzbar not available, trying alternative method...", file=sys.stderr)
    except Exception as e:
        print(f"Error decoding QR: {e}", file=sys.stderr)
    
    return None

def main():
    if len(sys.argv) > 1:
        # Read from file
        with open(sys.argv[1], 'r', encoding='utf-8') as f:
            text = f.read()
    else:
        # Read from stdin
        text = sys.stdin.read()
    
    # Extract ASCII QR code
    qr_lines = extract_qr_ascii(text)
    
    if not qr_lines:
        print("No QR code found in input", file=sys.stderr)
        sys.exit(1)
    
    print(f"Found QR code with {len(qr_lines)} lines", file=sys.stderr)
    
    # Convert to image
    img_path = ascii_qr_to_image(qr_lines)
    if not img_path:
        print("Failed to convert QR to image", file=sys.stderr)
        sys.exit(1)
    
    print(f"Converted to image: {img_path}", file=sys.stderr)
    
    # Try to decode
    url = decode_qr_image(img_path)
    if url:
        print(url)  # Output the URL to stdout
        sys.exit(0)
    else:
        print("Failed to decode QR code", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""
Decode QR code from ASCII art output by zeus preview command.
"""
import sys
import re
from PIL import Image, ImageDraw, ImageFont

def extract_qr_ascii(text):
    """Extract the ASCII QR code block from text."""
    lines = text.split('\n')
    qr_lines = []
    in_qr = False
    
    for line in lines:
        # QR codes start and end with a line of ▄ characters
        if line.startswith('▄' * 10):  # At least 10 ▄ characters
            if not in_qr:
                in_qr = True
                qr_lines.append(line)
            else:
                qr_lines.append(line)
                break  # End of QR code
        elif in_qr:
            qr_lines.append(line)
    
    return qr_lines

def ascii_qr_to_image(qr_lines, output_path='qr_temp.png'):
    """Convert ASCII QR code to an image."""
    if not qr_lines:
        return None
    
    # Calculate cell size - each character represents a cell
    cell_size = 10
    
    # Find the maximum line length
    max_width = max(len(line) for line in qr_lines)
    
    # Create image
    img_width = max_width * cell_size
    img_height = len(qr_lines) * cell_size
    img = Image.new('RGB', (img_width, img_height), 'white')
    draw = ImageDraw.Draw(img)
    
    # Map Unicode QR characters to black/white
    # Full block █ = black, spaces and certain characters = white
    # QR codes use: █ ▀ ▄ and space
    black_chars = {'█', '▀', '▄', '▌', '▐', '▆', '▇', '▉', '▊', '▋'}
    
    for y, line in enumerate(qr_lines):
        for x, char in enumerate(line):
            if char in black_chars or ord(char) > 0x2580:  # Unicode box drawing
                # Draw a black cell
                x1 = x * cell_size
                y1 = y * cell_size
                x2 = x1 + cell_size
                y2 = y1 + cell_size
                draw.rectangle([x1, y1, x2, y2], fill='black')
    
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

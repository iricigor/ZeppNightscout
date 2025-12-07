/**
 * Simple HTTP server for the simulator
 * Starts a local server and opens the browser automatically
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

const PORT = process.env.PORT || 8080;
const HOST = process.env.CODESPACE_NAME ? '0.0.0.0' : 'localhost';

// MIME types
const mimeTypes = {
    '.html': 'text/html',
    '.js': 'text/javascript',
    '.css': 'text/css',
    '.json': 'application/json',
    '.png': 'image/png',
    '.jpg': 'image/jpg',
    '.gif': 'image/gif',
    '.svg': 'image/svg+xml',
    '.ico': 'image/x-icon'
};

const server = http.createServer((req, res) => {
    console.log(`${req.method} ${req.url}`);
    
    // Default to index.html
    let filePath = req.url === '/' ? '/simulator/index.html' : req.url;
    
    // Remove query string
    filePath = filePath.split('?')[0];
    
    // Security: prevent directory traversal
    filePath = path.normalize(filePath);
    if (filePath.includes('..')) {
        res.writeHead(403);
        res.end('Forbidden');
        return;
    }
    
    // Construct full path
    const fullPath = path.join(__dirname, '..', filePath);
    
    // Get file extension
    const extname = String(path.extname(fullPath)).toLowerCase();
    const contentType = mimeTypes[extname] || 'application/octet-stream';
    
    // Read and serve file
    fs.readFile(fullPath, (error, content) => {
        if (error) {
            if (error.code === 'ENOENT') {
                res.writeHead(404);
                res.end(`File not found: ${req.url}`);
            } else {
                res.writeHead(500);
                res.end(`Server error: ${error.code}`);
            }
        } else {
            res.writeHead(200, { 'Content-Type': contentType });
            res.end(content, 'utf-8');
        }
    });
});

server.listen(PORT, HOST, () => {
    const isCodespaces = !!process.env.CODESPACE_NAME;
    const url = isCodespaces 
        ? `https://${process.env.CODESPACE_NAME}-${PORT}.${process.env.GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}/`
        : `http://localhost:${PORT}/`;
    
    console.log('\n========================================');
    console.log('Zepp Nightscout Simulator');
    console.log('========================================');
    console.log(`Server running at: ${url}`);
    
    if (isCodespaces) {
        console.log('\n✓ Detected GitHub Codespaces environment');
        console.log('✓ Port forwarding configured');
        console.log(`\nOpen in browser: ${url}`);
    } else {
        console.log('\nOpening browser...');
        openBrowser(url);
    }
    
    console.log('\nPress Ctrl+C to stop the server');
    console.log('========================================\n');
});

function openBrowser(url) {
    const platform = process.platform;
    let command;
    
    switch (platform) {
        case 'darwin':
            command = `open "${url}"`;
            break;
        case 'win32':
            command = `start "" "${url}"`;
            break;
        default:
            command = `xdg-open "${url}"`;
            break;
    }
    
    exec(command, (error) => {
        if (error) {
            console.error('Could not open browser automatically.');
            console.log(`Please open: ${url}`);
        }
    });
}

// Handle graceful shutdown
process.on('SIGTERM', () => {
    console.log('\nReceived SIGTERM, shutting down gracefully...');
    server.close(() => {
        console.log('Server closed');
        process.exit(0);
    });
});

process.on('SIGINT', () => {
    console.log('\n\nReceived SIGINT, shutting down gracefully...');
    server.close(() => {
        console.log('Server closed');
        process.exit(0);
    });
});

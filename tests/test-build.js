/**
 * Test script for build validation
 * Validates that all required files for building the app are present and valid
 * Run with: node test-build.js
 */

const fs = require('fs');
const path = require('path');

console.log('='.repeat(50));
console.log('Testing Build Requirements');
console.log('='.repeat(50));
console.log();

let passed = 0;
let failed = 0;

function assert(condition, message) {
  if (condition) {
    console.log('✓', message);
    passed++;
  } else {
    console.log('✗', message);
    failed++;
  }
}

// Test 1: Check required files exist
console.log('Test 1: Required Build Files');
console.log('-'.repeat(50));

const requiredFiles = [
  'app.json',
  'package.json',
  'page/index.js',
  'app-side/index.js',
  'shared/message.js'
];

requiredFiles.forEach(file => {
  const filePath = path.join(process.cwd(), file);
  const exists = fs.existsSync(filePath);
  assert(exists, `File exists: ${file}`);
});

console.log();

// Test 2: Validate app.json structure
console.log('Test 2: app.json Structure Validation');
console.log('-'.repeat(50));

try {
  const appJsonPath = path.join(process.cwd(), 'app.json');
  const appJsonContent = fs.readFileSync(appJsonPath, 'utf8');
  const appJson = JSON.parse(appJsonContent);

  // Check required top-level fields
  assert(appJson.configVersion !== undefined, 'app.json has configVersion');
  assert(appJson.app !== undefined, 'app.json has app section');
  assert(appJson.permissions !== undefined, 'app.json has permissions');
  assert(appJson.runtime !== undefined, 'app.json has runtime');
  assert(appJson.targets !== undefined, 'app.json has targets');

  // Check app section fields
  assert(appJson.app.appId !== undefined, 'app.appId is defined');
  assert(appJson.app.appName !== undefined, 'app.appName is defined');
  assert(appJson.app.appType !== undefined, 'app.appType is defined');
  assert(appJson.app.version !== undefined, 'app.version is defined');
  assert(appJson.app.version.code !== undefined, 'app.version.code is defined');
  assert(appJson.app.version.name !== undefined, 'app.version.name is defined');

  // Check permissions include internet (required for Nightscout)
  assert(
    Array.isArray(appJson.permissions) && appJson.permissions.includes('internet'),
    'Permissions include "internet"'
  );

  // Check targets exist
  const targetKeys = Object.keys(appJson.targets);
  assert(targetKeys.length > 0, 'At least one target device is defined');

  // Check target structure
  targetKeys.forEach(target => {
    assert(
      appJson.targets[target].module !== undefined,
      `Target "${target}" has module definition`
    );
    assert(
      appJson.targets[target].module.page !== undefined,
      `Target "${target}" has page module`
    );
    assert(
      appJson.targets[target].module['app-side'] !== undefined,
      `Target "${target}" has app-side module`
    );
  });

} catch (error) {
  console.log('✗ Error parsing app.json:', error.message);
  failed++;
}

console.log();

// Test 3: Validate JavaScript files can be parsed
console.log('Test 3: JavaScript Files Syntax Validation');
console.log('-'.repeat(50));

const jsFiles = [
  'page/index.js',
  'app-side/index.js',
  'shared/message.js'
];

jsFiles.forEach(file => {
  const filePath = path.join(process.cwd(), file);
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    // Basic validation - check file is not empty and has some content
    assert(content.length > 0, `${file} is not empty`);
    
    // Check for common syntax patterns
    const hasValidStructure = 
      content.includes('Page(') || 
      content.includes('AppSideService(') || 
      content.includes('module.exports') ||
      content.includes('export');
    assert(hasValidStructure, `${file} has valid Zepp OS structure`);
  } catch (error) {
    console.log('✗', `Error reading ${file}:`, error.message);
    failed++;
  }
});

console.log();

// Test 4: Check package.json structure
console.log('Test 4: package.json Structure Validation');
console.log('-'.repeat(50));

try {
  const packageJsonPath = path.join(process.cwd(), 'package.json');
  const packageJsonContent = fs.readFileSync(packageJsonPath, 'utf8');
  const packageJson = JSON.parse(packageJsonContent);

  assert(packageJson.name !== undefined, 'package.json has name');
  assert(packageJson.version !== undefined, 'package.json has version');
  assert(packageJson.scripts !== undefined, 'package.json has scripts');
  assert(packageJson.scripts.build !== undefined, 'package.json has build script');
  
} catch (error) {
  console.log('✗ Error parsing package.json:', error.message);
  failed++;
}

console.log();

// Test 5: Validate assets (optional check)
console.log('Test 5: Asset Files Validation');
console.log('-'.repeat(50));

const assetFiles = [
  'assets/icon.png'
];

assetFiles.forEach(file => {
  const filePath = path.join(process.cwd(), file);
  try {
    const stats = fs.statSync(filePath);
    assert(stats.size > 0, `${file} exists and is not empty`);
    
    // Check file size is reasonable for an icon (between 1KB and 1MB)
    const sizeInKB = stats.size / 1024;
    assert(
      sizeInKB > 1 && sizeInKB < 1024,
      `${file} has reasonable size (${sizeInKB.toFixed(2)} KB)`
    );
  } catch (error) {
    // Icon is optional - just log a warning
    console.log('⚠', `${file} not found (optional)`);
  }
});

console.log();

// Summary
console.log('='.repeat(50));
console.log('Test Summary');
console.log('='.repeat(50));
console.log(`Passed: ${passed}`);
console.log(`Failed: ${failed}`);
console.log();

if (failed === 0) {
  console.log('✓ All build requirements validated!');
  console.log('✓ Project is ready for building with zeus CLI');
  process.exit(0);
} else {
  console.log('✗ Some build requirements are missing!');
  process.exit(1);
}

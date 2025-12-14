/**
 * Test for PAGE_NAVIGATION message type and functionality
 */

const path = require('path');
const fs = require('fs');

// Read and parse MESSAGE_TYPES from shared/message.js
const messagePath = path.join(__dirname, '../shared/message.js');
const messageContent = fs.readFileSync(messagePath, 'utf8');

const messageTypesMatch = messageContent.match(/export const MESSAGE_TYPES = \{([^}]+)\}/s);
let MESSAGE_TYPES = {};
if (messageTypesMatch) {
  const typesContent = messageTypesMatch[1];
  const typeMatches = typesContent.matchAll(/(\w+):\s*['"](\w+)['"]/g);
  for (const match of typeMatches) {
    MESSAGE_TYPES[match[1]] = match[2];
  }
}

console.log('==================================================');
console.log('Testing PAGE_NAVIGATION Message Type');
console.log('==================================================\n');

let passed = 0;
let failed = 0;

function test(description, condition) {
  if (condition) {
    console.log(`✓ ${description}`);
    passed++;
  } else {
    console.error(`✗ ${description}`);
    failed++;
  }
}

// Test 1: PAGE_NAVIGATION message type exists
console.log('Test 1: Message Type Validation');
console.log('--------------------------------------------------');
test('PAGE_NAVIGATION message type should exist', MESSAGE_TYPES.PAGE_NAVIGATION !== undefined);
test('PAGE_NAVIGATION should equal "PAGE_NAVIGATION"', MESSAGE_TYPES.PAGE_NAVIGATION === 'PAGE_NAVIGATION');

// Test 2: All expected message types exist
console.log('\nTest 2: All Message Types Present');
console.log('--------------------------------------------------');
test('FETCH_DATA should exist', MESSAGE_TYPES.FETCH_DATA === 'FETCH_DATA');
test('UPDATE_SETTINGS should exist', MESSAGE_TYPES.UPDATE_SETTINGS === 'UPDATE_SETTINGS');
test('VERIFY_URL should exist', MESSAGE_TYPES.VERIFY_URL === 'VERIFY_URL');
test('VALIDATE_TOKEN should exist', MESSAGE_TYPES.VALIDATE_TOKEN === 'VALIDATE_TOKEN');
test('GET_SECRET should exist', MESSAGE_TYPES.GET_SECRET === 'GET_SECRET');
test('PAGE_NAVIGATION should exist', MESSAGE_TYPES.PAGE_NAVIGATION === 'PAGE_NAVIGATION');

// Test 3: Message file contains PAGE_NAVIGATION
console.log('\nTest 3: Source File Validation');
console.log('--------------------------------------------------');
test('shared/message.js should contain PAGE_NAVIGATION', messageContent.includes('PAGE_NAVIGATION'));
test('shared/message.js should export PAGE_NAVIGATION in MESSAGE_TYPES', 
     MESSAGE_TYPES.PAGE_NAVIGATION === 'PAGE_NAVIGATION');

// Test 4: App-side index.js contains logPageNavigation handler
console.log('\nTest 4: App-Side Handler Validation');
console.log('--------------------------------------------------');
const appSidePath = path.join(__dirname, '../app-side/index.js');
const appSideContent = fs.readFileSync(appSidePath, 'utf8');
test('app-side/index.js should check for PAGE_NAVIGATION message', 
     appSideContent.includes('MESSAGE_TYPES.PAGE_NAVIGATION'));
test('app-side/index.js should have logPageNavigation method', 
     appSideContent.includes('logPageNavigation'));
test('app-side/index.js should call logPageNavigation with page and action', 
     appSideContent.includes('logPageNavigation(data.page, data.action)'));

// Test 5: Page files send navigation events
console.log('\nTest 5: Page Implementation Validation');
console.log('--------------------------------------------------');
const page1Path = path.join(__dirname, '../page/index.js');
const page1Content = fs.readFileSync(page1Path, 'utf8');
test('page/index.js should import messaging', 
     page1Content.includes("import * as messaging from '@zos/ble'"));
test('page/index.js should import MESSAGE_TYPES', 
     page1Content.includes('MESSAGE_TYPES'));
test('page/index.js should send PAGE_NAVIGATION on init', 
     page1Content.includes('MESSAGE_TYPES.PAGE_NAVIGATION') && page1Content.includes("action: 'init'"));
test('page/index.js should send PAGE_NAVIGATION on destroy', 
     page1Content.includes('MESSAGE_TYPES.PAGE_NAVIGATION') && page1Content.includes("action: 'destroy'"));

const page2Path = path.join(__dirname, '../page/page2.js');
const page2Content = fs.readFileSync(page2Path, 'utf8');
test('page/page2.js should import messaging', 
     page2Content.includes("import * as messaging from '@zos/ble'"));
test('page/page2.js should import MESSAGE_TYPES', 
     page2Content.includes('MESSAGE_TYPES'));
test('page/page2.js should send PAGE_NAVIGATION on init', 
     page2Content.includes('MESSAGE_TYPES.PAGE_NAVIGATION') && page2Content.includes("action: 'init'"));
test('page/page2.js should send PAGE_NAVIGATION on destroy', 
     page2Content.includes('MESSAGE_TYPES.PAGE_NAVIGATION') && page2Content.includes("action: 'destroy'"));

console.log('\n==================================================');
console.log('Test Summary');
console.log('==================================================');
console.log(`Passed: ${passed}`);
console.log(`Failed: ${failed}`);

if (failed === 0) {
  console.log('\n✓ All tests passed!');
  process.exit(0);
} else {
  console.log(`\n✗ ${failed} test(s) failed!`);
  process.exit(1);
}

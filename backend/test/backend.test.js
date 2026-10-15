const assert = require('assert');
const http = require('http');
const firebaseService = require('../services/firebaseService');

console.log('🧪 Starting PushPilot Backend Unit Tests...\n');

// Test 1: Service Account Validation - Null / Empty
try {
  firebaseService.validateServiceAccountJson(null);
  assert.fail('Should have thrown on null');
} catch (e) {
  assert.strictEqual(e.message.includes('Invalid credentials'), true);
  console.log('✅ Test 1 Passed: Correctly rejects null credentials');
}

// Test 2: Service Account Validation - Detect google-services.json
try {
  const fakeGoogleServices = {
    project_info: { project_number: '123456', project_id: 'sample-app' },
    client: [{ client_info: { mobilesdk_app_id: '1:123:android:abc' } }],
  };
  firebaseService.validateServiceAccountJson(fakeGoogleServices);
  assert.fail('Should have detected google-services.json');
} catch (e) {
  assert.strictEqual(e.message.includes("google-services.json"), true);
  console.log('✅ Test 2 Passed: Correctly catches Android google-services.json confusion');
}

// Test 3: Service Account Validation - Missing fields
try {
  const incompleteJson = {
    type: 'service_account',
    project_id: 'my-project',
    // missing private_key and client_email
  };
  firebaseService.validateServiceAccountJson(incompleteJson);
  assert.fail('Should have failed on missing fields');
} catch (e) {
  assert.strictEqual(e.message.includes('Missing required service account field'), true);
  console.log('✅ Test 3 Passed: Correctly identifies missing private_key and client_email');
}

// Test 4: Token Masking
const longToken = 'fQ91zklA9482710492817409182374981723984712093847109283740981724';
const masked = firebaseService.maskToken(longToken);
assert.strictEqual(masked.startsWith('fQ91zk...'), true);
assert.strictEqual(masked.endsWith('81724'), true);
console.log(`✅ Test 4 Passed: Token correctly masked (${masked})`);

// Test 5: Initial Stats
const stats = firebaseService.getStats();
assert.strictEqual(typeof stats.totalRequests, 'number');
assert.strictEqual(typeof stats.successfulDeliveries, 'number');
console.log('✅ Test 5 Passed: Stats structure is valid');

console.log('\n🎉 All Backend Unit Tests Passed Successfully!\n');

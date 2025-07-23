// ABOUTME: Test script for the new file check API
// ABOUTME: Verifies SHA256 pre-upload duplicate detection functionality

/**
 * File Check API Test Script
 * 
 * Tests the new pre-upload duplicate detection API:
 * 1. GET /api/check/{sha256} - Check single file
 * 2. POST /api/check - Batch check multiple files
 * 
 * Usage:
 * node test_file_check_api.js [--url=http://localhost:8787] [--verbose]
 */

import crypto from 'crypto';

class FileCheckAPITester {
  constructor(options = {}) {
    this.verbose = options.verbose || false;
    this.backendUrl = options.url || 'http://localhost:8787';
  }

  log(message, level = 'info') {
    if (level === 'verbose' && !this.verbose) return;
    const timestamp = new Date().toISOString();
    const prefix = level === 'error' ? '❌' : level === 'warn' ? '⚠️' : level === 'success' ? '✅' : '📋';
    console.log(`${timestamp} ${prefix} ${message}`);
  }

  /**
   * Generate test SHA256 hashes
   */
  generateTestHashes() {
    const testData = [
      'test_video_content_1',
      'test_video_content_2', 
      'identical_content',
      'identical_content', // Duplicate
    ];

    return testData.map(content => {
      const hash = crypto.createHash('sha256').update(content).digest('hex');
      return { content, hash };
    });
  }

  /**
   * Test single file check endpoint
   */
  async testSingleFileCheck(sha256) {
    try {
      this.log(`Testing single file check: ${sha256.substring(0, 16)}...`, 'verbose');
      
      const response = await fetch(`${this.backendUrl}/api/check/${sha256}`, {
        method: 'GET',
        headers: {
          'Accept': 'application/json'
        }
      });

      const result = await response.json();
      
      if (response.ok) {
        this.log(`✅ Single check result: ${result.exists ? 'EXISTS' : 'NOT_FOUND'} - ${result.message}`, 'success');
        if (result.exists) {
          this.log(`   URL: ${result.url}`, 'verbose');
          this.log(`   File ID: ${result.fileId}`, 'verbose');
        }
      } else {
        this.log(`❌ Single check failed (${response.status}): ${result.message || 'Unknown error'}`, 'error');
      }

      return { sha256, response: response.ok, result };
    } catch (error) {
      this.log(`❌ Single check error for ${sha256}: ${error.message}`, 'error');
      return { sha256, response: false, error: error.message };
    }
  }

  /**
   * Test batch file check endpoint
   */
  async testBatchFileCheck(hashes) {
    try {
      this.log(`Testing batch file check with ${hashes.length} files...`, 'verbose');
      
      const requestBody = {
        files: hashes.map(h => ({
          sha256: h.hash,
          filename: `test_${h.content}.mp4`,
          size: h.content.length
        }))
      };

      const response = await fetch(`${this.backendUrl}/api/check`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify(requestBody)
      });

      const result = await response.json();
      
      if (response.ok) {
        this.log(`✅ Batch check completed: ${result.summary?.existing || 0}/${result.summary?.total || 0} files exist`, 'success');
        
        if (result.results) {
          result.results.forEach((fileResult, index) => {
            const status = fileResult.exists ? 'EXISTS' : 'NOT_FOUND';
            this.log(`   ${index + 1}. ${fileResult.sha256.substring(0, 16)}... - ${status}`, 'verbose');
            if (fileResult.exists) {
              this.log(`      URL: ${fileResult.url}`, 'verbose');
            }
          });
        }
      } else {
        this.log(`❌ Batch check failed (${response.status}): ${result.error || 'Unknown error'}`, 'error');
      }

      return { response: response.ok, result };
    } catch (error) {
      this.log(`❌ Batch check error: ${error.message}`, 'error');
      return { response: false, error: error.message };
    }
  }

  /**
   * Test CORS preflight
   */
  async testCORS() {
    try {
      this.log('Testing CORS preflight...', 'verbose');
      
      const response = await fetch(`${this.backendUrl}/api/check`, {
        method: 'OPTIONS',
        headers: {
          'Origin': 'https://openvine.co',
          'Access-Control-Request-Method': 'POST',
          'Access-Control-Request-Headers': 'Content-Type'
        }
      });

      if (response.ok) {
        const corsHeaders = {
          'Access-Control-Allow-Origin': response.headers.get('Access-Control-Allow-Origin'),
          'Access-Control-Allow-Methods': response.headers.get('Access-Control-Allow-Methods'),
          'Access-Control-Allow-Headers': response.headers.get('Access-Control-Allow-Headers')
        };
        
        this.log('✅ CORS preflight successful', 'success');
        this.log(`   Allow-Origin: ${corsHeaders['Access-Control-Allow-Origin']}`, 'verbose');
        this.log(`   Allow-Methods: ${corsHeaders['Access-Control-Allow-Methods']}`, 'verbose');
        
        return true;
      } else {
        this.log(`❌ CORS preflight failed (${response.status})`, 'error');
        return false;
      }
    } catch (error) {
      this.log(`❌ CORS test error: ${error.message}`, 'error');
      return false;
    }
  }

  /**
   * Test invalid inputs
   */
  async testInvalidInputs() {
    this.log('Testing invalid inputs...', 'verbose');
    
    const tests = [
      { 
        name: 'Invalid SHA256 format', 
        sha256: 'invalid_hash',
        expectedStatus: 400
      },
      { 
        name: 'Short SHA256', 
        sha256: 'abc123',
        expectedStatus: 400
      },
      { 
        name: 'Missing SHA256', 
        sha256: '',
        expectedStatus: 400
      }
    ];

    let passed = 0;
    
    for (const test of tests) {
      try {
        const response = await fetch(`${this.backendUrl}/api/check/${test.sha256}`, {
          method: 'GET',
          headers: { 'Accept': 'application/json' }
        });

        if (response.status === test.expectedStatus) {
          this.log(`✅ ${test.name}: Got expected status ${test.expectedStatus}`, 'success');
          passed++;
        } else {
          this.log(`❌ ${test.name}: Expected ${test.expectedStatus}, got ${response.status}`, 'error');
        }
      } catch (error) {
        this.log(`❌ ${test.name}: Error - ${error.message}`, 'error');
      }
    }

    return passed === tests.length;
  }

  /**
   * Check backend availability
   */
  async checkBackendHealth() {
    try {
      this.log('Checking backend health...', 'verbose');
      
      const response = await fetch(`${this.backendUrl}/api/info`, {
        method: 'GET',
        headers: { 'Accept': 'application/json' }
      });

      if (response.ok) {
        const info = await response.json();
        this.log(`✅ Backend healthy: ${this.backendUrl}`, 'success');
        this.log(`   Version: ${info.version || 'unknown'}`, 'verbose');
        return true;
      } else {
        this.log(`⚠️  Backend responded but unhealthy (${response.status})`, 'warn');
        return false;
      }
    } catch (error) {
      this.log(`❌ Backend not available: ${error.message}`, 'error');
      this.log('Make sure the backend is running with: npm run dev', 'error');
      return false;
    }
  }

  /**
   * Run complete test suite
   */
  async run() {
    try {
      this.log('🧪 Starting File Check API tests...');
      this.log(`Target: ${this.backendUrl}`);
      
      // Check backend health
      const isHealthy = await this.checkBackendHealth();
      if (!isHealthy) {
        this.log('❌ Backend not available, aborting tests', 'error');
        process.exit(1);
      }

      // Generate test data
      const testHashes = this.generateTestHashes();
      this.log(`Generated ${testHashes.length} test hashes`, 'verbose');

      let totalTests = 0;
      let passedTests = 0;

      // Test 1: CORS
      totalTests++;
      const corsResult = await this.testCORS();
      if (corsResult) passedTests++;

      // Test 2: Invalid inputs
      totalTests++;
      const invalidResult = await this.testInvalidInputs();
      if (invalidResult) passedTests++;

      // Test 3: Single file checks
      for (const hash of testHashes) {
        totalTests++;
        const result = await this.testSingleFileCheck(hash.hash);
        if (result.response) passedTests++;
      }

      // Test 4: Batch file check
      totalTests++;
      const batchResult = await this.testBatchFileCheck(testHashes);
      if (batchResult.response) passedTests++;

      // Results
      this.log('\n📊 TEST RESULTS:', 'success');
      this.log(`Total tests: ${totalTests}`);
      this.log(`Passed: ${passedTests}`);
      this.log(`Failed: ${totalTests - passedTests}`);
      this.log(`Success rate: ${((passedTests / totalTests) * 100).toFixed(1)}%`);

      if (passedTests === totalTests) {
        this.log('\n✅ ALL TESTS PASSED - File Check API is working!', 'success');
        process.exit(0);
      } else {
        this.log('\n❌ SOME TESTS FAILED - Check backend logs', 'error');
        process.exit(1);
      }

    } catch (error) {
      this.log(`Fatal error: ${error.message}`, 'error');
      console.error(error.stack);
      process.exit(2);
    }
  }
}

// Parse command line arguments
const args = process.argv.slice(2);
const options = {
  verbose: args.includes('--verbose') || args.includes('-v'),
  url: args.find(arg => arg.startsWith('--url='))?.split('=')[1] || 'http://localhost:8787'
};

if (args.includes('--help') || args.includes('-h')) {
  console.log(`
File Check API Test Tool

Usage: node test_file_check_api.js [options]

Options:
  --url=URL         Backend URL (default: http://localhost:8787)
  --verbose, -v     Show detailed output
  --help, -h        Show this help message

Examples:
  node test_file_check_api.js                     # Test local backend
  node test_file_check_api.js --verbose           # Detailed output
  node test_file_check_api.js --url=https://api.openvine.co # Test production
`);
  process.exit(0);
}

// Run the tests
const tester = new FileCheckAPITester(options);
tester.run().catch(error => {
  console.error('Unhandled error:', error);
  process.exit(2);
});
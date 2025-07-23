// ABOUTME: Test script to simulate concurrent uploads and detect race conditions
// ABOUTME: Creates identical files and uploads them simultaneously to test deduplication

/**
 * Concurrent Upload Test Script for OpenVine
 * 
 * This script tests for race conditions in the upload system by:
 * 1. Creating identical test files with same content/SHA256
 * 2. Uploading them concurrently to trigger race conditions
 * 3. Checking if duplicates are created in R2 storage
 * 4. Verifying SHA256 deduplication works correctly
 * 
 * Usage:
 * node test_concurrent_uploads.js [--count=5] [--size=1MB] [--verbose]
 */

import fs from 'fs/promises';
import crypto from 'crypto';
import path from 'path';
import { performance } from 'perf_hooks';

class ConcurrentUploadTester {
  constructor(options = {}) {
    this.verbose = options.verbose || false;
    this.uploadCount = options.count || 5;
    this.fileSize = this.parseSize(options.size || '1MB');
    this.backendUrl = options.url || 'http://localhost:8787'; // Local dev server
    this.testFiles = [];
    this.uploadResults = [];
    this.tempDir = '/tmp/openvine_test_uploads';
  }

  log(message, level = 'info') {
    if (level === 'verbose' && !this.verbose) return;
    const timestamp = new Date().toISOString();
    const prefix = level === 'error' ? '❌' : level === 'warn' ? '⚠️' : level === 'success' ? '✅' : '📋';
    console.log(`${timestamp} ${prefix} ${message}`);
  }

  /**
   * Parse size string like "1MB", "500KB" to bytes
   */
  parseSize(sizeStr) {
    const units = { B: 1, KB: 1024, MB: 1024 * 1024, GB: 1024 * 1024 * 1024 };
    const match = sizeStr.match(/^(\d+(?:\.\d+)?)(B|KB|MB|GB)$/i);
    if (!match) throw new Error(`Invalid size format: ${sizeStr}`);
    
    const [, number, unit] = match;
    return Math.floor(parseFloat(number) * units[unit.toUpperCase()]);
  }

  /**
   * Generate test file with specific content pattern
   */
  async generateTestFile(index, contentPattern = 'identical') {
    const filename = `test_file_${index}.mp4`;
    const filepath = path.join(this.tempDir, filename);
    
    let content;
    if (contentPattern === 'identical') {
      // All files have identical content (should trigger deduplication)
      content = Buffer.alloc(this.fileSize, 0x42); // Fill with 'B' bytes
      content.write('OPENVINE_TEST_VIDEO_IDENTICAL_CONTENT', 0);
    } else if (contentPattern === 'unique') {
      // Each file has unique content
      content = Buffer.alloc(this.fileSize, index % 256);
      content.write(`OPENVINE_TEST_VIDEO_UNIQUE_${index}`, 0);
    } else if (contentPattern === 'similar') {
      // Similar files with small differences (should not trigger deduplication)
      content = Buffer.alloc(this.fileSize, 0x42);
      content.write(`OPENVINE_TEST_VIDEO_SIMILAR_${index}`, 0);
    }
    
    await fs.writeFile(filepath, content);
    
    const sha256 = crypto.createHash('sha256').update(content).digest('hex');
    
    const fileInfo = {
      index,
      filename,
      filepath,
      size: content.length,
      sha256,
      contentPattern
    };
    
    this.testFiles.push(fileInfo);
    this.log(`Generated test file ${index}: ${filename} (${content.length} bytes, SHA256: ${sha256.substring(0, 16)}...)`, 'verbose');
    
    return fileInfo;
  }

  /**
   * Create a mock NIP-98 auth token for testing
   */
  createMockAuthToken() {
    // This is a simplified mock - in production you'd need proper Nostr signing
    const mockEvent = {
      kind: 27235,
      tags: [
        ['u', `${this.backendUrl}/api/upload`],
        ['method', 'POST']
      ],
      content: '',
      created_at: Math.floor(Date.now() / 1000)
    };
    
    // Base64 encode the mock event
    return 'Nostr ' + Buffer.from(JSON.stringify(mockEvent)).toString('base64');
  }

  /**
   * Upload a single file to the backend
   */
  async uploadFile(fileInfo, uploadIndex) {
    const startTime = performance.now();
    
    try {
      this.log(`Starting upload ${uploadIndex} for file ${fileInfo.index}...`, 'verbose');
      
      // Read file
      const fileData = await fs.readFile(fileInfo.filepath);
      
      // Create form data
      const formData = new FormData();
      const blob = new Blob([fileData], { type: 'video/mp4' });
      formData.append('file', blob, fileInfo.filename);
      formData.append('title', `Test Upload ${uploadIndex}`);
      formData.append('description', `Concurrent upload test ${uploadIndex} - pattern: ${fileInfo.contentPattern}`);
      
      // Make request with auth
      const response = await fetch(`${this.backendUrl}/api/upload`, {
        method: 'POST',
        headers: {
          'Authorization': this.createMockAuthToken()
        },
        body: formData
      });
      
      const endTime = performance.now();
      const duration = endTime - startTime;
      
      const responseText = await response.text();
      let responseData;
      try {
        responseData = JSON.parse(responseText);
      } catch {
        responseData = { raw: responseText };
      }
      
      const result = {
        uploadIndex,
        fileInfo,
        success: response.ok,
        status: response.status,
        duration,
        response: responseData,
        startTime,
        endTime
      };
      
      if (response.ok) {
        this.log(`Upload ${uploadIndex} succeeded in ${duration.toFixed(1)}ms: ${responseData.download_url || 'no URL'}`, 'verbose');
      } else {
        this.log(`Upload ${uploadIndex} failed (${response.status}): ${responseData.message || responseText}`, 'error');
      }
      
      this.uploadResults.push(result);
      return result;
      
    } catch (error) {
      const endTime = performance.now();
      const duration = endTime - startTime;
      
      this.log(`Upload ${uploadIndex} error after ${duration.toFixed(1)}ms: ${error.message}`, 'error');
      
      const result = {
        uploadIndex,
        fileInfo,
        success: false,
        error: error.message,
        duration,
        startTime,
        endTime
      };
      
      this.uploadResults.push(result);
      return result;
    }
  }

  /**
   * Run concurrent uploads
   */
  async runConcurrentUploads(files) {
    this.log(`🚀 Starting ${files.length} concurrent uploads...`);
    
    const uploadPromises = files.map((file, index) => 
      this.uploadFile(file, index + 1)
    );
    
    // Start all uploads simultaneously
    const results = await Promise.allSettled(uploadPromises);
    
    this.log(`✅ All ${files.length} uploads completed`);
    return results;
  }

  /**
   * Analyze upload results for duplicates
   */
  analyzeResults() {
    this.log('\n🔍 ANALYZING UPLOAD RESULTS...');
    
    const successful = this.uploadResults.filter(r => r.success);
    const failed = this.uploadResults.filter(r => !r.success);
    
    this.log(`Total uploads: ${this.uploadResults.length}`);
    this.log(`Successful: ${successful.length}`);
    this.log(`Failed: ${failed.length}`);
    
    if (failed.length > 0) {
      this.log('\n❌ FAILED UPLOADS:', 'error');
      failed.forEach(result => {
        this.log(`  Upload ${result.uploadIndex}: ${result.error || 'Unknown error'}`, 'error');
      });
    }
    
    if (successful.length === 0) {
      this.log('❌ No successful uploads to analyze', 'error');
      return { hasDuplicates: false, hasDeduplication: false };
    }
    
    // Group by SHA256 to detect duplicates
    const bySha256 = new Map();
    const byUrl = new Map();
    const byVideoId = new Map();
    
    successful.forEach(result => {
      const sha256 = result.fileInfo.sha256;
      const url = result.response.download_url || result.response.url;
      const videoId = result.response.video_id || this.extractVideoIdFromUrl(url);
      
      // Group by SHA256
      if (!bySha256.has(sha256)) bySha256.set(sha256, []);
      bySha256.get(sha256).push(result);
      
      // Group by URL
      if (url) {
        if (!byUrl.has(url)) byUrl.set(url, []);
        byUrl.get(url).push(result);
      }
      
      // Group by video ID
      if (videoId) {
        if (!byVideoId.has(videoId)) byVideoId.set(videoId, []);
        byVideoId.get(videoId).push(result);
      }
    });
    
    // Analyze deduplication effectiveness
    this.log('\n📊 DEDUPLICATION ANALYSIS:');
    
    let hasDuplicates = false;
    let hasDeduplication = false;
    
    // Check SHA256 groups
    for (const [sha256, results] of bySha256) {
      if (results.length > 1) {
        const urls = [...new Set(results.map(r => r.response.download_url || r.response.url))];
        const videoIds = [...new Set(results.map(r => r.response.video_id || this.extractVideoIdFromUrl(r.response.download_url)))];
        
        if (urls.length === 1) {
          // Good: Multiple uploads of same content returned same URL (deduplication worked)
          hasDeduplication = true;
          this.log(`✅ Deduplication worked: ${results.length} uploads with SHA256 ${sha256.substring(0, 16)}... returned same URL: ${urls[0]}`, 'success');
        } else {
          // Bad: Multiple uploads of same content got different URLs (duplicates created)
          hasDuplicates = true;
          this.log(`❌ DUPLICATES CREATED: ${results.length} uploads with SHA256 ${sha256.substring(0, 16)}... got different URLs:`, 'error');
          urls.forEach((url, i) => {
            const count = results.filter(r => (r.response.download_url || r.response.url) === url).length;
            this.log(`    ${count}x ${url}`, 'error');
          });
        }
      }
    }
    
    // Check timing for race conditions
    this.log('\n⏱️  TIMING ANALYSIS:');
    const timings = successful.map(r => ({ upload: r.uploadIndex, start: r.startTime, end: r.endTime, duration: r.duration }));
    timings.sort((a, b) => a.start - b.start);
    
    this.log('Upload timeline:');
    timings.forEach(t => {
      this.log(`  Upload ${t.upload}: ${t.duration.toFixed(1)}ms (started at +${(t.start - timings[0].start).toFixed(1)}ms)`, 'verbose');
    });
    
    const overlapCount = this.calculateOverlaps(timings);
    if (overlapCount > 0) {
      this.log(`⚠️  Found ${overlapCount} overlapping uploads (potential race condition window)`, 'warn');
    } else {
      this.log(`✅ No overlapping uploads detected`, 'success');
    }
    
    return { hasDuplicates, hasDeduplication, overlapCount };
  }

  /**
   * Calculate how many uploads overlapped in time
   */
  calculateOverlaps(timings) {
    let overlaps = 0;
    for (let i = 0; i < timings.length; i++) {
      for (let j = i + 1; j < timings.length; j++) {
        const a = timings[i];
        const b = timings[j];
        
        // Check if uploads overlapped
        if (a.start < b.end && b.start < a.end) {
          overlaps++;
        }
      }
    }
    return overlaps;
  }

  /**
   * Extract video ID from URL
   */
  extractVideoIdFromUrl(url) {
    if (!url) return null;
    const match = url.match(/\/media\/([^\/\?]+)/);
    return match ? match[1] : null;
  }

  /**
   * Setup test environment
   */
  async setupEnvironment() {
    this.log('🛠️  Setting up test environment...');
    
    // Create temp directory
    try {
      await fs.mkdir(this.tempDir, { recursive: true });
      this.log(`Created temp directory: ${this.tempDir}`, 'verbose');
    } catch (error) {
      if (error.code !== 'EEXIST') throw error;
    }
    
    // Check if backend is available
    try {
      const response = await fetch(`${this.backendUrl}/api/info`);
      if (response.ok) {
        const info = await response.json();
        this.log(`✅ Backend available: ${this.backendUrl} (${info.version || 'unknown version'})`, 'success');
      } else {
        this.log(`⚠️  Backend responded with ${response.status}, but continuing test...`, 'warn');
      }
    } catch (error) {
      this.log(`⚠️  Backend not available at ${this.backendUrl}: ${error.message}`, 'warn');
      this.log('Continuing with test - uploads may fail if backend is down', 'warn');
    }
  }

  /**
   * Cleanup test files
   */
  async cleanup() {
    this.log('🧹 Cleaning up test files...');
    
    try {
      for (const file of this.testFiles) {
        await fs.unlink(file.filepath);
        this.log(`Deleted ${file.filename}`, 'verbose');
      }
      
      // Remove temp directory if empty
      try {
        await fs.rmdir(this.tempDir);
        this.log(`Removed temp directory: ${this.tempDir}`, 'verbose');
      } catch (error) {
        // Directory not empty or doesn't exist - that's fine
      }
      
    } catch (error) {
      this.log(`Cleanup error: ${error.message}`, 'warn');
    }
  }

  /**
   * Run the complete test suite
   */
  async run() {
    try {
      this.log('🧪 Starting concurrent upload test...');
      this.log(`Configuration: ${this.uploadCount} uploads, ${this.fileSize} bytes each`);
      
      await this.setupEnvironment();
      
      // Test 1: Identical content (should trigger deduplication)
      this.log('\n📋 TEST 1: Identical content (testing deduplication)...');
      this.testFiles = [];
      this.uploadResults = [];
      
      for (let i = 0; i < this.uploadCount; i++) {
        await this.generateTestFile(i, 'identical');
      }
      
      await this.runConcurrentUploads(this.testFiles);
      const identicalResults = this.analyzeResults();
      
      // Test 2: Unique content (should not trigger deduplication)
      this.log('\n📋 TEST 2: Unique content (no deduplication expected)...');
      this.testFiles = [];
      this.uploadResults = [];
      
      for (let i = 0; i < Math.min(3, this.uploadCount); i++) { // Fewer files for unique test
        await this.generateTestFile(i, 'unique');
      }
      
      await this.runConcurrentUploads(this.testFiles);
      const uniqueResults = this.analyzeResults();
      
      // Final report
      this.log('\n📊 FINAL REPORT:', 'success');
      this.log('=' * 50, 'success');
      
      if (identicalResults.hasDuplicates) {
        this.log('❌ CRITICAL: Deduplication failed - identical files created duplicates!', 'error');
        this.log('   This indicates a race condition in the SHA256 deduplication logic.', 'error');
      } else if (identicalResults.hasDeduplication) {
        this.log('✅ SUCCESS: Deduplication working - identical files returned same URL', 'success');
      } else {
        this.log('⚠️  INCONCLUSIVE: No identical files uploaded successfully', 'warn');
      }
      
      if (uniqueResults.hasDuplicates) {
        this.log('❌ UNEXPECTED: Unique files incorrectly deduplicated', 'error');
      }
      
      if (identicalResults.overlapCount > 0) {
        this.log(`⚠️  Race condition window detected: ${identicalResults.overlapCount} overlapping uploads`, 'warn');
      }
      
      await this.cleanup();
      
      // Exit with appropriate code
      if (identicalResults.hasDuplicates || uniqueResults.hasDuplicates) {
        this.log('\n❌ TEST FAILED: Duplicate issues detected', 'error');
        process.exit(1);
      } else if (identicalResults.hasDeduplication) {
        this.log('\n✅ TEST PASSED: Deduplication working correctly', 'success');
        process.exit(0);
      } else {
        this.log('\n⚠️  TEST INCONCLUSIVE: Unable to verify deduplication', 'warn');
        process.exit(2);
      }
      
    } catch (error) {
      this.log(`Fatal error: ${error.message}`, 'error');
      console.error(error.stack);
      await this.cleanup();
      process.exit(3);
    }
  }
}

// Parse command line arguments
const args = process.argv.slice(2);
const options = {
  verbose: args.includes('--verbose') || args.includes('-v'),
  count: parseInt(args.find(arg => arg.startsWith('--count='))?.split('=')[1]) || 5,
  size: args.find(arg => arg.startsWith('--size='))?.split('=')[1] || '1MB',
  url: args.find(arg => arg.startsWith('--url='))?.split('=')[1] || 'http://localhost:8787'
};

if (args.includes('--help') || args.includes('-h')) {
  console.log(`
OpenVine Concurrent Upload Test Tool

Usage: node test_concurrent_uploads.js [options]

Options:
  --count=N         Number of concurrent uploads (default: 5)
  --size=SIZE       File size like 1MB, 500KB (default: 1MB)
  --url=URL         Backend URL (default: http://localhost:8787)
  --verbose, -v     Show detailed output
  --help, -h        Show this help message

Exit codes:
  0  Test passed - deduplication working
  1  Test failed - duplicates detected
  2  Test inconclusive
  3  Fatal error

Examples:
  node test_concurrent_uploads.js                     # Basic test
  node test_concurrent_uploads.js --count=10 --verbose # More uploads with details
  node test_concurrent_uploads.js --size=5MB          # Larger files
  node test_concurrent_uploads.js --url=https://api.openvine.co # Production test
`);
  process.exit(0);
}

// Run the tester
const tester = new ConcurrentUploadTester(options);
tester.run().catch(error => {
  console.error('Unhandled error:', error);
  process.exit(3);
});
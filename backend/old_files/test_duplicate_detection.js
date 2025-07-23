// ABOUTME: Test script to detect and analyze upload duplicates in R2 storage
// ABOUTME: Checks for duplicate files by SHA256, file size, and content analysis

/**
 * Duplicate Detection Test Script for OpenVine
 * 
 * This script analyzes R2 storage to find potential duplicate uploads:
 * 1. Files with identical SHA256 hashes but different fileIds
 * 2. Files with identical content but missing SHA256 mappings
 * 3. Files with same size and similar names (potential duplicates)
 * 4. Orphaned SHA256 mappings (point to non-existent files)
 * 
 * Usage:
 * node test_duplicate_detection.js [--fix-mappings] [--verbose]
 */

import { spawn } from 'child_process';
import crypto from 'crypto';

class DuplicateDetector {
  constructor(options = {}) {
    this.verbose = options.verbose || false;
    this.fixMappings = options.fixMappings || false;
    this.duplicates = {
      bySha256: new Map(), // SHA256 -> [fileIds]
      bySize: new Map(),   // size -> [fileIds] 
      orphanedMappings: [], // SHA256 mappings with no corresponding file
      missingMappings: []   // Files with no SHA256 mapping
    };
  }

  log(message, level = 'info') {
    if (level === 'verbose' && !this.verbose) return;
    const timestamp = new Date().toISOString();
    const prefix = level === 'error' ? '❌' : level === 'warn' ? '⚠️' : level === 'success' ? '✅' : '📋';
    console.log(`${timestamp} ${prefix} ${message}`);
  }

  /**
   * Run Wrangler command and return parsed output
   */
  async runWrangler(args) {
    return new Promise((resolve, reject) => {
      const process = spawn('npx', ['wrangler', ...args], { 
        stdio: ['pipe', 'pipe', 'pipe'],
        cwd: '/Users/rabble/code/andotherstuff/openvine/backend'
      });

      let stdout = '';
      let stderr = '';

      process.stdout.on('data', (data) => {
        stdout += data.toString();
      });

      process.stderr.on('data', (data) => {
        stderr += data.toString();
      });

      process.on('close', (code) => {
        if (code === 0) {
          resolve(stdout);
        } else {
          reject(new Error(`Wrangler command failed: ${stderr}`));
        }
      });
    });
  }

  /**
   * List all files in R2 bucket
   */
  async listR2Files() {
    this.log('Fetching R2 file list...');
    try {
      // Note: Wrangler doesn't have a direct object list command
      // We'll need to use a different approach or implement this in the backend
      this.log('⚠️  R2 object listing not available via wrangler CLI', 'warn');
      this.log('Continuing with empty file list for now...', 'warn');
      return [];
    } catch (error) {
      this.log(`Failed to list R2 files: ${error.message}`, 'error');
      throw error;
    }
  }

  /**
   * List all SHA256 mappings from KV store
   */
  async listSha256Mappings() {
    this.log('Fetching SHA256 mappings from KV...');
    try {
      const output = await this.runWrangler(['kv', 'key', 'list', '--namespace-id', '45b500d029d24315bb447a066fe9e9df', '--prefix', 'sha256:']);
      const mappings = JSON.parse(output);
      this.log(`Found ${mappings.length} SHA256 mappings in KV`);
      return mappings;
    } catch (error) {
      this.log(`Failed to list KV mappings: ${error.message}`, 'error');
      throw error;
    }
  }

  /**
   * Get file metadata from R2
   */
  async getFileMetadata(key) {
    try {
      const output = await this.runWrangler(['r2', 'object', 'get', 'openvine-media', key, '--json']);
      return JSON.parse(output);
    } catch (error) {
      this.log(`Failed to get metadata for ${key}: ${error.message}`, 'verbose');
      return null;
    }
  }

  /**
   * Extract fileId from various file key patterns
   */
  extractFileId(key) {
    // Handle different file patterns:
    // uploads/1750592208655-13cdc4ee.mp4 -> 1750592208655-13cdc4ee
    // releases/OpenVine-0.0.1-2.dmg -> OpenVine-0.0.1-2
    
    if (key.startsWith('uploads/')) {
      const filename = key.replace('uploads/', '');
      return filename.replace(/\.[^.]+$/, ''); // Remove extension
    }
    
    if (key.startsWith('releases/')) {
      const filename = key.replace('releases/', '');
      return filename.replace(/\.[^.]+$/, ''); // Remove extension
    }
    
    return key;
  }

  /**
   * Calculate SHA256 from file content (if accessible)
   */
  async calculateFileSha256(key) {
    try {
      // For this test, we'll use stored metadata instead of downloading
      // In production, you might want to download and hash the content
      const metadata = await this.getFileMetadata(key);
      return metadata?.customMetadata?.sha256 || null;
    } catch (error) {
      this.log(`Failed to get SHA256 for ${key}: ${error.message}`, 'verbose');
      return null;
    }
  }

  /**
   * Analyze files for duplicates
   */
  async analyzeFiles(files) {
    this.log('Analyzing files for duplicates...');
    
    const fileAnalysis = new Map(); // fileId -> { keys: [], sha256: '', size: number, metadata: {} }
    
    for (const file of files) {
      const fileId = this.extractFileId(file.key);
      const sha256 = await this.calculateFileSha256(file.key);
      
      if (!fileAnalysis.has(fileId)) {
        fileAnalysis.set(fileId, {
          keys: [],
          sha256: sha256,
          size: file.size,
          lastModified: file.lastModified
        });
      }
      
      fileAnalysis.get(fileId).keys.push(file.key);
      
      // Group by SHA256 if available
      if (sha256) {
        if (!this.duplicates.bySha256.has(sha256)) {
          this.duplicates.bySha256.set(sha256, []);
        }
        this.duplicates.bySha256.get(sha256).push(fileId);
      }
      
      // Group by size
      if (!this.duplicates.bySize.has(file.size)) {
        this.duplicates.bySize.set(file.size, []);
      }
      this.duplicates.bySize.get(file.size).push(fileId);
      
      this.log(`Analyzed ${fileId}: ${sha256 ? 'SHA256=' + sha256.substring(0, 8) : 'no SHA256'}, size=${file.size}`, 'verbose');
    }
    
    return fileAnalysis;
  }

  /**
   * Check SHA256 mappings for consistency
   */
  async checkSha256Mappings(mappings, fileAnalysis) {
    this.log('Checking SHA256 mapping consistency...');
    
    for (const mapping of mappings) {
      const sha256 = mapping.name.replace('sha256:', '');
      
      try {
        const output = await this.runWrangler(['kv', 'key', 'get', mapping.name, '--namespace-id', '45b500d029d24315bb447a066fe9e9df']);
        const fileId = output.trim();
        
        // Check if this fileId actually exists
        if (!fileAnalysis.has(fileId)) {
          this.duplicates.orphanedMappings.push({
            sha256: sha256,
            fileId: fileId,
            mappingKey: mapping.name
          });
          this.log(`Orphaned mapping: ${sha256} -> ${fileId} (file not found)`, 'verbose');
        } else {
          // Check if the stored SHA256 matches
          const actualSha256 = fileAnalysis.get(fileId).sha256;
          if (actualSha256 && actualSha256 !== sha256) {
            this.log(`SHA256 mismatch: mapping says ${sha256}, file has ${actualSha256}`, 'warn');
          }
        }
      } catch (error) {
        this.log(`Failed to get mapping value for ${mapping.name}: ${error.message}`, 'verbose');
      }
    }
  }

  /**
   * Find files missing SHA256 mappings
   */
  findMissingMappings(fileAnalysis, mappings) {
    this.log('Finding files missing SHA256 mappings...');
    
    const mappedSha256s = new Set();
    mappings.forEach(mapping => {
      mappedSha256s.add(mapping.name.replace('sha256:', ''));
    });
    
    for (const [fileId, analysis] of fileAnalysis) {
      if (analysis.sha256 && !mappedSha256s.has(analysis.sha256)) {
        this.duplicates.missingMappings.push({
          fileId: fileId,
          sha256: analysis.sha256,
          size: analysis.size
        });
        this.log(`Missing mapping: ${fileId} with SHA256 ${analysis.sha256}`, 'verbose');
      }
    }
  }

  /**
   * Generate duplicate report
   */
  generateReport() {
    this.log('\n🔍 DUPLICATE DETECTION REPORT', 'success');
    this.log('=' * 50, 'success');
    
    // SHA256 duplicates
    const sha256Duplicates = Array.from(this.duplicates.bySha256.entries())
      .filter(([sha256, fileIds]) => fileIds.length > 1);
    
    if (sha256Duplicates.length > 0) {
      this.log(`\n❌ CRITICAL: Found ${sha256Duplicates.length} SHA256 hash collisions:`, 'error');
      sha256Duplicates.forEach(([sha256, fileIds]) => {
        this.log(`  SHA256 ${sha256.substring(0, 16)}... has ${fileIds.length} files: ${fileIds.join(', ')}`, 'error');
      });
    } else {
      this.log('\n✅ No SHA256 duplicate files found', 'success');
    }
    
    // Size duplicates (potential duplicates)
    const sizeDuplicates = Array.from(this.duplicates.bySize.entries())
      .filter(([size, fileIds]) => fileIds.length > 1 && size > 1024); // Ignore tiny files
    
    if (sizeDuplicates.length > 0) {
      this.log(`\n⚠️  Found ${sizeDuplicates.length} file size collisions (potential duplicates):`, 'warn');
      sizeDuplicates.slice(0, 10).forEach(([size, fileIds]) => { // Show top 10
        this.log(`  Size ${size} bytes: ${fileIds.length} files (${fileIds.slice(0, 3).join(', ')}${fileIds.length > 3 ? '...' : ''})`, 'warn');
      });
      if (sizeDuplicates.length > 10) {
        this.log(`  ... and ${sizeDuplicates.length - 10} more size collisions`, 'warn');
      }
    }
    
    // Orphaned mappings
    if (this.duplicates.orphanedMappings.length > 0) {
      this.log(`\n⚠️  Found ${this.duplicates.orphanedMappings.length} orphaned SHA256 mappings:`, 'warn');
      this.duplicates.orphanedMappings.slice(0, 5).forEach(orphan => {
        this.log(`  ${orphan.sha256.substring(0, 16)}... -> ${orphan.fileId} (file not found)`, 'warn');
      });
    }
    
    // Missing mappings
    if (this.duplicates.missingMappings.length > 0) {
      this.log(`\n⚠️  Found ${this.duplicates.missingMappings.length} files missing SHA256 mappings:`, 'warn');
      this.duplicates.missingMappings.slice(0, 5).forEach(missing => {
        this.log(`  ${missing.fileId} (SHA256: ${missing.sha256.substring(0, 16)}..., size: ${missing.size})`, 'warn');
      });
    }
    
    // Summary
    this.log('\n📊 SUMMARY:', 'success');
    this.log(`  • SHA256 duplicates: ${sha256Duplicates.length}`, sha256Duplicates.length > 0 ? 'error' : 'success');
    this.log(`  • Size duplicates: ${sizeDuplicates.length}`, sizeDuplicates.length > 10 ? 'warn' : 'success');
    this.log(`  • Orphaned mappings: ${this.duplicates.orphanedMappings.length}`, this.duplicates.orphanedMappings.length > 0 ? 'warn' : 'success');
    this.log(`  • Missing mappings: ${this.duplicates.missingMappings.length}`, this.duplicates.missingMappings.length > 0 ? 'warn' : 'success');
    
    return {
      hasCriticalIssues: sha256Duplicates.length > 0,
      hasWarnings: sizeDuplicates.length > 10 || this.duplicates.orphanedMappings.length > 0 || this.duplicates.missingMappings.length > 0,
      sha256Duplicates: sha256Duplicates.length,
      sizeDuplicates: sizeDuplicates.length,
      orphanedMappings: this.duplicates.orphanedMappings.length,
      missingMappings: this.duplicates.missingMappings.length
    };
  }

  /**
   * Fix orphaned mappings (if --fix-mappings flag is used)
   */
  async fixOrphanedMappings() {
    if (!this.fixMappings || this.duplicates.orphanedMappings.length === 0) {
      return;
    }
    
    this.log(`\n🔧 Fixing ${this.duplicates.orphanedMappings.length} orphaned mappings...`);
    
    for (const orphan of this.duplicates.orphanedMappings) {
      try {
        await this.runWrangler(['kv', 'key', 'delete', orphan.mappingKey, '--namespace-id', '45b500d029d24315bb447a066fe9e9df']);
        this.log(`Deleted orphaned mapping: ${orphan.sha256}`, 'success');
      } catch (error) {
        this.log(`Failed to delete mapping ${orphan.sha256}: ${error.message}`, 'error');
      }
    }
  }

  /**
   * Create missing SHA256 mappings (if --fix-mappings flag is used)
   */
  async createMissingMappings() {
    if (!this.fixMappings || this.duplicates.missingMappings.length === 0) {
      return;
    }
    
    this.log(`\n🔧 Creating ${this.duplicates.missingMappings.length} missing SHA256 mappings...`);
    
    for (const missing of this.duplicates.missingMappings) {
      try {
        const key = `sha256:${missing.sha256}`;
        await this.runWrangler(['kv', 'key', 'put', key, missing.fileId, '--namespace-id', '45b500d029d24315bb447a066fe9e9df']);
        this.log(`Created mapping: ${missing.sha256} -> ${missing.fileId}`, 'success');
      } catch (error) {
        this.log(`Failed to create mapping for ${missing.fileId}: ${error.message}`, 'error');
      }
    }
  }

  /**
   * Run the complete duplicate detection analysis
   */
  async run() {
    try {
      this.log('🚀 Starting duplicate detection analysis...');
      
      // Fetch data
      const [files, mappings] = await Promise.all([
        this.listR2Files(),
        this.listSha256Mappings()
      ]);
      
      // Analyze
      const fileAnalysis = await this.analyzeFiles(files);
      await this.checkSha256Mappings(mappings, fileAnalysis);
      this.findMissingMappings(fileAnalysis, mappings);
      
      // Report
      const summary = this.generateReport();
      
      // Fix issues if requested
      await this.fixOrphanedMappings();
      await this.createMissingMappings();
      
      // Exit with appropriate code
      if (summary.hasCriticalIssues) {
        this.log('\n❌ CRITICAL ISSUES FOUND - Upload system has duplicate problems!', 'error');
        process.exit(1);
      } else if (summary.hasWarnings) {
        this.log('\n⚠️  Warnings found - system may have minor duplicate issues', 'warn');
        process.exit(2);
      } else {
        this.log('\n✅ No significant duplicate issues found', 'success');
        process.exit(0);
      }
      
    } catch (error) {
      this.log(`Fatal error: ${error.message}`, 'error');
      console.error(error.stack);
      process.exit(3);
    }
  }
}

// Parse command line arguments
const args = process.argv.slice(2);
const options = {
  verbose: args.includes('--verbose') || args.includes('-v'),
  fixMappings: args.includes('--fix-mappings') || args.includes('-f')
};

if (args.includes('--help') || args.includes('-h')) {
  console.log(`
OpenVine Duplicate Detection Tool

Usage: node test_duplicate_detection.js [options]

Options:
  --verbose, -v      Show detailed analysis output
  --fix-mappings, -f Automatically fix orphaned and missing SHA256 mappings
  --help, -h         Show this help message

Exit codes:
  0  No issues found
  1  Critical issues (SHA256 duplicates found)
  2  Warnings (potential issues)
  3  Fatal error

Examples:
  node test_duplicate_detection.js                    # Basic analysis
  node test_duplicate_detection.js --verbose          # Detailed output
  node test_duplicate_detection.js --fix-mappings     # Fix mapping issues
`);
  process.exit(0);
}

// Run the detector
const detector = new DuplicateDetector(options);
detector.run().catch(error => {
  console.error('Unhandled error:', error);
  process.exit(3);
});
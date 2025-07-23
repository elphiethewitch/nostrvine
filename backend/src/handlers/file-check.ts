// ABOUTME: Pre-upload file existence check using SHA256 hash
// ABOUTME: Allows clients to verify if file already exists before uploading

import { MetadataStore } from '../services/metadata-store';
import { validateNIP98Auth } from '../utils/nip98-auth';

export interface FileCheckRequest {
  sha256: string;
  size?: number;
  filename?: string;
}

export interface FileCheckResponse {
  exists: boolean;
  url?: string;
  fileId?: string;
  message: string;
}

/**
 * Handle GET /api/check/{sha256} - Check if file exists by SHA256
 */
export async function handleFileCheckBySha256(
  sha256: string,
  request: Request,
  env: Env
): Promise<Response> {
  try {
    console.log(`🔍 File check request for SHA256: ${sha256}`);

    // Validate SHA256 format
    if (!sha256 || !/^[a-fA-F0-9]{64}$/.test(sha256)) {
      return new Response(JSON.stringify({
        exists: false,
        message: 'Invalid SHA256 hash format'
      }), {
        status: 400,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      });
    }

    // Optional: Validate authentication (could be required for rate limiting)
    // For now, we'll allow anonymous checks to enable client-side deduplication
    
    if (!env.METADATA_CACHE) {
      console.error('METADATA_CACHE not available');
      return new Response(JSON.stringify({
        exists: false,
        message: 'Metadata cache not available'
      }), {
        status: 503,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      });
    }

    const metadataStore = new MetadataStore(env.METADATA_CACHE);
    const duplicateCheck = await metadataStore.checkDuplicateBySha256(sha256);

    if (duplicateCheck?.exists && duplicateCheck.url) {
      console.log(`✅ File exists: ${sha256} -> ${duplicateCheck.url}`);
      
      const response: FileCheckResponse = {
        exists: true,
        url: duplicateCheck.url,
        fileId: duplicateCheck.fileId,
        message: 'File already exists, upload not needed'
      };

      return new Response(JSON.stringify(response), {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Cache-Control': 'public, max-age=300' // 5 minute cache
        }
      });
    } else {
      console.log(`❌ File not found: ${sha256}`);
      
      const response: FileCheckResponse = {
        exists: false,
        message: 'File not found, upload required'
      };

      return new Response(JSON.stringify(response), {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Cache-Control': 'public, max-age=60' // 1 minute cache for "not found"
        }
      });
    }

  } catch (error) {
    console.error('File check error:', error);
    
    return new Response(JSON.stringify({
      exists: false,
      message: 'Internal server error during file check'
    }), {
      status: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      }
    });
  }
}

/**
 * Handle POST /api/check - Batch check multiple files by SHA256
 */
export async function handleBatchFileCheck(
  request: Request,
  env: Env
): Promise<Response> {
  try {
    console.log('🔍 Batch file check request');

    // Parse request body
    const body = await request.json() as { files: FileCheckRequest[] };
    
    if (!body.files || !Array.isArray(body.files)) {
      return new Response(JSON.stringify({
        error: 'Invalid request - files array required'
      }), {
        status: 400,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      });
    }

    // Limit batch size
    if (body.files.length > 50) {
      return new Response(JSON.stringify({
        error: 'Batch size limited to 50 files'
      }), {
        status: 400,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      });
    }

    // Validate SHA256 formats
    for (const file of body.files) {
      if (!file.sha256 || !/^[a-fA-F0-9]{64}$/.test(file.sha256)) {
        return new Response(JSON.stringify({
          error: `Invalid SHA256 format: ${file.sha256}`
        }), {
          status: 400,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
          }
        });
      }
    }

    if (!env.METADATA_CACHE) {
      return new Response(JSON.stringify({
        error: 'Metadata cache not available'
      }), {
        status: 503,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      });
    }

    const metadataStore = new MetadataStore(env.METADATA_CACHE);
    const results: (FileCheckResponse & { sha256: string })[] = [];

    // Check each file
    for (const file of body.files) {
      try {
        const duplicateCheck = await metadataStore.checkDuplicateBySha256(file.sha256);
        
        if (duplicateCheck?.exists && duplicateCheck.url) {
          results.push({
            sha256: file.sha256,
            exists: true,
            url: duplicateCheck.url,
            fileId: duplicateCheck.fileId,
            message: 'File already exists'
          });
        } else {
          results.push({
            sha256: file.sha256,
            exists: false,
            message: 'File not found'
          });
        }
      } catch (error) {
        console.error(`Error checking ${file.sha256}:`, error);
        results.push({
          sha256: file.sha256,
          exists: false,
          message: 'Error checking file'
        });
      }
    }

    const existingCount = results.filter(r => r.exists).length;
    console.log(`✅ Batch check complete: ${existingCount}/${results.length} files exist`);

    return new Response(JSON.stringify({
      results,
      summary: {
        total: results.length,
        existing: existingCount,
        missing: results.length - existingCount
      }
    }), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Cache-Control': 'public, max-age=300'
      }
    });

  } catch (error) {
    console.error('Batch file check error:', error);
    
    return new Response(JSON.stringify({
      error: 'Internal server error during batch file check'
    }), {
      status: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      }
    });
  }
}

/**
 * Handle OPTIONS requests for file check endpoints
 */
export async function handleFileCheckOptions(): Promise<Response> {
  return new Response(null, {
    status: 204,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Access-Control-Max-Age': '86400'
    }
  });
}
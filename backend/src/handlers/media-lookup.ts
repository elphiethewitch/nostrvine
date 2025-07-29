// ABOUTME: Media lookup API handler for checking if content already exists
// ABOUTME: Enables efficient re-runs of migrations by checking vine_id or filename before upload

import { validateNIP98Auth, createAuthErrorResponse } from '../utils/nip98-auth';
import { MetadataStore } from '../services/metadata-store';
import { isValidVineId } from '../utils/vine-id-extractor';

export interface MediaLookupResponse {
  exists: boolean;
  url?: string;
  file_id?: string;
  uploaded_at?: string;
  file_size?: number;
  content_type?: string;
}

export interface MediaLookupErrorResponse {
  error: string;
  message?: string;
}

/**
 * Handle GET /api/media/lookup requests
 * Checks if media exists by vine_id or filename
 * Requires NIP-98 authentication
 */
export async function handleMediaLookup(
  request: Request,
  env: Env,
  ctx: ExecutionContext
): Promise<Response> {
  try {
    console.log('🔍 Media lookup handler started');

    // Validate request method
    if (request.method !== 'GET') {
      return createErrorResponse('Only GET method allowed for media lookup', 405);
    }

    // Validate NIP-98 authentication
    const authResult = await validateNIP98Auth(request);
    if (!authResult.valid) {
      console.error('NIP-98 authentication failed:', authResult.error);
      return createAuthErrorResponse(
        authResult.error || 'Valid NIP-98 authentication required',
        authResult.errorCode
      );
    }

    console.log(`✅ Authenticated user: ${authResult.pubkey}`);

    // Parse query parameters
    const url = new URL(request.url);
    const vineId = url.searchParams.get('vine_id');
    const filename = url.searchParams.get('filename');

    // Validate parameters - at least one must be provided
    if (!vineId && !filename) {
      return createErrorResponse(
        'Must provide either vine_id or filename parameter',
        400
      );
    }

    // Validate vine_id format if provided
    if (vineId && !isValidVineId(vineId)) {
      return createErrorResponse(
        `Invalid vine_id format: ${vineId}. Must be 11 alphanumeric characters.`,
        400
      );
    }

    console.log(`🔍 Looking up media - vine_id: ${vineId}, filename: ${filename}`);

    const metadataStore = new MetadataStore(env.METADATA_CACHE);
    let mediaData: { fileId: string; uploadedAt: number } | null = null;

    // Try lookup by vine_id first (more specific)
    if (vineId) {
      console.log(`🔍 Searching by vine_id: ${vineId}`);
      const vineMapping = await metadataStore.getFileIdByVineId(vineId);
      if (vineMapping) {
        mediaData = {
          fileId: vineMapping.fileId,
          uploadedAt: vineMapping.uploadedAt
        };
        console.log(`✅ Found by vine_id: ${mediaData.fileId}`);
      }
    }

    // If not found by vine_id, try filename
    if (!mediaData && filename) {
      console.log(`🔍 Searching by filename: ${filename}`);
      const filenameMapping = await metadataStore.getFileIdByFilename(filename);
      if (filenameMapping) {
        mediaData = {
          fileId: filenameMapping.fileId,
          uploadedAt: filenameMapping.uploadedAt
        };
        console.log(`✅ Found by filename: ${mediaData.fileId}`);
      }
    }

    // If not found, return not exists
    if (!mediaData) {
      console.log('❌ Media not found');
      const response: MediaLookupResponse = { exists: false };
      return new Response(JSON.stringify(response), {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Cache-Control': 'public, max-age=300' // 5 minutes cache for not found
        }
      });
    }

    // Get additional file metadata from R2
    let fileSize: number | undefined;
    let contentType: string | undefined;

    try {
      const r2Metadata = await metadataStore.getFileMetadataFromR2(mediaData.fileId, env.MEDIA_BUCKET);
      if (r2Metadata) {
        fileSize = r2Metadata.size;
        contentType = r2Metadata.contentType;
      }
    } catch (error) {
      console.warn('Failed to get R2 metadata, continuing without size/type info:', error);
    }

    // Return found response
    const response: MediaLookupResponse = {
      exists: true,
      url: `https://api.openvine.co/media/${mediaData.fileId}`,
      file_id: mediaData.fileId,
      uploaded_at: new Date(mediaData.uploadedAt).toISOString(),
      file_size: fileSize,
      content_type: contentType
    };

    console.log(`✅ Media lookup successful: ${mediaData.fileId}`);

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Cache-Control': 'public, max-age=3600' // 1 hour cache for found files
      }
    });

  } catch (error) {
    console.error('Media lookup error:', error);
    return createErrorResponse(
      'Internal server error',
      500,
      error instanceof Error ? error.message : 'Unknown error'
    );
  }
}

/**
 * Handle OPTIONS requests for media lookup
 */
export function handleMediaLookupOptions(): Response {
  return new Response(null, {
    status: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Access-Control-Max-Age': '86400' // 24 hours
    }
  });
}

/**
 * Create standardized error response
 */
function createErrorResponse(
  message: string,
  status: number = 400,
  details?: string
): Response {
  const errorResponse: MediaLookupErrorResponse = {
    error: message,
    message: details
  };

  return new Response(JSON.stringify(errorResponse), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    }
  });
}
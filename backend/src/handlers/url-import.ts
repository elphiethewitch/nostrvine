// ABOUTME: URL-based video import handler that fetches videos from external URLs
// ABOUTME: Supports GCS and other HTTP sources with NIP-98 authentication

import { 
  NIP96UploadResponse, 
  NIP96ErrorResponse, 
  NIP96ErrorCode,
  FileMetadata
} from '../types/nip96';
import { 
  isSupportedContentType, 
  getMaxFileSize
} from './nip96-info';
import { 
  calculateSHA256
} from '../utils/nip94-generator';
import {
  validateNIP98Auth,
  extractUserPlan,
  createAuthErrorResponse
} from '../utils/nip98-auth';
import { MetadataStore } from '../services/metadata-store';
import { ThumbnailService } from '../services/ThumbnailService';

interface URLImportRequest {
  url: string;
  caption?: string;
  alt?: string;
  useCloudinary?: boolean; // Optional flag to use Cloudinary for processing
}

/**
 * Handle URL-based video import
 * Fetches video from URL and processes through existing pipeline
 */
export async function handleURLImport(
  request: Request, 
  env: Env,
  ctx: ExecutionContext
): Promise<Response> {
  try {
    console.log('🌐 URL import handler started');
    
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

    // Parse request body
    let importRequest: URLImportRequest;
    try {
      importRequest = await request.json();
    } catch (e) {
      return createErrorResponse(
        NIP96ErrorCode.SERVER_ERROR,
        'Invalid JSON in request body'
      );
    }

    if (!importRequest.url) {
      return createErrorResponse(
        NIP96ErrorCode.SERVER_ERROR,
        'URL parameter is required'
      );
    }

    // Validate URL
    let videoUrl: URL;
    try {
      videoUrl = new URL(importRequest.url);
      if (!['http:', 'https:'].includes(videoUrl.protocol)) {
        throw new Error('Only HTTP(S) URLs are supported');
      }
    } catch (e) {
      return createErrorResponse(
        NIP96ErrorCode.SERVER_ERROR,
        'Invalid URL provided'
      );
    }

    console.log(`📥 Fetching video from: ${videoUrl.href}`);

    // Fetch video from URL
    const fetchResponse = await fetch(videoUrl.href, {
      method: 'GET',
      headers: {
        'User-Agent': 'OpenVine/1.0 (Video Import Bot)'
      }
    });

    if (!fetchResponse.ok) {
      return createErrorResponse(
        NIP96ErrorCode.SERVER_ERROR,
        `Failed to fetch video: ${fetchResponse.status} ${fetchResponse.statusText}`
      );
    }

    // Get content type from response
    const contentType = fetchResponse.headers.get('content-type') || 'video/mp4';
    if (!isSupportedContentType(contentType)) {
      return createErrorResponse(
        NIP96ErrorCode.INVALID_FILE_TYPE,
        `Content type ${contentType} not supported`
      );
    }

    // Get content length
    const contentLength = fetchResponse.headers.get('content-length');
    const fileSize = contentLength ? parseInt(contentLength) : 0;

    // Extract user plan
    const userPlan = authResult.authEvent ? 
      extractUserPlan(authResult.authEvent) : 'free';

    // Validate file size if known
    if (fileSize > 0) {
      const maxSize = getMaxFileSize(userPlan);
      if (fileSize > maxSize) {
        return createErrorResponse(
          NIP96ErrorCode.FILE_TOO_LARGE,
          `File size ${fileSize} exceeds limit of ${maxSize} bytes`
        );
      }
    }

    // Download video data
    const fileData = await fetchResponse.arrayBuffer();
    
    // Validate actual size after download
    const actualSize = fileData.byteLength;
    const maxSize = getMaxFileSize(userPlan);
    if (actualSize > maxSize) {
      return createErrorResponse(
        NIP96ErrorCode.FILE_TOO_LARGE,
        `File size ${actualSize} exceeds limit of ${maxSize} bytes`
      );
    }

    // Calculate SHA256 hash
    const sha256Hash = await calculateSHA256(fileData);
    
    // Check for duplicates
    if (env.METADATA_CACHE) {
      const metadataStore = new MetadataStore(env.METADATA_CACHE);
      const duplicate = await metadataStore.checkDuplicateBySha256(sha256Hash);
      
      if (duplicate && duplicate.exists) {
        console.log(`🔁 Duplicate detected: ${duplicate.fileId}`);
        // Return existing file info
        const mediaUrl = `${new URL(request.url).origin}/media/${duplicate.fileId}`;
        
        return new Response(JSON.stringify({
          status: 'success',
          message: 'File already exists',
          processing_url: mediaUrl,
          download_url: mediaUrl,
          nip94_event: {
            kind: 1063,
            tags: [
              ['url', mediaUrl],
              ['x', sha256Hash],
              ['size', actualSize.toString()],
              ['m', contentType],
              ['dim', '1280x720'], // TODO: Get actual dimensions
              ['alt', importRequest.alt || `Video imported from ${videoUrl.hostname}`]
            ],
            content: importRequest.caption || ''
          }
        } as NIP96UploadResponse), {
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
          }
        });
      }
    }

    // Generate file ID
    const fileId = `${Date.now()}-${sha256Hash.substring(0, 8)}`;
    const filename = videoUrl.pathname.split('/').pop() || 'imported-video.mp4';

    console.log(`📁 Processing imported video: ${filename} (${actualSize} bytes)`);

    let mediaUrl: string;

    // Check if we should use Cloudinary for processing
    if (importRequest.useCloudinary && env.CLOUDINARY_API_KEY) {
      console.log('☁️ Using Cloudinary for video processing and moderation');
      
      // Upload to Cloudinary for processing, moderation, and thumbnail generation
      const cloudinaryResponse = await uploadToCloudinary(
        fileData,
        filename,
        contentType,
        authResult.pubkey,
        env
      );

      if (cloudinaryResponse.success) {
        // Store minimal metadata pointing to Cloudinary
        if (env.METADATA_CACHE) {
          const metadata: FileMetadata = {
            id: fileId,
            filename: filename,
            content_type: contentType,
            size: actualSize,
            sha256: sha256Hash,
            uploaded_at: Date.now(),
            uploader_pubkey: authResult.pubkey,
            url: cloudinaryResponse.url,
            dimensions: { width: cloudinaryResponse.width || 1280, height: cloudinaryResponse.height || 720 },
            original_url: videoUrl.href,
            cloudinary_public_id: cloudinaryResponse.public_id,
            processing_status: 'processing'
          };

          const metadataStore = new MetadataStore(env.METADATA_CACHE);
          await metadataStore.setMetadata(fileId, metadata);
          await metadataStore.setSha256Mapping(sha256Hash, fileId);
        }

        mediaUrl = cloudinaryResponse.url;
      } else {
        // Fallback to R2 if Cloudinary fails
        console.warn('Cloudinary upload failed, falling back to R2');
        mediaUrl = await storeInR2(fileData, fileId, filename, contentType, sha256Hash, videoUrl.href, authResult.pubkey, env, request);
      }
    } else {
      // Direct R2 storage
      mediaUrl = await storeInR2(fileData, fileId, filename, contentType, sha256Hash, videoUrl.href, authResult.pubkey, env, request);
    }

    // Trigger thumbnail generation in the background
    if (!importRequest.useCloudinary) {
      ctx.waitUntil(triggerThumbnailGeneration(fileId, request.url));
    }
    
    const response: NIP96UploadResponse = {
      status: 'success',
      message: 'Video imported successfully',
      processing_url: mediaUrl,
      download_url: mediaUrl,
      nip94_event: {
        kind: 1063,
        tags: [
          ['url', mediaUrl],
          ['x', sha256Hash],
          ['size', actualSize.toString()],
          ['m', contentType],
          ['dim', '1280x720'], // TODO: Get actual dimensions
          ['alt', importRequest.alt || `Video imported from ${videoUrl.hostname}`]
        ],
        content: importRequest.caption || ''
      }
    };

    return new Response(JSON.stringify(response), {
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      }
    });

  } catch (error) {
    console.error('URL import error:', error);
    return createErrorResponse(
      NIP96ErrorCode.SERVER_ERROR,
      error instanceof Error ? error.message : 'Internal server error'
    );
  }
}

/**
 * Handle OPTIONS request for URL import endpoint
 */
export function handleURLImportOptions(): Response {
  return new Response(null, {
    status: 204,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Access-Control-Max-Age': '86400'
    }
  });
}

/**
 * Create NIP-96 error response
 */
function createErrorResponse(
  code: NIP96ErrorCode,
  message: string,
  status: number = 400
): Response {
  const response: NIP96ErrorResponse = {
    status: 'error',
    message,
    code
  };

  return new Response(JSON.stringify(response), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    }
  });
}
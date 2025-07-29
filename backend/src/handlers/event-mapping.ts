// ABOUTME: Store mapping between Nostr event IDs and video file IDs
// ABOUTME: Enables thumbnail lookups using either event ID or file ID

import { logger } from '../utils/logger.js';

interface EventMappingRequest {
  eventId: string;
  fileId: string;
  videoUrl: string;
  thumbnailUrl?: string;
}

/**
 * Store mapping between Nostr event ID and video file ID
 * POST /api/event-mapping
 */
export async function handleEventMapping(request: Request, env: Env): Promise<Response> {
  try {
    // Parse request body
    const body = await request.json() as EventMappingRequest;
    
    // Validate required fields
    if (!body.eventId || !body.fileId || !body.videoUrl) {
      return new Response(JSON.stringify({
        error: 'Missing required fields: eventId, fileId, videoUrl'
      }), {
        status: 400,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      });
    }

    // Validate event ID format (64 char hex)
    if (!/^[a-f0-9]{64}$/i.test(body.eventId)) {
      return new Response(JSON.stringify({
        error: 'Invalid event ID format'
      }), {
        status: 400,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      });
    }

    logger.info(`Storing event mapping: ${body.eventId.substring(0, 8)}... -> ${body.fileId}`);

    // Store the mapping in KV
    const mapping = {
      fileId: body.fileId,
      videoUrl: body.videoUrl,
      thumbnailUrl: body.thumbnailUrl,
      createdAt: Date.now()
    };

    await env.METADATA_CACHE.put(
      `event:${body.eventId}`,
      JSON.stringify(mapping),
      {
        expirationTtl: 60 * 60 * 24 * 365 // 1 year
      }
    );

    // Also store reverse mapping for lookups
    await env.METADATA_CACHE.put(
      `file:${body.fileId}:event`,
      body.eventId,
      {
        expirationTtl: 60 * 60 * 24 * 365 // 1 year
      }
    );

    logger.info(`Event mapping stored successfully`);

    return new Response(JSON.stringify({
      success: true,
      eventId: body.eventId,
      fileId: body.fileId
    }), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      }
    });
  } catch (error) {
    logger.error('Error storing event mapping:', error);
    
    return new Response(JSON.stringify({
      error: 'Failed to store event mapping'
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
 * Handle OPTIONS for event mapping endpoint
 */
export function handleEventMappingOptions(): Response {
  return new Response(null, {
    status: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization'
    }
  });
}
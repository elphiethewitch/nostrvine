import { describe, it, expect, beforeEach } from 'vitest';
import { ThumbnailService } from '../services/ThumbnailService';

describe('ThumbnailService - Event ID Mapping', () => {
  let service: ThumbnailService;
  let mockEnv: any;

  beforeEach(() => {
    // Create mock environment with KV store
    mockEnv = {
      MEDIA_BUCKET: {
        get: async (key: string) => null,
        put: async () => {},
        delete: async () => {},
        list: async () => ({ keys: [] })
      },
      METADATA_CACHE: {
        get: async (key: string, type?: string) => {
          // Mock event ID to fileId mapping
          if (key === 'event:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855') {
            const data = {
              fileId: '1704067200-abc123',
              videoUrl: 'https://api.openvine.co/media/1704067200-abc123',
              createdAt: Date.now()
            };
            return type === 'json' ? data : JSON.stringify(data);
          }
          // Mock video metadata
          if (key === 'v1:video:1704067200-abc123') {
            const data = {
              videoId: '1704067200-abc123',
              stream: {
                uid: 'stream123',
                thumbnailUrl: 'https://stream.example.com/thumbnail.jpg'
              }
            };
            return type === 'json' ? data : JSON.stringify(data);
          }
          return null;
        },
        put: async () => {},
        delete: async () => {},
        list: async () => ({ keys: [] })
      }
    };

    service = new ThumbnailService(mockEnv);
  });

  it('should resolve Nostr event ID to fileId', async () => {
    const eventId = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
    
    // Mock fetch for Stream thumbnail
    global.fetch = async (url: string) => {
      if (url.includes('stream.example.com')) {
        return new Response(new ArrayBuffer(100), {
          ok: true,
          status: 200
        });
      }
      throw new Error('Unexpected fetch');
    };

    const response = await service.getThumbnail(eventId);
    
    expect(response.status).toBe(200);
    expect(response.headers.get('Content-Type')).toBe('image/jpg');
  });

  it('should handle direct fileId without mapping', async () => {
    const fileId = '1704067200-xyz789';
    
    const response = await service.getThumbnail(fileId);
    
    // Should return placeholder since video doesn't exist
    expect(response.status).toBe(200);
    expect(response.headers.get('Content-Type')).toBe('image/svg+xml');
  });

  it('should handle event ID with no mapping', async () => {
    const unmappedEventId = 'f3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
    
    const response = await service.getThumbnail(unmappedEventId);
    
    // Should continue with original ID and return placeholder
    expect(response.status).toBe(200);
    expect(response.headers.get('Content-Type')).toBe('image/svg+xml');
  });

  it('should validate event ID format', async () => {
    // Valid 64 char hex
    const validEventId = 'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789';
    const response1 = await service.getThumbnail(validEventId);
    expect(response1.status).toBe(200);

    // Not hex format - should be treated as fileId
    const notHexId = 'xyz12345-notvalid';
    const response2 = await service.getThumbnail(notHexId);
    expect(response2.status).toBe(200);

    // Wrong length - should be treated as fileId
    const wrongLengthId = 'abcdef';
    const response3 = await service.getThumbnail(wrongLengthId);
    expect(response3.status).toBe(200);
  });
});
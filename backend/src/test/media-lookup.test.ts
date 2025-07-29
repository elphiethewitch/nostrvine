// ABOUTME: Test suite for media lookup API endpoint functionality
// ABOUTME: Validates vine_id and filename lookup with proper NIP-98 authentication

import { describe, it, expect, vi } from 'vitest';
import { handleMediaLookup, handleMediaLookupOptions } from '../handlers/media-lookup';

// Mock the dependencies
vi.mock('../utils/nip98-auth', () => ({
  validateNIP98Auth: vi.fn(),
  createAuthErrorResponse: vi.fn()
}));

vi.mock('../services/metadata-store', () => ({
  MetadataStore: vi.fn()
}));

vi.mock('../utils/vine-id-extractor', () => ({
  isValidVineId: vi.fn()
}));

describe('Media Lookup API', () => {
  const mockEnv = {
    METADATA_CACHE: {} as KVNamespace,
    MEDIA_BUCKET: {} as R2Bucket
  } as Env;

  const mockCtx = {} as ExecutionContext;

  describe('handleMediaLookup', () => {
    it('should reject non-GET requests', async () => {
      const request = new Request('http://localhost/api/media/lookup', {
        method: 'POST'
      });

      const response = await handleMediaLookup(request, mockEnv, mockCtx);
      expect(response.status).toBe(405);
    });

    it('should require NIP-98 authentication', async () => {
      const { validateNIP98Auth, createAuthErrorResponse } = await import('../utils/nip98-auth');
      
      (validateNIP98Auth as any).mockResolvedValue({
        valid: false,
        error: 'Missing authorization'
      });

      (createAuthErrorResponse as any).mockReturnValue(
        new Response('Unauthorized', { status: 401 })
      );

      const request = new Request('http://localhost/api/media/lookup?vine_id=iBu3q1zHizZ');

      const response = await handleMediaLookup(request, mockEnv, mockCtx);
      expect(response.status).toBe(401);
    });

    it('should require either vine_id or filename parameter', async () => {
      const { validateNIP98Auth } = await import('../utils/nip98-auth');
      
      (validateNIP98Auth as any).mockResolvedValue({
        valid: true,
        pubkey: 'test-pubkey'
      });

      const request = new Request('http://localhost/api/media/lookup');

      const response = await handleMediaLookup(request, mockEnv, mockCtx);
      expect(response.status).toBe(400);
      
      const body = await response.json();
      expect(body.error).toContain('Must provide either vine_id or filename');
    });

    it('should validate vine_id format', async () => {
      const { validateNIP98Auth } = await import('../utils/nip98-auth');
      const { isValidVineId } = await import('../utils/vine-id-extractor');
      
      (validateNIP98Auth as any).mockResolvedValue({
        valid: true,
        pubkey: 'test-pubkey'
      });

      (isValidVineId as any).mockReturnValue(false);

      const request = new Request('http://localhost/api/media/lookup?vine_id=invalid');

      const response = await handleMediaLookup(request, mockEnv, mockCtx);
      expect(response.status).toBe(400);
      
      const body = await response.json();
      expect(body.error).toContain('Invalid vine_id format');
    });

    it('should return not found when media does not exist', async () => {
      const { validateNIP98Auth } = await import('../utils/nip98-auth');
      const { isValidVineId } = await import('../utils/vine-id-extractor');
      const { MetadataStore } = await import('../services/metadata-store');
      
      (validateNIP98Auth as any).mockResolvedValue({
        valid: true,
        pubkey: 'test-pubkey'
      });

      (isValidVineId as any).mockReturnValue(true);

      const mockMetadataStore = {
        getFileIdByVineId: vi.fn().mockResolvedValue(null),
        getFileIdByFilename: vi.fn().mockResolvedValue(null)
      };

      (MetadataStore as any).mockImplementation(() => mockMetadataStore);

      const request = new Request('http://localhost/api/media/lookup?vine_id=iBu3q1zHizZ');

      const response = await handleMediaLookup(request, mockEnv, mockCtx);
      expect(response.status).toBe(200);
      
      const body = await response.json();
      expect(body.exists).toBe(false);
    });

    it('should return found media when vine_id exists', async () => {
      const { validateNIP98Auth } = await import('../utils/nip98-auth');
      const { isValidVineId } = await import('../utils/vine-id-extractor');
      const { MetadataStore } = await import('../services/metadata-store');
      
      (validateNIP98Auth as any).mockResolvedValue({
        valid: true,
        pubkey: 'test-pubkey'
      });

      (isValidVineId as any).mockReturnValue(true);

      const mockMapping = {
        fileId: '1234567890-abcdef12',
        uploadedAt: Date.now()
      };

      const mockR2Metadata = {
        size: 1234567,
        contentType: 'video/mp4'
      };

      const mockMetadataStore = {
        getFileIdByVineId: vi.fn().mockResolvedValue(mockMapping),
        getFileIdByFilename: vi.fn(),
        getFileMetadataFromR2: vi.fn().mockResolvedValue(mockR2Metadata)
      };

      (MetadataStore as any).mockImplementation(() => mockMetadataStore);

      const request = new Request('http://localhost/api/media/lookup?vine_id=iBu3q1zHizZ');

      const response = await handleMediaLookup(request, mockEnv, mockCtx);
      expect(response.status).toBe(200);
      
      const body = await response.json();
      expect(body.exists).toBe(true);
      expect(body.file_id).toBe(mockMapping.fileId);
      expect(body.url).toBe(`https://api.openvine.co/media/${mockMapping.fileId}`);
      expect(body.file_size).toBe(mockR2Metadata.size);
      expect(body.content_type).toBe(mockR2Metadata.contentType);
    });

    it('should fallback to filename lookup when vine_id not found', async () => {
      const { validateNIP98Auth } = await import('../utils/nip98-auth');
      const { isValidVineId } = await import('../utils/vine-id-extractor');
      const { MetadataStore } = await import('../services/metadata-store');
      
      (validateNIP98Auth as any).mockResolvedValue({
        valid: true,
        pubkey: 'test-pubkey'
      });

      (isValidVineId as any).mockReturnValue(true);

      const mockMapping = {
        fileId: '1234567890-fedcba98',
        uploadedAt: Date.now()
      };

      const mockMetadataStore = {
        getFileIdByVineId: vi.fn().mockResolvedValue(null), // Not found by vine_id
        getFileIdByFilename: vi.fn().mockResolvedValue(mockMapping), // Found by filename
        getFileMetadataFromR2: vi.fn().mockResolvedValue({
          size: 2345678,
          contentType: 'video/webm'
        })
      };

      (MetadataStore as any).mockImplementation(() => mockMetadataStore);

      const request = new Request('http://localhost/api/media/lookup?vine_id=iBu3q1zHizZ&filename=iBu3q1zHizZ.webm');

      const response = await handleMediaLookup(request, mockEnv, mockCtx);
      expect(response.status).toBe(200);
      
      const body = await response.json();
      expect(body.exists).toBe(true);
      expect(body.file_id).toBe(mockMapping.fileId);
    });
  });

  describe('handleMediaLookupOptions', () => {
    it('should return proper CORS headers', () => {
      const response = handleMediaLookupOptions();
      
      expect(response.status).toBe(200);
      expect(response.headers.get('Access-Control-Allow-Origin')).toBe('*');
      expect(response.headers.get('Access-Control-Allow-Methods')).toBe('GET, OPTIONS');
      expect(response.headers.get('Access-Control-Allow-Headers')).toBe('Content-Type, Authorization');
    });
  });
});

describe('Vine ID Extractor', () => {
  describe('extractVineIdFromFilename', () => {
    it('should extract vine ID from simple filename', async () => {
      const { extractVineIdFromFilename } = await import('../utils/vine-id-extractor');
      
      expect(extractVineIdFromFilename('iBu3q1zHizZ.mp4')).toBe('iBu3q1zHizZ');
      expect(extractVineIdFromFilename('vine_iBu3q1zHizZ.webm')).toBe('iBu3q1zHizZ');
      expect(extractVineIdFromFilename('/path/to/aBcDeFgHiJk_extra.mp4')).toBe('aBcDeFgHiJk');
    });

    it('should return null for invalid filenames', async () => {
      const { extractVineIdFromFilename } = await import('../utils/vine-id-extractor');
      
      expect(extractVineIdFromFilename('')).toBe(null);
      expect(extractVineIdFromFilename('short.mp4')).toBe(null);
      expect(extractVineIdFromFilename('toolong123456.mp4')).toBe(null);
    });
  });

  describe('isValidVineId', () => {
    it('should validate proper vine IDs', async () => {
      const { isValidVineId } = await import('../utils/vine-id-extractor');
      
      expect(isValidVineId('iBu3q1zHizZ')).toBe(true);
      expect(isValidVineId('aBcDeFgHiJk')).toBe(true);
      expect(isValidVineId('0123456789A')).toBe(true);
    });

    it('should reject invalid vine IDs', async () => {
      const { isValidVineId } = await import('../utils/vine-id-extractor');
      
      expect(isValidVineId('')).toBe(false);
      expect(isValidVineId('short')).toBe(false);
      expect(isValidVineId('toolong12345')).toBe(false);
      expect(isValidVineId('invalid@char')).toBe(false);
      expect(isValidVineId(null as any)).toBe(false);
    });
  });
});
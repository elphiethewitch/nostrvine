// ABOUTME: Video metadata storage service using Cloudflare KV
// ABOUTME: Provides efficient video metadata management with batch operations and caching

export interface VideoRendition {
  url: string;
  size: number;
}

export interface VideoMetadata {
  videoId: string;
  duration: number;
  fileSize: number;
  renditions: {
    '480p': VideoRendition;
    '720p': VideoRendition;
  };
  poster: string;
  uploadTimestamp: number;
  originalEventId: string; // Nostr event ID
}

export interface VideoListResult {
  videos: VideoMetadata[];
  nextCursor?: string;
}

// In-memory cache for request lifecycle
const requestCache = new Map<string, VideoMetadata>();

export class MetadataStore {
  constructor(private kv: KVNamespace) {}

  /**
   * Get metadata for a single video
   */
  async getVideoMetadata(videoId: string): Promise<VideoMetadata | null> {
    // Check request cache first
    if (requestCache.has(videoId)) {
      return requestCache.get(videoId)!;
    }

    try {
      const key = `video:${videoId}`;
      const metadata = await this.kv.get<VideoMetadata>(key, 'json');
      
      if (metadata) {
        // Cache for request lifecycle
        requestCache.set(videoId, metadata);
      }
      
      return metadata;
    } catch (error) {
      console.error(`Failed to get metadata for video ${videoId}:`, error);
      return null;
    }
  }

  /**
   * Set metadata for a video
   */
  async setVideoMetadata(metadata: VideoMetadata): Promise<void> {
    try {
      const key = `video:${metadata.videoId}`;
      await this.kv.put(key, JSON.stringify(metadata), {
        expirationTtl: 60 * 60 * 24 * 30 // 30 days
      });
      
      // Update request cache
      requestCache.set(metadata.videoId, metadata);
      
      // Also maintain a list of recent videos
      await this.addToRecentVideos(metadata.videoId);
    } catch (error) {
      console.error(`Failed to set metadata for video ${metadata.videoId}:`, error);
      throw error;
    }
  }

  /**
   * Batch get metadata for multiple videos
   */
  async batchGetMetadata(videoIds: string[]): Promise<VideoMetadata[]> {
    const results: VideoMetadata[] = [];
    const uncachedIds: string[] = [];
    
    // Check request cache first
    for (const videoId of videoIds) {
      if (requestCache.has(videoId)) {
        results.push(requestCache.get(videoId)!);
      } else {
        uncachedIds.push(videoId);
      }
    }
    
    // Batch fetch uncached videos
    if (uncachedIds.length > 0) {
      const promises = uncachedIds.map(id => this.getVideoMetadata(id));
      const metadataResults = await Promise.all(promises);
      
      for (const metadata of metadataResults) {
        if (metadata) {
          results.push(metadata);
        }
      }
    }
    
    return results;
  }

  /**
   * List recent videos with cursor-based pagination
   */
  async listRecentVideos(limit: number = 20, cursor?: string): Promise<VideoListResult> {
    try {
      const recentKey = 'recent_videos';
      const recentList = await this.kv.get<string[]>(recentKey, 'json') || [];
      
      // Calculate start index from cursor
      let startIndex = 0;
      if (cursor) {
        startIndex = parseInt(cursor, 10) || 0;
      }
      
      // Get the requested page
      const pageIds = recentList.slice(startIndex, startIndex + limit);
      const videos = await this.batchGetMetadata(pageIds);
      
      // Calculate next cursor
      let nextCursor: string | undefined;
      if (startIndex + limit < recentList.length) {
        nextCursor = String(startIndex + limit);
      }
      
      return {
        videos,
        nextCursor
      };
    } catch (error) {
      console.error('Failed to list recent videos:', error);
      return { videos: [] };
    }
  }

  /**
   * Add video to recent videos list
   */
  private async addToRecentVideos(videoId: string): Promise<void> {
    try {
      const recentKey = 'recent_videos';
      const recentList = await this.kv.get<string[]>(recentKey, 'json') || [];
      
      // Remove if already exists and add to front
      const filtered = recentList.filter(id => id !== videoId);
      filtered.unshift(videoId);
      
      // Keep only last 1000 videos
      const trimmed = filtered.slice(0, 1000);
      
      await this.kv.put(recentKey, JSON.stringify(trimmed));
    } catch (error) {
      console.error('Failed to update recent videos list:', error);
    }
  }

  /**
   * Get file ID by SHA256 hash for deduplication
   */
  async getFileIdBySha256(sha256: string): Promise<string | null> {
    try {
      const key = `sha256:${sha256}`;
      const fileId = await this.kv.get(key, 'text');
      return fileId;
    } catch (error) {
      console.error(`Failed to get fileId for SHA256 ${sha256}:`, error);
      return null;
    }
  }

  /**
   * Set file ID by SHA256 hash for deduplication
   */
  async setFileIdBySha256(sha256: string, fileId: string): Promise<void> {
    try {
      const key = `sha256:${sha256}`;
      await this.kv.put(key, fileId, {
        expirationTtl: 60 * 60 * 24 * 365 // 1 year
      });
    } catch (error) {
      console.error(`Failed to set fileId for SHA256 ${sha256}:`, error);
      throw error;
    }
  }

  /**
   * Check if file exists and get its metadata by SHA256
   */
  async checkDuplicateBySha256(sha256: string): Promise<{ exists: boolean; fileId?: string; url?: string } | null> {
    try {
      const existingFileId = await this.getFileIdBySha256(sha256);
      if (!existingFileId) {
        return { exists: false };
      }

      // SHA256 mapping exists, so file should exist
      // Note: We don't check video metadata since uploads may not store it
      // The SHA256 mapping itself is the authoritative source
      return {
        exists: true,
        fileId: existingFileId,
        url: `https://api.openvine.co/media/${existingFileId}`
      };
    } catch (error) {
      console.error(`Failed to check duplicate for SHA256 ${sha256}:`, error);
      return null;
    }
  }

  /**
   * Store mapping from original Vine URL path to our fileId
   * @param vineUrlPath The original vine URL path like "r/videos_h264high/7DB4F985..."
   * @param fileId Our internal fileId
   */
  async setVineUrlMapping(vineUrlPath: string, fileId: string): Promise<void> {
    try {
      const key = `vine_url:${vineUrlPath}`;
      await this.kv.put(key, fileId, {
        expirationTtl: 60 * 60 * 24 * 365 // 1 year
      });
    } catch (error) {
      console.error(`Failed to set Vine URL mapping for ${vineUrlPath}:`, error);
      throw error;
    }
  }

  /**
   * Get fileId from original Vine URL path
   * @param vineUrlPath The original vine URL path like "r/videos_h264high/7DB4F985..."
   * @returns fileId if found, null otherwise
   */
  async getFileIdByVineUrl(vineUrlPath: string): Promise<string | null> {
    try {
      const key = `vine_url:${vineUrlPath}`;
      const fileId = await this.kv.get(key, 'text');
      return fileId;
    } catch (error) {
      console.error(`Failed to get fileId for Vine URL ${vineUrlPath}:`, error);
      return null;
    }
  }

  /**
   * Set vine ID to fileId mapping for lookup
   */
  async setVineIdMapping(vineId: string, fileId: string, originalFilename?: string): Promise<void> {
    try {
      const vineKey = `vine_id:${vineId}`;
      const mappingData = {
        fileId,
        originalFilename,
        uploadedAt: Date.now()
      };
      
      await this.kv.put(vineKey, JSON.stringify(mappingData), {
        expirationTtl: 60 * 60 * 24 * 365 // 1 year
      });
    } catch (error) {
      console.error(`Failed to set vine ID mapping for ${vineId}:`, error);
      throw error;
    }
  }

  /**
   * Get fileId from vine ID
   */
  async getFileIdByVineId(vineId: string): Promise<{ fileId: string; originalFilename?: string; uploadedAt: number } | null> {
    try {
      const vineKey = `vine_id:${vineId}`;
      const mappingData = await this.kv.get(vineKey, 'json');
      return mappingData as { fileId: string; originalFilename?: string; uploadedAt: number } | null;
    } catch (error) {
      console.error(`Failed to get fileId for vine ID ${vineId}:`, error);
      return null;
    }
  }

  /**
   * Set filename to fileId mapping for lookup
   */
  async setFilenameMapping(originalFilename: string, fileId: string, vineId?: string): Promise<void> {
    try {
      const filenameKey = `filename:${originalFilename}`;
      const mappingData = {
        fileId,
        vineId,
        uploadedAt: Date.now()
      };
      
      await this.kv.put(filenameKey, JSON.stringify(mappingData), {
        expirationTtl: 60 * 60 * 24 * 365 // 1 year
      });
    } catch (error) {
      console.error(`Failed to set filename mapping for ${originalFilename}:`, error);
      throw error;
    }
  }

  /**
   * Get fileId from original filename
   */
  async getFileIdByFilename(originalFilename: string): Promise<{ fileId: string; vineId?: string; uploadedAt: number } | null> {
    try {
      const filenameKey = `filename:${originalFilename}`;
      const mappingData = await this.kv.get(filenameKey, 'json');
      return mappingData as { fileId: string; vineId?: string; uploadedAt: number } | null;
    } catch (error) {
      console.error(`Failed to get fileId for filename ${originalFilename}:`, error);
      return null;
    }
  }

  /**
   * Get file metadata from R2 (for size and content type info)
   */
  async getFileMetadataFromR2(fileId: string, mediaBucket: R2Bucket): Promise<{ size: number; contentType: string } | null> {
    try {
      const objectKey = `uploads/${fileId}.mp4`; // Most uploads are MP4
      const object = await mediaBucket.head(objectKey);
      
      if (!object) {
        // Try without .mp4 extension
        const altKey = `uploads/${fileId}`;
        const altObject = await mediaBucket.head(altKey);
        if (!altObject) return null;
        
        return {
          size: altObject.size,
          contentType: altObject.httpMetadata?.contentType || 'application/octet-stream'
        };
      }
      
      return {
        size: object.size,
        contentType: object.httpMetadata?.contentType || 'video/mp4'
      };
    } catch (error) {
      console.error(`Failed to get R2 metadata for fileId ${fileId}:`, error);
      return null;
    }
  }

  /**
   * Clear request cache (call at end of request)
   */
  static clearRequestCache(): void {
    requestCache.clear();
  }
}
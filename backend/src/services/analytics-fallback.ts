// ABOUTME: Fallback analytics service using KV for immediate results
// ABOUTME: Complements Analytics Engine with real-time queryable data

export interface VideoViewRecord {
  videoId: string;
  userId?: string;
  creatorPubkey?: string;
  source: string;
  eventType: string;
  timestamp: number;
  watchDuration?: number;
  totalDuration?: number;
  loopCount?: number;
  completionRate?: number;
  hashtags?: string[];
  title?: string;
}

export interface VideoStats {
  videoId: string;
  views: number;
  uniqueViewers: Set<string>;
  totalWatchTime: number;
  totalLoops: number;
  lastView: number;
  title?: string;
  creatorPubkey?: string;
  hashtags?: string[];
}

export class AnalyticsFallbackService {
  constructor(
    private env: Env,
    private ctx: ExecutionContext
  ) {}

  /**
   * Track video view and store in KV for immediate querying
   */
  async trackVideoView(event: VideoViewRecord): Promise<void> {
    const now = Date.now();
    const today = new Date().toISOString().split('T')[0];
    
    // Store individual view record for detailed analytics
    const viewKey = `view:${event.videoId}:${now}:${Math.random().toString(36).substring(7)}`;
    
    try {
      // Store the view record with 7 day TTL
      await this.env.METADATA_CACHE.put(viewKey, JSON.stringify(event), {
        expirationTtl: 7 * 24 * 60 * 60 // 7 days
      });

      // Update video stats aggregation
      await this.updateVideoStats(event);
      
      // Update daily stats
      await this.updateDailyStats(today, event);
      
      console.log(`📊 Fallback analytics: Tracked ${event.eventType} for video ${event.videoId.substring(0, 8)}...`);
    } catch (error) {
      console.error('Failed to store fallback analytics:', error);
    }
  }

  /**
   * Update aggregated video statistics
   */
  private async updateVideoStats(event: VideoViewRecord): Promise<void> {
    const statsKey = `stats:video:${event.videoId}`;
    
    try {
      // Get existing stats
      const existingData = await this.env.METADATA_CACHE.get(statsKey);
      let stats: VideoStats;
      
      if (existingData) {
        const parsed = JSON.parse(existingData);
        stats = {
          ...parsed,
          uniqueViewers: new Set(parsed.uniqueViewers || [])
        };
      } else {
        stats = {
          videoId: event.videoId,
          views: 0,
          uniqueViewers: new Set(),
          totalWatchTime: 0,
          totalLoops: 0,
          lastView: 0,
          title: event.title,
          creatorPubkey: event.creatorPubkey,
          hashtags: event.hashtags
        };
      }

      // Update stats
      if (event.eventType === 'view_start' || event.eventType === 'view') {
        stats.views += 1;
        if (event.userId) {
          stats.uniqueViewers.add(event.userId);
        }
      }
      
      if (event.watchDuration) {
        stats.totalWatchTime += event.watchDuration;
      }
      
      if (event.loopCount) {
        stats.totalLoops += event.loopCount;
      }
      
      stats.lastView = event.timestamp;

      // Store updated stats with 30 day TTL
      const serializable = {
        ...stats,
        uniqueViewers: Array.from(stats.uniqueViewers)
      };
      
      await this.env.METADATA_CACHE.put(statsKey, JSON.stringify(serializable), {
        expirationTtl: 30 * 24 * 60 * 60 // 30 days
      });
    } catch (error) {
      console.error('Failed to update video stats:', error);
    }
  }

  /**
   * Update daily aggregated statistics
   */
  private async updateDailyStats(date: string, event: VideoViewRecord): Promise<void> {
    const dailyKey = `stats:daily:${date}`;
    
    try {
      const existingData = await this.env.METADATA_CACHE.get(dailyKey);
      let dailyStats = existingData ? JSON.parse(existingData) : {
        date,
        totalEvents: 0,
        totalVideos: new Set(),
        totalUsers: new Set(),
        totalWatchTime: 0
      };

      // Update daily stats
      dailyStats.totalEvents += 1;
      dailyStats.totalVideos = new Set([...dailyStats.totalVideos, event.videoId]);
      if (event.userId) {
        dailyStats.totalUsers = new Set([...dailyStats.totalUsers, event.userId]);
      }
      if (event.watchDuration) {
        dailyStats.totalWatchTime += event.watchDuration;
      }

      // Store with sets converted to arrays
      const serializable = {
        ...dailyStats,
        totalVideos: Array.from(dailyStats.totalVideos),
        totalUsers: Array.from(dailyStats.totalUsers)
      };

      await this.env.METADATA_CACHE.put(dailyKey, JSON.stringify(serializable), {
        expirationTtl: 30 * 24 * 60 * 60 // 30 days
      });
    } catch (error) {
      console.error('Failed to update daily stats:', error);
    }
  }

  /**
   * Get popular videos from KV fallback data
   */
  async getPopularVideos(limit: number = 10): Promise<any[]> {
    try {
      // List all video stats keys
      const listResult = await this.env.METADATA_CACHE.list({ prefix: 'stats:video:' });
      
      const videoStats: any[] = [];
      
      // Fetch each video's stats
      for (const key of listResult.keys) {
        try {
          const data = await this.env.METADATA_CACHE.get(key.name);
          if (data) {
            const stats = JSON.parse(data);
            videoStats.push({
              videoId: stats.videoId,
              views: stats.views || 0,
              uniqueViewers: stats.uniqueViewers?.length || 0,
              avgWatchTime: stats.totalWatchTime / Math.max(stats.views, 1),
              totalLoops: stats.totalLoops || 0,
              lastView: stats.lastView,
              title: stats.title,
              creatorPubkey: stats.creatorPubkey
            });
          }
        } catch (error) {
          console.error(`Failed to parse stats for ${key.name}:`, error);
        }
      }
      
      // Sort by views and return top results
      return videoStats
        .sort((a, b) => b.views - a.views)
        .slice(0, limit);
        
    } catch (error) {
      console.error('Failed to get popular videos from fallback:', error);
      return [];
    }
  }

  /**
   * Get real-time metrics from fallback data
   */
  async getRealtimeMetrics(): Promise<any> {
    try {
      const today = new Date().toISOString().split('T')[0];
      const dailyData = await this.env.METADATA_CACHE.get(`stats:daily:${today}`);
      
      if (!dailyData) {
        return {
          totalEvents: 0,
          activeVideos: 0,
          activeUsers: 0,
          averageWatchTime: 0
        };
      }
      
      const stats = JSON.parse(dailyData);
      
      return {
        totalEvents: stats.totalEvents || 0,
        activeVideos: stats.totalVideos?.length || 0,
        activeUsers: stats.totalUsers?.length || 0,
        averageWatchTime: stats.totalWatchTime / Math.max(stats.totalEvents, 1)
      };
    } catch (error) {
      console.error('Failed to get realtime metrics from fallback:', error);
      return {
        totalEvents: 0,
        activeVideos: 0,
        activeUsers: 0,
        averageWatchTime: 0
      };
    }
  }
}
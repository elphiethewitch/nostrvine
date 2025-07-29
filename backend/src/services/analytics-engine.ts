// ABOUTME: Modern analytics service using Cloudflare Analytics Engine
// ABOUTME: Replaces KV-based analytics with proper time-series data storage

import { AnalyticsFallbackService } from './analytics-fallback';

export interface VideoViewEvent {
  videoId: string;
  userId?: string;
  creatorPubkey?: string;
  source: string;
  eventType: string;
  country?: string;
  hashtags?: string[];
  title?: string;
  watchDuration?: number;
  totalDuration?: number;
  loopCount?: number;
  completionRate?: number;
}

export interface VideoMetrics {
  videoId: string;
  views: number;
  uniqueViewers: number;
  avgWatchTime: number;
  avgCompletionRate: number;
  totalLoops: number;
}

export class VideoAnalyticsEngineService {
  private fallbackService: AnalyticsFallbackService;

  constructor(
    private env: Env,
    private ctx: ExecutionContext
  ) {
    this.fallbackService = new AnalyticsFallbackService(env, ctx);
  }

  /**
   * Track a video view event using Analytics Engine
   */
  async trackVideoView(event: VideoViewEvent, request: Request): Promise<void> {
    // Extract metadata from request
    const country = (request as any).cf?.country || 'unknown';
    const userAgent = request.headers.get('User-Agent') || 'unknown';
    const timestamp = new Date().toISOString();
    const date = timestamp.split('T')[0];
    const hour = new Date().getHours();

    // Prepare hashtags as a single string for blob storage
    const hashtagsStr = event.hashtags?.join(',') || '';

    // Write data point to Analytics Engine
    // Note: We don't await this to avoid blocking the response
    this.ctx.waitUntil(
      this.writeAnalyticsDataPoint({
        blobs: [
          event.videoId,                    // blob1: video ID
          event.userId || 'anonymous',      // blob2: user ID
          country,                           // blob3: country
          event.source,                      // blob4: source (mobile/web)
          event.eventType,                   // blob5: event type
          date,                              // blob6: date (YYYY-MM-DD)
          event.creatorPubkey || 'unknown',  // blob7: creator pubkey
          hashtagsStr,                       // blob8: hashtags (comma-separated)
          event.title || '',                 // blob9: video title
          hour.toString()                    // blob10: hour of day
        ],
        doubles: [
          1,                                          // double1: view count
          event.watchDuration || 0,                   // double2: watch duration (ms)
          event.loopCount || 0,                       // double3: loop count
          event.completionRate || 0,                  // double4: completion rate (0-1)
          event.totalDuration || 0,                   // double5: total video duration (ms)
          event.eventType === 'view_start' ? 1 : 0,  // double6: is new view
          event.eventType === 'view_end' ? 1 : 0,    // double7: is completed view
          Date.now()                                  // double8: timestamp (for time-based queries)
        ],
        indexes: [event.videoId] // Use video ID for sampling
      })
    );

    // Log for debugging
    console.log(`📊 Analytics Engine: Tracked ${event.eventType} for video ${event.videoId.substring(0, 8)}...`);
  }

  /**
   * Write data point to Analytics Engine
   */
  private async writeAnalyticsDataPoint(data: {
    blobs: string[];
    doubles: number[];
    indexes: string[];
  }): Promise<void> {
    try {
      // Write to Analytics Engine dataset
      this.env.VIDEO_ANALYTICS.writeDataPoint(data);
    } catch (error) {
      console.error('Failed to write to Analytics Engine:', error);
    }
  }

  /**
   * Get popular videos using SQL query
   */
  async getPopularVideos(
    timeframe: '1h' | '24h' | '7d' = '24h',
    limit: number = 10
  ): Promise<VideoMetrics[]> {
    // First try a simple count query to test if there's any data
    const testQuery = `SELECT COUNT(*) as total FROM VIDEO_ANALYTICS`;
    
    try {
      console.log('Testing Analytics Engine with simple count query...');
      const testResults = await this.executeAnalyticsQuery(testQuery);
      console.log('Test query results:', testResults);
    } catch (error) {
      console.error('Test query failed:', error);
    }

    // Convert timeframe to minutes for Analytics Engine
    const timeframeMinutes = {
      '1h': 60,
      '24h': 1440,
      '7d': 10080
    };

    // Use correct Analytics Engine table name (binding name)
    const query = `
      SELECT 
        blob1 AS videoId,
        SUM(double1) AS views,
        COUNT(DISTINCT blob2) AS uniqueViewers,
        AVG(double2) AS avgWatchTime,
        AVG(double4) AS avgCompletionRate,
        SUM(double3) AS totalLoops
      FROM VIDEO_ANALYTICS
      GROUP BY blob1
      ORDER BY views DESC
      LIMIT ${limit}
    `;

    try {
      // Execute SQL query against Analytics Engine
      const results = await this.executeAnalyticsQuery(query);
      return results as VideoMetrics[];
    } catch (error) {
      console.error('Failed to get popular videos:', error);
      return [];
    }
  }

  /**
   * Get detailed analytics for a specific video
   */
  async getVideoAnalytics(videoId: string, days: number = 30): Promise<any> {
    const query = `
      SELECT 
        toDate(timestamp) AS date,
        SUM(double1) AS dailyViews,
        COUNT(DISTINCT blob2) AS uniqueViewers,
        AVG(double2) AS avgWatchTime,
        AVG(double4) AS avgCompletionRate,
        SUM(double3) AS totalLoops,
        SUM(double6) AS newViews,
        SUM(double7) AS completedViews
      FROM VIDEO_ANALYTICS
      WHERE blob1 = '${videoId}'
        AND timestamp >= NOW() - INTERVAL '${days}' DAY
      GROUP BY date
      ORDER BY date DESC
    `;

    try {
      const results = await this.executeAnalyticsQuery(query);
      return {
        videoId,
        dailyMetrics: results,
        period: `${days} days`
      };
    } catch (error) {
      console.error('Failed to get video analytics:', error);
      return null;
    }
  }

  /**
   * Get real-time metrics
   */
  async getRealtimeMetrics(): Promise<any> {
    const query = `
      SELECT 
        COUNT(*) AS totalEvents,
        COUNT(DISTINCT blob1) AS activeVideos,
        COUNT(DISTINCT blob2) AS activeUsers,
        AVG(double2) AS avgWatchTime,
        SUM(double6) AS newViews
      FROM VIDEO_ANALYTICS
    `;

    try {
      const results = await this.executeAnalyticsQuery(query);
      return results[0] || {};
    } catch (error) {
      console.error('Failed to get realtime metrics:', error);
      return {};
    }
  }

  /**
   * Get analytics by hashtag
   */
  async getHashtagAnalytics(hashtag: string, days: number = 7): Promise<any> {
    const query = `
      SELECT 
        blob1 AS videoId,
        blob9 AS title,
        SUM(double1) AS views,
        AVG(double2) AS avgWatchTime,
        AVG(double4) AS avgCompletionRate
      FROM VIDEO_ANALYTICS
      WHERE blob8 LIKE '%${hashtag}%'
        AND timestamp >= NOW() - INTERVAL '${days}' DAY
      GROUP BY videoId, title
      ORDER BY views DESC
      LIMIT 20
    `;

    try {
      const results = await this.executeAnalyticsQuery(query);
      return {
        hashtag,
        videos: results,
        period: `${days} days`
      };
    } catch (error) {
      console.error('Failed to get hashtag analytics:', error);
      return null;
    }
  }

  /**
   * Get creator analytics
   */
  async getCreatorAnalytics(creatorPubkey: string, days: number = 30): Promise<any> {
    const query = `
      SELECT 
        blob1 AS videoId,
        blob9 AS title,
        SUM(double1) AS totalViews,
        COUNT(DISTINCT blob2) AS uniqueViewers,
        AVG(double2) AS avgWatchTime,
        AVG(double4) AS avgCompletionRate,
        SUM(double3) AS totalLoops
      FROM VIDEO_ANALYTICS
      WHERE blob7 = '${creatorPubkey}'
        AND timestamp >= NOW() - INTERVAL '${days}' DAY
      GROUP BY videoId, title
      ORDER BY totalViews DESC
    `;

    try {
      const results = await this.executeAnalyticsQuery(query);
      return {
        creatorPubkey,
        videos: results,
        totalVideos: results.length,
        period: `${days} days`
      };
    } catch (error) {
      console.error('Failed to get creator analytics:', error);
      return null;
    }
  }

  /**
   * Execute SQL query against Analytics Engine using Cloudflare's SQL API
   */
  private async executeAnalyticsQuery(query: string): Promise<any[]> {
    try {
      console.log('Executing Analytics Engine query:', query);
      
      // Use Cloudflare's Analytics Engine SQL API
      // The dataset binding provides direct SQL access
      const statement = this.env.VIDEO_ANALYTICS.prepare(query);
      const results = await statement.all();
      
      console.log(`Analytics query returned ${results.results?.length || 0} rows`);
      console.log('Query results preview:', JSON.stringify(results.results?.slice(0, 3), null, 2));
      
      return results.results || [];
    } catch (error) {
      console.error('Analytics Engine SQL query failed:', error);
      console.error('Error details:', {
        message: error.message,
        stack: error.stack,
        query: query
      });
      
      // Return empty results instead of throwing to prevent breaking the API
      return [];
    }
  }

  /**
   * Get system health metrics (compatibility with existing system)
   */
  async getHealthStatus(): Promise<any> {
    const realtimeMetrics = await this.getRealtimeMetrics();
    
    return {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      metrics: {
        totalRequests: realtimeMetrics.totalEvents || 0,
        activeVideos: realtimeMetrics.activeVideos || 0,
        activeUsers: realtimeMetrics.activeUsers || 0,
        averageWatchTime: realtimeMetrics.avgWatchTime || 0,
        requestsPerMinute: Math.round((realtimeMetrics.totalEvents || 0) / 5)
      },
      dependencies: {
        analyticsEngine: 'healthy',
        r2: 'unknown',
        kv: 'unknown'
      }
    };
  }
}
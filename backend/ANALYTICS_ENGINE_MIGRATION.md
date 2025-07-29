# Analytics Engine Migration Guide

## Overview

We've migrated from KV-based analytics storage to Cloudflare Analytics Engine, which provides:
- Unlimited cardinality analytics at scale
- Proper time-series data storage without TTL management
- SQL-based querying capabilities
- Automatic data retention and sampling
- No storage cost concerns

## What Changed

### 1. Storage Backend
- **Before**: Cloudflare KV with 24-hour TTLs (data was being lost!)
- **After**: Cloudflare Analytics Engine with automatic retention

### 2. Data Model
Analytics Engine uses a structured format:
```javascript
{
  blobs: [
    videoId,         // blob1
    userId,          // blob2
    country,         // blob3
    source,          // blob4
    eventType,       // blob5
    date,            // blob6
    creatorPubkey,   // blob7
    hashtags,        // blob8
    title,           // blob9
    hour             // blob10
  ],
  doubles: [
    1,               // double1: view count
    watchDuration,   // double2: watch duration (ms)
    loopCount,       // double3: loop count
    completionRate,  // double4: completion rate (0-1)
    totalDuration,   // double5: total duration (ms)
    isNewView,       // double6: 1 for view_start
    isCompleted,     // double7: 1 for view_end
    timestamp        // double8: unix timestamp
  ],
  indexes: [videoId] // for sampling
}
```

### 3. New Analytics Endpoints

#### Track Video View (Enhanced)
```bash
POST /analytics/view
{
  "eventId": "video-id",
  "source": "mobile",
  "eventType": "view_start", // or view_end, loop, pause, resume, skip
  "creatorPubkey": "creator-npub",
  "hashtags": ["funny", "cats"],
  "title": "Video Title",
  "watchDuration": 15000,    // milliseconds watched
  "totalDuration": 30000,    // total video duration
  "loopCount": 2,
  "completedVideo": true
}
```

#### Get Popular Videos
```bash
GET /api/analytics/popular?window=24h&limit=10
# window: 1h, 24h, 7d
```

#### Get Video Analytics
```bash
GET /api/analytics/video/{videoId}?days=30
# Returns daily metrics for specific video
```

#### Get Hashtag Analytics
```bash
GET /api/analytics/hashtag?hashtag=funny&days=7
# Returns videos and metrics for hashtag
```

#### Get Creator Analytics
```bash
GET /api/analytics/creator?pubkey={npub}&days=30
# Returns all videos and metrics for creator
```

#### Get Real-time Dashboard
```bash
GET /api/analytics/dashboard
# Returns real-time metrics and popular videos
```

## Implementation Status

### ✅ Completed
- Added Analytics Engine dataset binding to wrangler.jsonc
- Created new VideoAnalyticsEngineService
- Migrated all endpoints to use Analytics Engine
- Enhanced mobile tracking with detailed metrics
- Added new analytics query endpoints

### ⏳ Pending
- SQL API implementation (waiting for Cloudflare to enable)
- Historical data migration from KV (if any exists)
- Dashboard UI to visualize analytics

## Benefits

1. **No Data Loss**: Analytics are stored permanently with intelligent retention
2. **Better Insights**: Track watch time, completion rates, loops, etc.
3. **Scalable**: Handles millions of events without performance impact
4. **Cost Effective**: Currently free, paid tier is very affordable
5. **SQL Queries**: Powerful analytics without custom aggregation code

## Mobile App Integration

The mobile app can now send enhanced analytics:

```dart
// Basic view tracking (existing)
analyticsService.trackVideoView(video);

// Enhanced tracking (new)
analyticsService.trackDetailedVideoView(
  video,
  source: 'mobile',
  eventType: 'view_end',
  watchDuration: Duration(seconds: 28),
  totalDuration: Duration(seconds: 30),
  loopCount: 3,
  completedVideo: true,
);
```

## Notes

- The old KV-based analytics service is still available but deprecated
- Analytics Engine is currently not billing (free to use)
- SQL API queries will be enabled once Cloudflare provides access
- Consider implementing a data export feature before old KV data expires
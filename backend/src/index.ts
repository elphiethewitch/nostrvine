/**
 * NostrVine Backend - Cloudflare Workers
 * 
 * NIP-96 compliant file storage server with Cloudflare Stream integration
 * Supports vine-style video uploads, GIF conversion, and Nostr metadata broadcasting
 */

import { handleNIP96Info } from './handlers/nip96-info';
import { handleNIP96Upload, handleUploadOptions, handleJobStatus, handleMediaServing, handleReleaseDownload, handleVineUrlCompat } from './handlers/nip96-upload';
import { handleCloudinarySignedUpload, handleCloudinaryUploadOptions } from './handlers/cloudinary-upload';
import { handleCloudinaryWebhook, handleCloudinaryWebhookOptions } from './handlers/cloudinary-webhook';
import { handleVideoMetadata, handleVideoList, handleVideoMetadataOptions } from './handlers/video-metadata';

// New Cloudflare Stream handlers
import { handleStreamUploadRequest, handleStreamUploadOptions } from './handlers/stream-upload';
import { handleStreamWebhook, handleStreamWebhookOptions } from './handlers/stream-webhook';
import { handleVideoStatus, handleVideoStatusOptions } from './handlers/stream-status';

// Video caching API
import { handleVideoMetadata as handleVideoCacheMetadata, handleVideoMetadataOptions as handleVideoCacheOptions } from './handlers/video-cache-api';
import { handleBatchVideoLookup, handleBatchVideoOptions } from './handlers/batch-video-api';

// Analytics service
import { VideoAnalyticsService } from './services/analytics';
import { VideoAnalyticsEngineService } from './services/analytics-engine';

// Thumbnail service
import { ThumbnailService } from './services/ThumbnailService';

// URL import handler
import { handleURLImport, handleURLImportOptions } from './handlers/url-import';

// Feature flags
import {
  handleListFeatureFlags,
  handleGetFeatureFlag,
  handleCheckFeatureFlag,
  handleUpdateFeatureFlag,
  handleGradualRollout,
  handleRolloutHealth,
  handleRollback,
  handleFeatureFlagsOptions
} from './handlers/feature-flags-api';

// Moderation API
import { 
  handleReportSubmission, 
  handleModerationStatus, 
  handleModerationQueue, 
  handleModerationAction, 
  handleModerationOptions 
} from './handlers/moderation-api';

// NIP-05 Verification
import {
  handleNIP05Verification,
  handleNIP05Registration,
  handleNIP05Options
} from './handlers/nip05-verification';

// Cleanup script
import { handleCleanupRequest } from './scripts/cleanup-duplicates';

// Admin cleanup handler
import { handleAdminCleanup, handleAdminCleanupOptions } from './handlers/admin-cleanup';
import { handleAdminCleanupSimple, handleAdminCleanupSimpleOptions } from './handlers/admin-cleanup-simple';

// File check API
import { handleFileCheckBySha256, handleBatchFileCheck, handleFileCheckOptions } from './handlers/file-check';

// Event mapping API
import { handleEventMapping, handleEventMappingOptions } from './handlers/event-mapping';

// Media lookup API
import { handleMediaLookup, handleMediaLookupOptions } from './handlers/media-lookup';

// Export Durable Object
export { UploadJobManager } from './services/upload-job-manager';

export default {
	async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
		const url = new URL(request.url);
		const pathname = url.pathname;
		const method = request.method;
		
		// Request logging
		const startTime = Date.now();
		console.log(`🔍 ${method} ${pathname} from ${request.headers.get('origin') || 'unknown'}`);

		// Note: CORS preflight handling moved to individual endpoint handlers for proper functionality

		// Helper to wrap response with timing
		const wrapResponse = async (responsePromise: Promise<Response>): Promise<Response> => {
			const response = await responsePromise;
			const duration = Date.now() - startTime;
			console.log(`✅ ${method} ${pathname} - ${response.status} (${duration}ms)`);
			return response;
		};

		// Route handling
		try {
			// NIP-96 server information endpoint
			if (pathname === '/.well-known/nostr/nip96.json' && method === 'GET') {
				return wrapResponse(handleNIP96Info(request, env));
			}

			// NIP-05 verification endpoint
			if (pathname === '/.well-known/nostr.json' && method === 'GET') {
				return wrapResponse(handleNIP05Verification(request, env));
			}

			// NIP-05 registration endpoint
			if (pathname === '/api/nip05/register' && method === 'POST') {
				return wrapResponse(handleNIP05Registration(request, env));
			}

			if ((pathname === '/.well-known/nostr.json' || pathname === '/api/nip05/register') && method === 'OPTIONS') {
				return wrapResponse(Promise.resolve(handleNIP05Options()));
			}

			// Cloudflare Stream upload request endpoint (CDN implementation)
			if (pathname === '/v1/media/request-upload') {
				if (method === 'POST') {
					return handleStreamUploadRequest(request, env);
				}
				if (method === 'OPTIONS') {
					return handleStreamUploadOptions();
				}
			}

			// Cloudflare Stream webhook endpoint (CDN implementation)
			if (pathname === '/v1/webhooks/stream-complete') {
				if (method === 'POST') {
					return handleStreamWebhook(request, env, ctx);
				}
				if (method === 'OPTIONS') {
					return handleStreamWebhookOptions();
				}
			}

			// Video status polling endpoint
			if (pathname.startsWith('/v1/media/status/') && method === 'GET') {
				const videoId = pathname.split('/v1/media/status/')[1];
				return handleVideoStatus(videoId, request, env);
			}

			if (pathname.startsWith('/v1/media/status/') && method === 'OPTIONS') {
				return handleVideoStatusOptions();
			}

			// Ready events endpoint (for VideoEventPublisher)
			if (pathname === '/v1/media/ready-events' && method === 'GET') {
				// For now, return empty list - this endpoint would poll for processed videos
				// In a full implementation, this would check for videos ready to publish to Nostr
				return new Response(JSON.stringify({
					events: [],
					timestamp: new Date().toISOString()
				}), {
					headers: {
						'Content-Type': 'application/json',
						'Access-Control-Allow-Origin': '*'
					}
				});
			}

			if (pathname === '/v1/media/ready-events' && method === 'OPTIONS') {
				return new Response(null, {
					status: 200,
					headers: {
						'Access-Control-Allow-Origin': '*',
						'Access-Control-Allow-Methods': 'GET, OPTIONS',
						'Access-Control-Allow-Headers': 'Content-Type, Authorization'
					}
				});
			}

			// Video caching API endpoint
			if (pathname.startsWith('/api/video/') && method === 'GET') {
				const videoId = pathname.split('/api/video/')[1];
				return wrapResponse(handleVideoCacheMetadata(videoId, request, env, ctx));
			}

			if (pathname.startsWith('/api/video/') && method === 'OPTIONS') {
				return wrapResponse(Promise.resolve(handleVideoCacheOptions()));
			}

			// Batch video lookup endpoint
			if (pathname === '/api/videos/batch' && method === 'POST') {
				return wrapResponse(handleBatchVideoLookup(request, env, ctx));
			}

			if (pathname === '/api/videos/batch' && method === 'OPTIONS') {
				return wrapResponse(Promise.resolve(handleBatchVideoOptions()));
			}

			// Analytics endpoints
			if (pathname === '/api/analytics/popular' && method === 'GET') {
				try {
					const analyticsEngine = new VideoAnalyticsEngineService(env, ctx);
					const url = new URL(request.url);
					const timeframe = url.searchParams.get('window') as '1h' | '24h' | '7d' || '24h';
					const limit = parseInt(url.searchParams.get('limit') || '10');
					
					const popularVideos = await analyticsEngine.getPopularVideos(timeframe, limit);
					
					return new Response(JSON.stringify({
						timeframe,
						videos: popularVideos,
						timestamp: new Date().toISOString()
					}), {
						headers: {
							'Content-Type': 'application/json',
							'Access-Control-Allow-Origin': '*',
							'Cache-Control': 'public, max-age=300'
						}
					});
				} catch (error) {
					return new Response(JSON.stringify({ error: 'Failed to fetch popular videos' }), {
						status: 500,
						headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
					});
				}
			}

			// Analytics view tracking endpoint
			if (pathname === '/analytics/view' && method === 'POST') {
				try {
					const analyticsEngine = new VideoAnalyticsEngineService(env, ctx);
					const data = await request.json() as any;
					
					// Extract video tracking data
					const { 
						eventId, 
						source, 
						creatorPubkey, 
						hashtags, 
						title,
						eventType = 'view_start',
						watchDuration,
						totalDuration,
						loopCount,
						completedVideo
					} = data;
					
					if (!eventId) {
						return new Response(JSON.stringify({ error: 'eventId is required' }), {
							status: 400,
							headers: { 
								'Content-Type': 'application/json',
								'Access-Control-Allow-Origin': '*'
							}
						});
					}
					
					// Calculate completion rate if durations are provided
					let completionRate = undefined;
					if (watchDuration && totalDuration) {
						completionRate = Math.min(watchDuration / totalDuration, 1.0);
					}
					
					// Track the video view using Analytics Engine
					await analyticsEngine.trackVideoView({
						videoId: eventId,
						userId: undefined, // Not provided by mobile app yet
						creatorPubkey,
						source: source || 'mobile',
						eventType,
						hashtags,
						title,
						watchDuration,
						totalDuration,
						loopCount,
						completionRate
					}, request);
					
					return new Response(JSON.stringify({ 
						success: true,
						eventId,
						timestamp: new Date().toISOString()
					}), {
						headers: {
							'Content-Type': 'application/json',
							'Access-Control-Allow-Origin': '*'
						}
					});
				} catch (error) {
					console.error('Analytics view tracking error:', error);
					return new Response(JSON.stringify({ error: 'Failed to track view' }), {
						status: 500,
						headers: { 
							'Content-Type': 'application/json',
							'Access-Control-Allow-Origin': '*'
						}
					});
				}
			}

			// OPTIONS handler for analytics view endpoint
			if (pathname === '/analytics/view' && method === 'OPTIONS') {
				return new Response(null, {
					status: 200,
					headers: {
						'Access-Control-Allow-Origin': '*',
						'Access-Control-Allow-Methods': 'POST, OPTIONS',
						'Access-Control-Allow-Headers': 'Content-Type, User-Agent',
						'Access-Control-Max-Age': '86400'
					}
				});
			}

			// Video-specific analytics
			if (pathname.startsWith('/api/analytics/video/') && method === 'GET') {
				try {
					const analyticsEngine = new VideoAnalyticsEngineService(env, ctx);
					const videoId = pathname.split('/api/analytics/video/')[1];
					const url = new URL(request.url);
					const days = parseInt(url.searchParams.get('days') || '30');
					
					const videoAnalytics = await analyticsEngine.getVideoAnalytics(videoId, days);
					
					return new Response(JSON.stringify(videoAnalytics), {
						headers: {
							'Content-Type': 'application/json',
							'Access-Control-Allow-Origin': '*',
							'Cache-Control': 'public, max-age=300'
						}
					});
				} catch (error) {
					return new Response(JSON.stringify({ error: 'Failed to fetch video analytics' }), {
						status: 500,
						headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
					});
				}
			}

			// Hashtag analytics
			if (pathname === '/api/analytics/hashtag' && method === 'GET') {
				try {
					const analyticsEngine = new VideoAnalyticsEngineService(env, ctx);
					const url = new URL(request.url);
					const hashtag = url.searchParams.get('hashtag');
					const days = parseInt(url.searchParams.get('days') || '7');
					
					if (!hashtag) {
						return new Response(JSON.stringify({ error: 'hashtag parameter is required' }), {
							status: 400,
							headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
						});
					}
					
					const hashtagAnalytics = await analyticsEngine.getHashtagAnalytics(hashtag, days);
					
					return new Response(JSON.stringify(hashtagAnalytics), {
						headers: {
							'Content-Type': 'application/json',
							'Access-Control-Allow-Origin': '*',
							'Cache-Control': 'public, max-age=300'
						}
					});
				} catch (error) {
					return new Response(JSON.stringify({ error: 'Failed to fetch hashtag analytics' }), {
						status: 500,
						headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
					});
				}
			}

			// Creator analytics
			if (pathname === '/api/analytics/creator' && method === 'GET') {
				try {
					const analyticsEngine = new VideoAnalyticsEngineService(env, ctx);
					const url = new URL(request.url);
					const creatorPubkey = url.searchParams.get('pubkey');
					const days = parseInt(url.searchParams.get('days') || '30');
					
					if (!creatorPubkey) {
						return new Response(JSON.stringify({ error: 'pubkey parameter is required' }), {
							status: 400,
							headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
						});
					}
					
					const creatorAnalytics = await analyticsEngine.getCreatorAnalytics(creatorPubkey, days);
					
					return new Response(JSON.stringify(creatorAnalytics), {
						headers: {
							'Content-Type': 'application/json',
							'Access-Control-Allow-Origin': '*',
							'Cache-Control': 'public, max-age=300'
						}
					});
				} catch (error) {
					return new Response(JSON.stringify({ error: 'Failed to fetch creator analytics' }), {
						status: 500,
						headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
					});
				}
			}

			if (pathname === '/api/analytics/dashboard' && method === 'GET') {
				try {
					const analyticsEngine = new VideoAnalyticsEngineService(env, ctx);
					const [healthStatus, realtimeMetrics, popular24h] = await Promise.all([
						analyticsEngine.getHealthStatus(),
						analyticsEngine.getRealtimeMetrics(),
						analyticsEngine.getPopularVideos('24h', 5)
					]);
					
					return new Response(JSON.stringify({
						health: healthStatus,
						metrics: realtimeMetrics,
						popularVideos: popular24h,
						timestamp: new Date().toISOString()
					}), {
						headers: {
							'Content-Type': 'application/json',
							'Access-Control-Allow-Origin': '*',
							'Cache-Control': 'public, max-age=60'
						}
					});
				} catch (error) {
					return new Response(JSON.stringify({ error: 'Failed to fetch dashboard data' }), {
						status: 500,
						headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
					});
				}
			}

			// File check endpoints - check if file exists before upload
			if (pathname.startsWith('/api/check/') && method === 'GET') {
				const sha256 = pathname.split('/api/check/')[1];
				return wrapResponse(handleFileCheckBySha256(sha256, request, env));
			}

			if (pathname === '/api/check' && method === 'POST') {
				return wrapResponse(handleBatchFileCheck(request, env));
			}

			if ((pathname === '/api/check' || pathname.startsWith('/api/check/')) && method === 'OPTIONS') {
				return wrapResponse(Promise.resolve(handleFileCheckOptions()));
			}

			// Event mapping endpoint
			if (pathname === '/api/event-mapping' && method === 'POST') {
				return wrapResponse(handleEventMapping(request, env));
			}

			if (pathname === '/api/event-mapping' && method === 'OPTIONS') {
				return wrapResponse(Promise.resolve(handleEventMappingOptions()));
			}

			// Media lookup endpoint
			if (pathname === '/api/media/lookup' && method === 'GET') {
				return wrapResponse(handleMediaLookup(request, env, ctx));
			}

			if (pathname === '/api/media/lookup' && method === 'OPTIONS') {
				return wrapResponse(Promise.resolve(handleMediaLookupOptions()));
			}

			// Feature flag endpoints
			if (pathname === '/api/feature-flags' && method === 'GET') {
				return wrapResponse(handleListFeatureFlags(request, env, ctx));
			}

			if (pathname.startsWith('/api/feature-flags/') && pathname.endsWith('/check') && method === 'POST') {
				const flagName = pathname.split('/')[3];
				return wrapResponse(handleCheckFeatureFlag(flagName, request, env, ctx));
			}

			if (pathname.startsWith('/api/feature-flags/') && pathname.endsWith('/rollout') && method === 'POST') {
				const flagName = pathname.split('/')[3];
				return wrapResponse(handleGradualRollout(flagName, request, env, ctx));
			}

			if (pathname.startsWith('/api/feature-flags/') && pathname.endsWith('/health') && method === 'GET') {
				const flagName = pathname.split('/')[3];
				return wrapResponse(handleRolloutHealth(flagName, request, env, ctx));
			}

			if (pathname.startsWith('/api/feature-flags/') && pathname.endsWith('/rollback') && method === 'POST') {
				const flagName = pathname.split('/')[3];
				return wrapResponse(handleRollback(flagName, request, env, ctx));
			}

			if (pathname.startsWith('/api/feature-flags/') && !pathname.includes('/check') && !pathname.includes('/rollout') && !pathname.includes('/health') && !pathname.includes('/rollback')) {
				const flagName = pathname.split('/')[3];
				if (method === 'GET') {
					return wrapResponse(handleGetFeatureFlag(flagName, request, env, ctx));
				} else if (method === 'PUT') {
					return wrapResponse(handleUpdateFeatureFlag(flagName, request, env, ctx));
				}
			}

			if (pathname.startsWith('/api/feature-flags') && method === 'OPTIONS') {
				return wrapResponse(Promise.resolve(handleFeatureFlagsOptions()));
			}

			// Thumbnail endpoints
			if (pathname.startsWith('/thumbnail/') && method === 'GET') {
				const videoId = pathname.split('/thumbnail/')[1].split('?')[0];
				const thumbnailService = new ThumbnailService(env);
				
				// Parse query parameters
				const url = new URL(request.url);
				const options = {
					size: url.searchParams.get('size') as 'small' | 'medium' | 'large' | undefined,
					timestamp: parseInt(url.searchParams.get('t') || '1'),
					format: url.searchParams.get('format') as 'jpg' | 'webp' | undefined
				};
				
				return thumbnailService.getThumbnail(videoId, options);
			}

			if (pathname.startsWith('/thumbnail/') && pathname.endsWith('/upload') && method === 'POST') {
				const videoId = pathname.split('/thumbnail/')[1].split('/upload')[0];
				const thumbnailService = new ThumbnailService(env);
				
				// Get thumbnail data from request
				const formData = await request.formData();
				const thumbnailFile = formData.get('thumbnail');
				
				if (!thumbnailFile || !(thumbnailFile instanceof File)) {
					return new Response(JSON.stringify({ error: 'No thumbnail file provided' }), {
						status: 400,
						headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
					});
				}
				
				const thumbnailBuffer = await thumbnailFile.arrayBuffer();
				const format = thumbnailFile.type === 'image/webp' ? 'webp' : 'jpg';
				
				const thumbnailUrl = await thumbnailService.uploadCustomThumbnail(videoId, thumbnailBuffer, format);
				
				return new Response(JSON.stringify({ 
					success: true,
					thumbnailUrl 
				}), {
					headers: { 
						'Content-Type': 'application/json',
						'Access-Control-Allow-Origin': '*'
					}
				});
			}

			if (pathname.startsWith('/thumbnail/') && pathname.endsWith('/list') && method === 'GET') {
				const videoId = pathname.split('/thumbnail/')[1].split('/list')[0];
				const thumbnailService = new ThumbnailService(env);
				const thumbnails = await thumbnailService.listThumbnails(videoId);
				
				return new Response(JSON.stringify({
					videoId,
					thumbnails,
					count: thumbnails.length
				}), {
					headers: { 
						'Content-Type': 'application/json',
						'Access-Control-Allow-Origin': '*',
						'Cache-Control': 'public, max-age=300' // 5 minutes
					}
				});
			}

			if (pathname.startsWith('/thumbnail/') && method === 'OPTIONS') {
				return new Response(null, {
					status: 200,
					headers: {
						'Access-Control-Allow-Origin': '*',
						'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
						'Access-Control-Allow-Headers': 'Content-Type, Authorization'
					}
				});
			}

			// Video metadata endpoints
			if (pathname === '/v1/media/list' && method === 'GET') {
				return handleVideoList(request, env);
			}

			if (pathname.startsWith('/v1/media/metadata/') && method === 'GET') {
				const publicId = pathname.split('/v1/media/metadata/')[1];
				return handleVideoMetadata(publicId, request, env);
			}

			if (pathname === '/v1/media/list' && method === 'OPTIONS') {
				return handleVideoMetadataOptions();
			}

			if (pathname.startsWith('/v1/media/metadata/') && method === 'OPTIONS') {
				return handleVideoMetadataOptions();
			}


			// Releases download endpoint
			if (pathname.startsWith('/releases/')) {
				if (method === 'GET') {
					return handleReleaseDownload(pathname.substring(10), request, env);
				}
			}

			// Debug endpoint to list R2 bucket contents
			if (pathname === '/debug/r2-list' && method === 'GET') {
				try {
					const listResult = await env.MEDIA_BUCKET.list();
					return new Response(JSON.stringify({
						bucket: 'nostrvine-media',
						objects: listResult.objects?.map(obj => ({
							key: obj.key,
							size: obj.size,
							uploaded: obj.uploaded
						})) || [],
						truncated: listResult.truncated
					}), {
						headers: {
							'Content-Type': 'application/json',
							'Access-Control-Allow-Origin': '*'
						}
					});
				} catch (error) {
					return new Response(JSON.stringify({
						error: 'Failed to list bucket',
						message: error.message
					}), {
						status: 500,
						headers: {
							'Content-Type': 'application/json',
							'Access-Control-Allow-Origin': '*'
						}
					});
				}
			}

			// NIP-96 upload endpoint (compatibility)
			if (pathname === '/api/upload') {
				if (method === 'POST') {
					return handleNIP96Upload(request, env, ctx);
				}
				if (method === 'OPTIONS') {
					return handleUploadOptions();
				}
			}

			// URL import endpoint
			if (pathname === '/api/import-url') {
				if (method === 'POST') {
					return handleURLImport(request, env, ctx);
				}
				if (method === 'OPTIONS') {
					return handleURLImportOptions();
				}
			}

			// Upload job status endpoint
			if (pathname.startsWith('/api/status/') && method === 'GET') {
				const jobId = pathname.split('/api/status/')[1];
				return handleJobStatus(jobId, env);
			}

			// Set vine URL mapping endpoint for bulk importer
			if (pathname === '/api/set-vine-mapping' && method === 'POST') {
				try {
					const body = await request.json();
					const { vineUrlPath, fileId } = body;
					
					if (!vineUrlPath || !fileId) {
						return new Response(JSON.stringify({
							error: 'Missing parameters',
							message: 'Both vineUrlPath and fileId are required'
						}), {
							status: 400,
							headers: {
								'Content-Type': 'application/json',
								'Access-Control-Allow-Origin': '*'
							}
						});
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

					const { MetadataStore } = await import('./services/metadata-store');
					const metadataStore = new MetadataStore(env.METADATA_CACHE);
					await metadataStore.setVineUrlMapping(vineUrlPath, fileId);

					return new Response(JSON.stringify({
						success: true,
						message: `Mapped ${vineUrlPath} to ${fileId}`
					}), {
						headers: {
							'Content-Type': 'application/json',
							'Access-Control-Allow-Origin': '*'
						}
					});

				} catch (error) {
					console.error('Set vine mapping error:', error);
					return new Response(JSON.stringify({
						error: 'Internal server error',
						message: error.message
					}), {
						status: 500,
						headers: {
							'Content-Type': 'application/json',
							'Access-Control-Allow-Origin': '*'
						}
					});
				}
			}

			// Handle OPTIONS for set vine mapping
			if (pathname === '/api/set-vine-mapping' && method === 'OPTIONS') {
				return new Response(null, {
					status: 200,
					headers: {
						'Access-Control-Allow-Origin': '*',
						'Access-Control-Allow-Methods': 'POST, OPTIONS',
						'Access-Control-Allow-Headers': 'Content-Type, Authorization'
					}
				});
			}

			// Hash check endpoint for bulk importer
			if (pathname.startsWith('/api/check-hash/') && method === 'GET') {
				const sha256 = pathname.split('/api/check-hash/')[1];
				
				if (!sha256 || sha256.length !== 64) {
					return new Response(JSON.stringify({
						error: 'Invalid SHA256 hash',
						message: 'Provide a valid 64-character SHA256 hash'
					}), {
						status: 400,
						headers: {
							'Content-Type': 'application/json',
							'Access-Control-Allow-Origin': '*'
						}
					});
				}

				try {
					if (!env.METADATA_CACHE) {
						return new Response(JSON.stringify({
							exists: false,
							error: 'Metadata cache not available'
						}), {
							status: 503,
							headers: {
								'Content-Type': 'application/json',
								'Access-Control-Allow-Origin': '*'
							}
						});
					}

					const { MetadataStore } = await import('./services/metadata-store');
					const metadataStore = new MetadataStore(env.METADATA_CACHE);
					const result = await metadataStore.checkDuplicateBySha256(sha256);

					if (!result) {
						return new Response(JSON.stringify({
							exists: false,
							error: 'Check failed'
						}), {
							status: 500,
							headers: {
								'Content-Type': 'application/json',
								'Access-Control-Allow-Origin': '*'
							}
						});
					}

					return new Response(JSON.stringify(result), {
						headers: {
							'Content-Type': 'application/json',
							'Access-Control-Allow-Origin': '*',
							'Cache-Control': 'public, max-age=300' // 5 minutes cache
						}
					});

				} catch (error) {
					console.error('Hash check error:', error);
					return new Response(JSON.stringify({
						exists: false,
						error: 'Internal server error'
					}), {
						status: 500,
						headers: {
							'Content-Type': 'application/json',
							'Access-Control-Allow-Origin': '*'
						}
					});
				}
			}

			// Cleanup duplicates endpoint (admin only)
			if (pathname === '/admin/cleanup-duplicates' && method === 'POST') {
				return wrapResponse(handleCleanupRequest(request, env));
			}

			// Admin cleanup for corrupted HTML files
			if (pathname === '/admin/cleanup-html' && method === 'GET') {
				return wrapResponse(handleAdminCleanup(request, env));
			}
			
			if (pathname === '/admin/cleanup-html' && method === 'OPTIONS') {
				return wrapResponse(Promise.resolve(handleAdminCleanupOptions()));
			}

			// Simple admin cleanup (by file size)
			if (pathname === '/admin/cleanup-simple' && method === 'GET') {
				return wrapResponse(handleAdminCleanupSimple(request, env));
			}
			
			if (pathname === '/admin/cleanup-simple' && method === 'OPTIONS') {
				return wrapResponse(Promise.resolve(handleAdminCleanupSimpleOptions()));
			}

			// Analytics Dashboard (root path)
			if (pathname === '/' && method === 'GET') {
				const dashboardHtml = `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>OpenVine Analytics Dashboard</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
            color: #fff;
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        
        .header {
            text-align: center;
            margin-bottom: 40px;
        }
        
        .header h1 {
            font-size: 2.5rem;
            margin-bottom: 10px;
            background: linear-gradient(45deg, #00ff87, #60efff);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        
        .header p {
            opacity: 0.8;
            font-size: 1.1rem;
        }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 40px;
        }
        
        .stat-card {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 15px;
            padding: 25px;
            text-align: center;
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        
        .stat-card h3 {
            font-size: 2rem;
            color: #00ff87;
            margin-bottom: 10px;
        }
        
        .stat-card p {
            opacity: 0.8;
            font-size: 0.9rem;
        }
        
        .status {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.8rem;
            font-weight: bold;
        }
        
        .status.healthy {
            background: rgba(0, 255, 135, 0.2);
            color: #00ff87;
        }
        
        .status.unknown {
            background: rgba(255, 193, 7, 0.2);
            color: #ffc107;
        }
        
        .popular-videos {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 15px;
            padding: 30px;
            border: 1px solid rgba(255, 255, 255, 0.2);
            margin-bottom: 30px;
        }
        
        .popular-videos h2 {
            margin-bottom: 20px;
            color: #00ff87;
        }
        
        .video-list {
            display: grid;
            gap: 15px;
        }
        
        .video-item {
            background: rgba(255, 255, 255, 0.05);
            padding: 15px;
            border-radius: 10px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .video-info h4 {
            margin-bottom: 5px;
        }
        
        .video-info p {
            opacity: 0.7;
            font-size: 0.9rem;
        }
        
        .video-stats {
            text-align: right;
        }
        
        .video-stats .views {
            color: #00ff87;
            font-weight: bold;
        }
        
        .refresh-btn {
            background: linear-gradient(45deg, #00ff87, #60efff);
            color: #1e3c72;
            border: none;
            padding: 12px 24px;
            border-radius: 25px;
            font-weight: bold;
            cursor: pointer;
            font-size: 1rem;
            margin: 20px auto;
            display: block;
            transition: transform 0.2s;
        }
        
        .refresh-btn:hover {
            transform: translateY(-2px);
        }
        
        .refresh-btn:disabled {
            opacity: 0.6;
            cursor: not-allowed;
        }
        
        .endpoint-info {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 15px;
            padding: 20px;
            border: 1px solid rgba(255, 255, 255, 0.2);
            margin-top: 30px;
        }
        
        .endpoint-info h3 {
            color: #00ff87;
            margin-bottom: 15px;
        }
        
        .endpoint-list {
            display: grid;
            gap: 10px;
        }
        
        .endpoint {
            background: rgba(0, 0, 0, 0.2);
            padding: 10px 15px;
            border-radius: 8px;
            font-family: 'Courier New', monospace;
            font-size: 0.9rem;
        }
        
        .loading {
            text-align: center;
            opacity: 0.7;
            font-style: italic;
        }
        
        .error {
            background: rgba(255, 0, 0, 0.2);
            color: #ff6b6b;
            padding: 15px;
            border-radius: 10px;
            margin: 10px 0;
        }
        
        @media (max-width: 768px) {
            .header h1 {
                font-size: 2rem;
            }
            
            .stats-grid {
                grid-template-columns: 1fr;
            }
            
            .video-item {
                flex-direction: column;
                align-items: flex-start;
                gap: 10px;
            }
            
            .video-stats {
                text-align: left;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🍇 OpenVine Analytics</h1>
            <p>Real-time insights from your decentralized video platform</p>
        </div>
        
        <div class="stats-grid" id="statsGrid">
            <div class="stat-card">
                <h3 id="totalEvents">-</h3>
                <p>Total Events (5min)</p>
            </div>
            <div class="stat-card">
                <h3 id="activeVideos">-</h3>
                <p>Active Videos</p>
            </div>
            <div class="stat-card">
                <h3 id="activeUsers">-</h3>
                <p>Active Users</p>
            </div>
            <div class="stat-card">
                <h3 id="avgWatchTime">-</h3>
                <p>Avg Watch Time (ms)</p>
            </div>
        </div>
        
        <div id="systemStatus" class="stats-grid">
            <div class="stat-card">
                <h3>System Status</h3>
                <p>Analytics Engine: <span id="analyticsStatus" class="status">-</span></p>
                <p>R2 Storage: <span id="r2Status" class="status">-</span></p>
                <p>KV Storage: <span id="kvStatus" class="status">-</span></p>
            </div>
        </div>
        
        <div class="popular-videos">
            <h2>🔥 Popular Videos (24h)</h2>
            <div id="popularVideosList" class="video-list">
                <div class="loading">Loading popular videos...</div>
            </div>
        </div>
        
        <button class="refresh-btn" onclick="refreshDashboard()" id="refreshBtn">
            🔄 Refresh Data
        </button>
        
        <div class="endpoint-info">
            <h3>📡 Available Analytics Endpoints</h3>
            <div class="endpoint-list">
                <div class="endpoint">GET /api/analytics/dashboard - This dashboard data</div>
                <div class="endpoint">POST /analytics/view - Track video views</div>
                <div class="endpoint">GET /api/analytics/popular?window=24h&limit=10 - Popular videos</div>
                <div class="endpoint">GET /api/analytics/video/{videoId}?days=30 - Video-specific analytics</div>
                <div class="endpoint">GET /api/analytics/creator?pubkey={pubkey} - Creator analytics</div>
                <div class="endpoint">GET /api/analytics/hashtag?hashtag={tag} - Hashtag analytics</div>
            </div>
        </div>
        
        <div id="lastUpdate" style="text-align: center; margin-top: 20px; opacity: 0.6; font-size: 0.9rem;">
            Last updated: <span id="timestamp">-</span>
        </div>
    </div>
    
    <script>
        let refreshInterval;
        
        async function fetchDashboardData() {
            try {
                const response = await fetch('/api/analytics/dashboard');
                if (!response.ok) {
                    throw new Error(\`HTTP \${response.status}: \${response.statusText}\`);
                }
                return await response.json();
            } catch (error) {
                console.error('Failed to fetch dashboard data:', error);
                throw error;
            }
        }
        
        async function fetchPopularVideos() {
            try {
                const response = await fetch('/api/analytics/popular?window=24h&limit=10');
                if (!response.ok) {
                    throw new Error(\`HTTP \${response.status}: \${response.statusText}\`);
                }
                return await response.json();
            } catch (error) {
                console.error('Failed to fetch popular videos:', error);
                throw error;
            }
        }
        
        function updateStats(data) {
            const metrics = data.metrics || {};
            
            document.getElementById('totalEvents').textContent = metrics.totalEvents || 0;
            document.getElementById('activeVideos').textContent = metrics.activeVideos || 0;
            document.getElementById('activeUsers').textContent = metrics.activeUsers || 0;
            document.getElementById('avgWatchTime').textContent = Math.round(metrics.averageWatchTime || 0);
            
            // Update system status
            const health = data.health || {};
            const deps = health.dependencies || {};
            
            updateStatusBadge('analyticsStatus', deps.analyticsEngine || 'unknown');
            updateStatusBadge('r2Status', deps.r2 || 'unknown');
            updateStatusBadge('kvStatus', deps.kv || 'unknown');
            
            // Update timestamp
            document.getElementById('timestamp').textContent = new Date(data.timestamp).toLocaleString();
        }
        
        function updateStatusBadge(elementId, status) {
            const element = document.getElementById(elementId);
            element.textContent = status;
            element.className = \`status \${status}\`;
        }
        
        function updatePopularVideos(data) {
            const container = document.getElementById('popularVideosList');
            const videos = data.videos || [];
            
            if (videos.length === 0) {
                container.innerHTML = \`
                    <div class="loading">
                        No popular videos yet. Videos will appear here once analytics data is available.
                        <br><br>
                        Note: SQL queries are pending Cloudflare Analytics Engine API availability.
                    </div>
                \`;
                return;
            }
            
            container.innerHTML = videos.map(video => \`
                <div class="video-item">
                    <div class="video-info">
                        <h4>\${video.videoId?.substring(0, 12) || 'Unknown Video'}...</h4>
                        <p>Views: \${video.views || 0} • Unique: \${video.uniqueViewers || 0}</p>
                    </div>
                    <div class="video-stats">
                        <div class="views">\${video.views || 0} views</div>
                        <p>Avg: \${Math.round(video.avgWatchTime || 0)}ms</p>
                    </div>
                </div>
            \`).join('');
        }
        
        function showError(message) {
            const container = document.getElementById('popularVideosList');
            container.innerHTML = \`
                <div class="error">
                    ❌ Error: \${message}
                    <br><br>
                    Analytics Engine is deployed but SQL queries may not be available yet.
                </div>
            \`;
        }
        
        async function refreshDashboard() {
            const refreshBtn = document.getElementById('refreshBtn');
            refreshBtn.disabled = true;
            refreshBtn.textContent = '🔄 Refreshing...';
            
            try {
                // Fetch dashboard data and popular videos in parallel
                const [dashboardData, popularData] = await Promise.all([
                    fetchDashboardData(),
                    fetchPopularVideos()
                ]);
                
                updateStats(dashboardData);
                updatePopularVideos(popularData);
                
            } catch (error) {
                console.error('Dashboard refresh failed:', error);
                showError(error.message);
            } finally {
                refreshBtn.disabled = false;
                refreshBtn.textContent = '🔄 Refresh Data';
            }
        }
        
        // Initial load
        refreshDashboard();
        
        // Auto-refresh every 30 seconds
        refreshInterval = setInterval(refreshDashboard, 30000);
        
        // Clean up interval when page is hidden
        document.addEventListener('visibilitychange', () => {
            if (document.hidden) {
                clearInterval(refreshInterval);
            } else {
                refreshInterval = setInterval(refreshDashboard, 30000);
                refreshDashboard(); // Refresh immediately when page becomes visible
            }
        });
    </script>
</body>
</html>`;

				return new Response(dashboardHtml, {
					headers: {
						'Content-Type': 'text/html',
						'Cache-Control': 'public, max-age=60'
					}
				});
			}

			// Health check endpoint with analytics
			if (pathname === '/health' && method === 'GET') {
				const analyticsEngine = new VideoAnalyticsEngineService(env, ctx);
				const healthStatus = await analyticsEngine.getHealthStatus();
				
				return wrapResponse(Promise.resolve(new Response(JSON.stringify({
					...healthStatus,
					version: '1.0.0',
					services: {
						nip96: 'active',
						r2_storage: healthStatus.dependencies.r2,
						stream_api: 'active',
						video_cache_api: 'active',
						kv_storage: healthStatus.dependencies.kv,
						rate_limiter: healthStatus.dependencies.rateLimiter
					}
				}), {
					headers: {
						'Content-Type': 'application/json',
						'Access-Control-Allow-Origin': '*'
					}
				})));
			}

			// Original Vine URL compatibility - serve files using original vine CDN paths
			// Handle various Vine URL patterns like:
			// /r/videos_h264high/, /r/videos/, /r/videos_h264low/, /r/thumbs/, /r/avatars/, /v/, /t/
			if ((pathname.startsWith('/r/') || pathname.startsWith('/v/') || pathname.startsWith('/t/')) && method === 'GET') {
				const vineUrlPath = pathname.substring(1); // Remove leading slash
				return wrapResponse(handleVineUrlCompat(vineUrlPath, request, env));
			}

			// Media serving endpoint
			if (pathname.startsWith('/media/') && method === 'GET') {
				const fileId = pathname.split('/media/')[1];
				return handleMediaServing(fileId, request, env);
			}

			// Moderation API endpoints
			if (pathname === '/api/moderation/report' && method === 'POST') {
				return wrapResponse(handleReportSubmission(request, env, ctx));
			}

			if (pathname === '/api/moderation/report' && method === 'OPTIONS') {
				return wrapResponse(Promise.resolve(handleModerationOptions()));
			}

			if (pathname.startsWith('/api/moderation/status/') && method === 'GET') {
				const videoId = pathname.split('/api/moderation/status/')[1];
				return wrapResponse(handleModerationStatus(videoId, request, env));
			}

			if (pathname.startsWith('/api/moderation/status/') && method === 'OPTIONS') {
				return wrapResponse(Promise.resolve(handleModerationOptions()));
			}

			if (pathname === '/api/moderation/queue' && method === 'GET') {
				return wrapResponse(handleModerationQueue(request, env));
			}

			if (pathname === '/api/moderation/queue' && method === 'OPTIONS') {
				return wrapResponse(Promise.resolve(handleModerationOptions()));
			}

			if (pathname === '/api/moderation/action' && method === 'POST') {
				return wrapResponse(handleModerationAction(request, env, ctx));
			}

			if (pathname === '/api/moderation/action' && method === 'OPTIONS') {
				return wrapResponse(Promise.resolve(handleModerationOptions()));
			}

			// Default 404 response
			return new Response(JSON.stringify({
				error: 'Not Found',
				message: `Endpoint ${pathname} not found`,
				available_endpoints: [
					'/.well-known/nostr/nip96.json',
					'/.well-known/nostr.json?name=username (NIP-05 verification)',
					'/api/nip05/register (NIP-05 username registration)',
					'/v1/media/request-upload (Stream CDN)',
					'/v1/webhooks/stream-complete',
					'/v1/media/status/{videoId}',
					'/v1/media/list',
					'/v1/media/metadata/{publicId}',
					'/api/video/{videoId} (Video Cache API)',
					'/api/videos/batch (Batch Video Lookup)',
					'/analytics/view (Track Video Views)',
					'/api/analytics/popular (Popular Videos)',
					'/api/analytics/dashboard (Analytics Dashboard)',
					'/api/analytics/video/{videoId} (Video Analytics)',
					'/api/analytics/hashtag?hashtag={tag} (Hashtag Analytics)',
					'/api/analytics/creator?pubkey={pubkey} (Creator Analytics)',
					'/api/media/lookup (Media Lookup by vine_id or filename)',
					'/api/feature-flags (Feature Flag Management)',
					'/api/feature-flags/{flagName}/check (Check Feature Flag)',
					'/api/moderation/report (Report content)',
					'/api/moderation/status/{videoId} (Check moderation status)',
					'/api/moderation/queue (Admin: View moderation queue)',
					'/api/moderation/action (Admin: Take moderation action)',
					'/v1/media/cloudinary-upload (Legacy)',
					'/v1/media/webhook (Legacy)',
					'/api/upload (NIP-96)',
					'/api/import-url (Import video from URL)',
					'/api/status/{jobId}',
					'/api/check-hash/{sha256} (Check if file exists by hash)',
					'/api/set-vine-mapping (Set mapping from original Vine URL to fileId)',
					'/admin/cleanup-duplicates (Admin: Clean up duplicate files)',
					'/admin/cleanup-html?mode=scan (Admin: Scan for corrupted HTML files)',
					'/admin/cleanup-html?mode=delete (Admin: Delete corrupted HTML files)',
					'/r/videos_h264high/{vineId}, /r/videos/{vineId}, /v/{vineId}, /t/{vineId} (Vine URL compatibility)',
					'/thumbnail/{videoId} (Get/generate thumbnail)',
					'/thumbnail/{videoId}/upload (Upload custom thumbnail)',
					'/thumbnail/{videoId}/list (List available thumbnails)',
					'/health',
					'/media/{fileId}',
					'/releases/{filename} (Download app releases)'
				]
			}), {
				status: 404,
				headers: {
					'Content-Type': 'application/json',
					'Access-Control-Allow-Origin': '*'
				}
			});

		} catch (error) {
			const duration = Date.now() - startTime;
			console.error(`❌ ${method} ${pathname} - Error after ${duration}ms:`, error);
			
			// Structured error response
			const errorResponse = {
				error: 'Internal Server Error',
				message: error instanceof Error ? error.message : 'An unexpected error occurred',
				timestamp: new Date().toISOString(),
				path: pathname,
				method: method
			};

			if (env.ENVIRONMENT === 'development') {
				// Include stack trace in development
				errorResponse['stack'] = error instanceof Error ? error.stack : undefined;
			}
			
			return new Response(JSON.stringify(errorResponse), {
				status: 500,
				headers: {
					'Content-Type': 'application/json',
					'Access-Control-Allow-Origin': '*',
					'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
					'Access-Control-Allow-Headers': 'Content-Type, Authorization'
				}
			});
		}
	},
} satisfies ExportedHandler<Env>;

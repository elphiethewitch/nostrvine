// ABOUTME: Test script to demonstrate thumbnail mapping functionality
// ABOUTME: Shows how mobile app can use event IDs to get thumbnails

/**
 * Example of how the mobile app would use the thumbnail service
 * after publishing a Kind 22 event
 */

// Example 1: Mobile app publishes a video and gets back the event
const videoUrl = 'https://api.openvine.co/media/1704067200-abc123';
const nostrEventId = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

// Extract fileId from video URL
const fileId = videoUrl.split('/media/')[1]; // "1704067200-abc123"

// Store the mapping
console.log('Storing event mapping...');
const mappingResponse = await fetch('https://api.openvine.co/api/event-mapping', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    eventId: nostrEventId,
    fileId: fileId,
    videoUrl: videoUrl,
    thumbnailUrl: `https://api.openvine.co/thumbnail/${fileId}` // Optional
  })
});

console.log('Mapping stored:', await mappingResponse.json());

// Example 2: Another client receives the Kind 22 event without thumbnail
// They can now request thumbnail using the event ID
const thumbnailUrl = `https://api.openvine.co/thumbnail/${nostrEventId}?t=2.5&size=medium`;
console.log('Thumbnail URL:', thumbnailUrl);

// The backend will:
// 1. Detect it's a 64-char hex event ID
// 2. Look up the mapping to get fileId
// 3. Generate or serve the thumbnail for that video

// Example 3: Direct file ID still works (backward compatible)
const directThumbnailUrl = `https://api.openvine.co/thumbnail/${fileId}?t=2.5&size=medium`;
console.log('Direct thumbnail URL:', directThumbnailUrl);
// ABOUTME: Utility functions for extracting Vine IDs from filenames and metadata
// ABOUTME: Supports various Vine filename patterns and provides robust ID extraction

/**
 * Extract Vine ID from filename or path
 * Handles common patterns:
 * - "iBu3q1zHizZ.mp4" -> "iBu3q1zHizZ"
 * - "vine_iBu3q1zHizZ.webm" -> "iBu3q1zHizZ"
 * - "/path/to/iBu3q1zHizZ_something.mp4" -> "iBu3q1zHizZ"
 * - Vine IDs are typically 11 characters: alphanumeric (base62-like)
 */
export function extractVineIdFromFilename(filename: string): string | null {
  if (!filename) return null;

  // Remove path and get just the filename
  const baseName = filename.split('/').pop() || filename;
  
  // Pattern for Vine ID: 11 characters, alphanumeric (case-sensitive)
  // Vine used a base62-like encoding: [a-zA-Z0-9]
  const vineIdPattern = /([a-zA-Z0-9]{11})/;
  const match = baseName.match(vineIdPattern);
  
  return match ? match[1] : null;
}

/**
 * Validate that a string looks like a valid Vine ID
 * Vine IDs are 11 characters, alphanumeric, case-sensitive
 */
export function isValidVineId(vineId: string): boolean {
  if (!vineId || typeof vineId !== 'string') return false;
  
  // Must be exactly 11 characters and alphanumeric
  return /^[a-zA-Z0-9]{11}$/.test(vineId);
}

/**
 * Extract multiple potential Vine IDs from a string
 * Useful for processing batch operations or complex filenames
 */
export function extractAllVineIds(input: string): string[] {
  if (!input) return [];
  
  const vineIdPattern = /[a-zA-Z0-9]{11}/g;
  const matches = input.match(vineIdPattern) || [];
  
  // Filter to only valid Vine IDs (remove false positives)
  return matches.filter(isValidVineId);
}

/**
 * Generate a normalized filename for a Vine ID
 * Useful for creating consistent file naming
 */
export function generateVineFilename(vineId: string, extension: string = 'mp4'): string {
  if (!isValidVineId(vineId)) {
    throw new Error(`Invalid Vine ID: ${vineId}`);
  }
  
  // Ensure extension starts with dot
  const ext = extension.startsWith('.') ? extension : `.${extension}`;
  
  return `${vineId}${ext}`;
}

/**
 * Extract metadata from filename that might contain Vine information
 * Returns object with vine ID and other extracted info
 */
export function extractVineMetadata(filename: string): {
  vineId: string | null;
  originalFilename: string;
  extension: string | null;
  hasVinePrefix: boolean;
} {
  const vineId = extractVineIdFromFilename(filename);
  const baseName = filename.split('/').pop() || filename;
  const extension = baseName.includes('.') ? baseName.split('.').pop() : null;
  const hasVinePrefix = baseName.toLowerCase().includes('vine');
  
  return {
    vineId,
    originalFilename: baseName,
    extension,
    hasVinePrefix
  };
}
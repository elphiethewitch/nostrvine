# OpenVine ProofMode Implementation Plan

## Overview

This document outlines the implementation plan for ProofMode-style video authentication in OpenVine to prove videos were captured live on official OpenVine apps, distinguishing them from spam bots, AI-generated content, or recycled videos.

## Goals

- **Primary**: Detect and filter spam bot content
- **Secondary**: Prove authenticity of live-captured videos
- **Requirement**: Support creative recording styles (stop-motion, time-lapse)
- **Constraint**: Maintain performance and user experience

## Architecture

### Two-Key System
- **Nostr keypair**: User's social identity (existing nsec/npub)
- **PGP keypair**: Device/app verification (stored in secure keychain)

### Tiered Verification Levels

```
verified_mobile   -> Full device attestation + sensors + PGP
verified_web      -> Browser fingerprint + interaction patterns  
basic_proof       -> Simple signing + timing
unverified        -> No proof data
```

## Implementation Phases

### Phase 1: Foundation Infrastructure (Weeks 1-2)

**Objective**: Establish secure cryptographic foundation and key management

**Components**:
1. **PGP Key Management Service**
   - Generate device-specific PGP keypair on first install
   - Store keys in platform keychain (iOS Keychain, Android Keystore)
   - Export public key fingerprints for verification

2. **Platform-Specific Crypto Bridges**
   - iOS: Native Swift bridge using CryptoKit
   - Android: Kotlin bridge using Bouncy Castle  
   - Web: Fallback to WebCrypto API

3. **Device Attestation Integration**
   - iOS: App Attest API integration (no user permission required)
   - Android: Play Integrity API integration (no user permission required)
   - Web: Browser fingerprinting

**Milestone**: Keys can be generated and stored securely

### Phase 2: Video Capture Integration (Weeks 3-4)

**Objective**: Integrate proof generation into existing video capture pipeline

**Key Considerations for Vine Recording**:
- Support start/stop segments within 6-second window
- Handle stop-motion recording (short segments, long pauses)
- Maintain proof session continuity during pauses

**Components**:
1. **Segment-Based Proof Session**
```dart
class VineProofSession {
  final String challengeNonce;
  final int sessionStartTime;
  final List<RecordingSegment> segments = [];
  final List<PauseProof> pauseProofs; // Proof during pauses
  final List<UserInteractionProof> interactions; // Start/stop events
}
```

2. **Background Proof Processing**
   - Separate isolate for non-blocking frame hashing
   - Sample frames during recording segments only
   - Continue sensor monitoring during pauses

3. **Human Activity Detection**
   - Focus on "real human on real device" vs timing patterns
   - Natural variation detection (even careful humans vary)
   - Biometric micro-signals (hand tremor, breathing, heartbeat)

**Milestone**: Video hashing works without performance impact

### Phase 3: Nostr Protocol Integration (Weeks 5-6)

**Objective**: Extend Nostr events to carry proof data

**Event Structure**:
```json
{
  "kind": 22,
  "tags": [
    ["h", "vine"],
    ["url", "video_url"],
    ["proof-level", "verified_mobile|verified_web|basic_proof"],
    ["proof-key", "pgp_public_key_fingerprint"],
    ["proof-data", "base64_encoded_proof_manifest"],
    ["device-attestation", "attestation_token"],
    ["capture-method", "mobile|webcam"],
    ["live-captured", "true"]
  ]
}
```

**Proof Manifest Structure**:
```dart
class ProofManifest {
  final String challengeNonce;           // Server-provided nonce
  final int vineSessionStart;            // 6-second session start
  final int vineSessionEnd;              // 6-second session end
  final List<RecordingSegment> segments; // Individual recording segments
  final List<PauseProof> pauseProofs;    // Activity during pauses
  final String finalVideoHash;           // SHA256 of complete video
  final List<UserInteractionProof> interactions; // Start/stop events
  final String pgpSignature;             // PGP signature of manifest
}
```

**Milestone**: Proof events publish successfully

### Phase 4: Backend Verification Infrastructure (Weeks 7-8)

**Objective**: Build Cloudflare Workers services for proof verification

**Verification Service**:
```typescript
async function verifyVideoProof(data: ProofData): Promise<VerificationResult> {
  // 1. Verify device attestation (mobile) or browser fingerprint (web)
  const platformValid = await verifyPlatformAuth(data);
  
  // 2. Verify PGP signature on proof manifest
  const signatureValid = await verifyPGPSignature(data.proofManifest);
  
  // 3. Spot-check frame hashes against actual video
  const videoValid = await spotCheckVideoFrames(data.videoUrl, data.frameProofs);
  
  // 4. Validate human activity patterns
  const humanValid = await validateHumanActivity(data.interactions);
  
  return {
    isValid: platformValid && signatureValid && videoValid && humanValid,
    proofLevel: determineProofLevel(data.platform),
    confidenceScore: calculateConfidence(...)
  };
}
```

**Relay Policy Integration**:
```javascript
export const strfryPolicy = {
  async acceptEvent(event) {
    const proofLevel = event.tags.find(t => t[0] === 'proof-level')?.[1];
    
    switch (proofLevel) {
      case 'verified_mobile':
        return { accept: true }; // Always accept mobile verified
      case 'verified_web':
        return await verifyWebProof(event);
      case 'basic_proof':
        return await checkRateLimit(event.pubkey);
      default:
        return await applyStrictSpamFilters(event);
    }
  }
};
```

**Milestone**: End-to-end verification working

### Phase 5: Security Hardening and Client Integration (Weeks 9-10)

**Objective**: Harden against attacks and integrate verification UI

**Security Measures**:
1. **Anti-Reverse Engineering**
   - Obfuscate proof generation timing
   - App integrity validation
   - Rotate frame sampling patterns

2. **Human Activity Validation**
   - Natural variation detection (impossible precision = bot)
   - Biometric micro-signals
   - Environmental authenticity

3. **UI Integration**
   - Verification badges showing proof level
   - User settings for proof features
   - Privacy controls

**Milestone**: Production-ready implementation

## Platform-Specific Considerations

### Mobile (iOS/Android)
- **Full ProofMode capabilities**
- Device attestation (Play Integrity, App Attest) - no user permission required
- Rich sensor suite (GPS, accelerometer, gyroscope)
- Hardware-backed key storage
- **Proof Level**: `verified_mobile`

### Web/Webcam
- **Reduced but meaningful proof**
- Browser fingerprinting
- User interaction patterns
- WebRTC characteristics
- Camera device fingerprinting
- **Proof Level**: `verified_web`

## Human Activity Detection

### What Indicates Real Human Activity
```dart
class HumanActivityDetector {
  // Focus on biological impossibilities for bots:
  
  // 1. Natural micro-variations (even careful humans vary)
  bool hasNaturalVariation() {
    // Touch coordinates vary by 1-3 pixels
    // Timing varies by 10-50ms minimum
    // Pressure varies naturally
  }
  
  // 2. Biometric micro-signals
  bool hasBiometricSignals() {
    // Hand tremor (8-12 Hz) - unavoidable
    // Breathing cycle influence
    // Cardiac pulse effects
  }
  
  // 3. Real device usage
  bool hasRealDeviceCharacteristics() {
    // Device sensors show handling
    // Environment shows natural variation
    // Platform-specific characteristics present
  }
}
```

### Bot Detection Red Flags
- Identical touch coordinates (impossible for humans)
- Zero pressure variation across touches
- Perfect mathematical timing intervals
- Missing biometric micro-signals
- Static environment (no ambient changes)
- Emulator/VM detection

## Creative Use Case Support

### Stop-Motion and Time-Lapse
- **Support**: Deliberate timing patterns are fine
- **Validation**: Focus on "real human on real device" vs "natural timing"
- **Detection**: Even stop-motion creators have natural micro-variations

### Validation Strategy
```dart
// ✅ Allow: Creative timing patterns
// ❌ Block: Perfect precision impossible for humans
bool isLegitimateCreativeRecording(interactions) {
  return hasRealDeviceUsage(interactions) &&
         hasGenuineUserPresence(interactions) &&
         hasNaturalMicroVariations(interactions); // Even when being careful
}
```

## Feature Flag Implementation

### Development Strategy
```dart
class ProofModeConfig {
  static bool get isEnabled => 
    FeatureFlags.isEnabled('proofmode_enabled');
    
  static bool get isMobileProofEnabled => 
    FeatureFlags.isEnabled('proofmode_mobile');
    
  static bool get isWebProofEnabled => 
    FeatureFlags.isEnabled('proofmode_web');
    
  static bool get isUIEnabled => 
    FeatureFlags.isEnabled('proofmode_ui');
}

// Usage in camera service
class CameraService {
  Future<void> startRecording() async {
    if (ProofModeConfig.isEnabled) {
      await _proofService.startProofGeneration();
    }
    
    // Normal recording logic
    await _camera.startVideoRecording();
  }
}
```

### Feature Flag Stages
1. **`proofmode_dev`**: Enable for development/testing
2. **`proofmode_crypto`**: Enable crypto key generation
3. **`proofmode_capture`**: Enable proof generation during recording
4. **`proofmode_publish`**: Enable proof data in Nostr events
5. **`proofmode_verify`**: Enable verification services
6. **`proofmode_ui`**: Enable verification badges in UI
7. **`proofmode_production`**: Full production release

## Risk Mitigation

### High-Risk Items
1. **Performance Impact**
   - Risk: Video recording performance degradation
   - Mitigation: Background isolates, early performance testing
   - Fallback: Reduce hash frequency or post-capture processing

2. **Platform Crypto Libraries**
   - Risk: Library compatibility across platforms
   - Mitigation: Start with pure Dart, optimize later
   - Fallback: Simpler crypto without hardware security

3. **Device Attestation APIs**
   - Risk: Google/Apple API integration complexity
   - Mitigation: Incremental implementation
   - Fallback: App-specific signatures without attestation

### Success Metrics
- Spam bot detection rate >95%
- Video recording performance impact <5%
- User adoption of verification features >80%
- False positive rate for legitimate videos <1%

## Technology Stack

### Flutter Dependencies
- `dart_pg` or platform channels for PGP
- `sensors_plus`, `geolocator`, `device_info_plus`
- `flutter_secure_storage` for key management
- Platform-specific attestation plugins

### Backend Stack
- Cloudflare Workers for verification API
- strfry relay with custom policy scripts
- Google/Apple attestation validation services

## Next Steps

1. **Research Phase**: Evaluate PGP library options (dart_pg vs platform channels)
2. **Prototype**: Basic proof generation without camera integration
3. **Performance Testing**: Measure impact on video recording
4. **Feature Flag Setup**: Implement progressive rollout system
5. **Documentation**: Draft Nostr event specification for community feedback

## Privacy Considerations

### Data Collected
- Motion patterns (not location)
- Touch characteristics (not content)  
- Audio levels (not actual audio)
- Light variation (not images)
- Device characteristics (hashed/anonymized)

### Data NOT Collected
- Actual face images
- Audio recordings
- Precise location coordinates
- Personal identifiers
- Biometric templates

### User Controls
- Enable/disable proof generation
- Control sensor data inclusion
- Privacy-focused sensor data (hashed network fingerprints)
- Opt-out of location data

## Device Attestation Details

### No User Permissions Required

**iOS App Attest**:
- Runs transparently in background
- No permission prompt to user
- No Info.plist entries required
- Requires iOS 14+ and compatible hardware
- Uses Secure Enclave for hardware-backed verification

**Android Play Integrity**:
- No AndroidManifest.xml permissions needed
- No user consent dialog
- Operates through Google Play Services automatically
- Requires Play Services (available on most Android devices)
- Hardware-backed attestation when available

**Implementation**:
```dart
class DeviceAttestationService {
  // This works without asking user permission
  Future<String?> generateAttestation(String challenge) async {
    try {
      if (Platform.isIOS) {
        return await _generateiOSAttestation(challenge);
      } else if (Platform.isAndroid) {
        return await _generateAndroidAttestation(challenge);
      }
    } catch (e) {
      // Graceful fallback if not available
      return null;
    }
  }
}
```

### Privacy/Disclosure Requirements

**Required**:
- Privacy policy disclosure about device attestation for security
- App store data safety forms (check "device identifiers")
- Optional mention in app descriptions about anti-spam measures

**Example privacy text**:
> "We use device attestation to verify that videos are captured on legitimate devices to prevent spam and maintain content quality."

### Device Support Limitations

**Devices that may not support attestation**:
- iOS devices before iOS 14
- Android devices without Google Play Services (de-Googled phones)
- Development emulators
- Some older hardware

**Graceful fallback strategy**:
```dart
Future<ProofLevel> determineProofLevel() async {
  final attestation = await DeviceAttestationService.generateAttestation(challenge);
  
  if (attestation != null) {
    return ProofLevel.verified_mobile; // Full verification with attestation
  } else {
    return ProofLevel.basic_proof;     // Fallback without attestation
  }
}
```

## Implementation Notes

- All proof generation happens in background isolates to maintain UI performance
- Proof session continues during recording pauses to detect human presence
- Multiple recording segments within 6-second vine window are fully supported
- Web implementation provides meaningful verification despite platform limitations
- Progressive enhancement: features degrade gracefully across platforms
- Device attestation operates invisibly - users never see permission prompts
- Graceful fallback for devices that don't support hardware attestation
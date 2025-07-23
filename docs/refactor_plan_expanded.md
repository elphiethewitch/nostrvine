# OpenVine Aggressive Refactoring Plan: Pre-Launch Clean Slate Transformation

## Executive Summary

This expanded plan leverages OpenVine's pre-launch status to perform aggressive refactoring without backward compatibility concerns. Timeline compressed from 12 to 6-8 weeks with complete restructuring, mass renaming, and comprehensive reorganization.

## Core Principles for Pre-Launch Refactoring

1. **No Backward Compatibility** - Break anything that needs breaking
2. **Mass Operations** - Rename, restructure, reorganize entire directories at once
3. **Aggressive Timeline** - No gradual migrations, direct replacements
4. **AI-Driven Development** - Detailed prompts for every refactoring task
5. **Complete Restructuring** - New directory structure, naming conventions, organization

## New Directory Structure (Implement Week 1)

```
mobile/
├── lib/
│   ├── core/                      # Core utilities and shared code
│   │   ├── async/                 # AsyncUtils, Completers, Stream handlers
│   │   ├── cache/                 # Unified caching system
│   │   ├── constants/             # App-wide constants
│   │   ├── extensions/            # Dart extensions
│   │   ├── logging/               # Centralized logging
│   │   └── utils/                 # General utilities
│   │
│   ├── features/                  # Feature-based organization
│   │   ├── auth/
│   │   │   ├── data/              # Repositories, data sources
│   │   │   ├── domain/            # Models, entities
│   │   │   ├── presentation/     # Screens, widgets, providers
│   │   │   └── services/          # Business logic
│   │   │
│   │   ├── video/
│   │   │   ├── capture/           # Recording functionality
│   │   │   ├── playback/          # Video players
│   │   │   ├── processing/        # GIF creation, uploads
│   │   │   └── feed/              # Video feed features
│   │   │
│   │   ├── social/
│   │   │   ├── reactions/         # Likes, reposts
│   │   │   ├── profiles/          # User profiles
│   │   │   └── following/         # Follow system
│   │   │
│   │   └── nostr/
│   │       ├── client/            # WebSocket management
│   │       ├── events/            # Event handling
│   │       └── relay/             # Relay management
│   │
│   ├── infrastructure/            # External service integrations
│   │   ├── analytics/
│   │   ├── cloudflare/
│   │   └── storage/
│   │
│   └── app/                       # App-level code
│       ├── routing/               # Navigation
│       ├── theme/                 # Design system
│       └── startup/               # App initialization
```

## Phase 1: Foundation & Mass Restructuring (Week 1)

### 1.1 Directory Restructuring

**Checklist:**
- [ ] Create new directory structure
- [ ] Move files to new locations with git mv
- [ ] Update all imports
- [ ] Verify app still compiles
- [ ] Run flutter analyze

**AI Prompt for Directory Restructuring:**
```
I need to restructure the Flutter app from a flat service-based structure to a feature-based structure. Current structure has all services in lib/services/, all screens in lib/screens/, etc. 

New structure should be:
- lib/features/{feature_name}/{data,domain,presentation,services}
- lib/core/{async,cache,constants,extensions,logging,utils}
- lib/infrastructure/{analytics,cloudflare,storage}

Please:
1. Create a shell script that uses git mv to move all files
2. Generate a sed script to update all imports
3. Identify any circular dependencies that need breaking
4. Suggest which files belong in which feature modules

Current key services:
- video_event_service.dart (1300+ lines)
- auth_service.dart
- nostr_service.dart
- social_service.dart
```

### 1.2 Mass Naming Convention Update

**Checklist:**
- [ ] Rename all files to follow convention: feature_component_type.dart
- [ ] Update class names to match file names
- [ ] Remove all "new", "improved", "v2" suffixes
- [ ] Ensure consistent naming across codebase
- [ ] Update all imports and references

**AI Prompt for Mass Renaming:**
```
I need to perform a mass rename operation on a Flutter codebase to enforce consistent naming:

Rules:
1. Files: lowercase_with_underscores.dart
2. Classes: PascalCase matching file name
3. Remove all temporal suffixes (_v2, _new, _improved, _old)
4. Feature-based prefixes (video_, auth_, social_, nostr_)

Generate:
1. A script to rename all files following the pattern
2. A script to update all class names in files
3. A script to update all imports
4. A validation script to ensure no broken references

Example transformations needed:
- feed_screen_v2.dart → video_feed_screen.dart
- NostrServiceInterface → INostrService
- user_profile_service.dart → social_profile_service.dart
```

### 1.3 Code Quality Gates

**Checklist:**
- [ ] Configure analysis_options.yaml with strict rules
- [ ] Set max file length to 200 lines
- [ ] Set max function length to 30 lines
- [ ] Enable all lint rules
- [ ] Add pre-commit hooks
- [ ] Configure CI/CD to fail on violations

**AI Prompt for Quality Configuration:**
```
Configure strict Flutter analysis options for a pre-launch app that can break anything:

Requirements:
- Maximum file length: 200 lines
- Maximum function length: 30 lines
- Maximum cyclomatic complexity: 5
- No Future.delayed allowed
- No dynamic types
- Require type annotations everywhere
- Require documentation on all public APIs

Generate:
1. Complete analysis_options.yaml
2. Pre-commit hook script
3. CI/CD configuration for GitHub Actions
4. VS Code settings.json for team
```

## Phase 2: Service Decomposition Blitz (Week 2)

### 2.1 VideoEventService Destruction

**Checklist:**
- [ ] Extract video network operations (max 150 lines)
- [ ] Extract video caching logic (max 150 lines)
- [ ] Extract video state management (max 150 lines)
- [ ] Extract video event coordination (max 100 lines)
- [ ] Delete original 1300+ line file
- [ ] Write tests for each new service
- [ ] Ensure zero code duplication

**AI Prompt for Service Decomposition:**
```
I have a 1300+ line VideoEventService that needs to be split into focused services. This is a pre-launch app so we can break anything.

Current responsibilities mixed in the service:
- Fetching videos from Nostr relays
- Caching video metadata
- Managing video player states
- Handling video events (likes, reposts)
- Video upload coordination
- Subscription management

Please analyze the service and:
1. Identify distinct responsibilities
2. Create interfaces for each new service
3. Generate the new service implementations
4. Show how to wire them together with dependency injection
5. Create a migration script to update all usages

Maximum service size: 150 lines
Use SOLID principles and clean architecture
```

### 2.2 Aggressive Function Extraction

**Checklist:**
- [ ] No function longer than 30 lines
- [ ] Every function does ONE thing
- [ ] Extract all inline logic to named functions
- [ ] Create helper classes for complex operations
- [ ] Add ABOUTME comments to all files

**AI Prompt for Function Extraction:**
```
Analyze this Flutter service file and extract all functions longer than 30 lines:

Rules:
1. Each function must do exactly ONE thing
2. Extract complex conditions to named boolean methods
3. Extract loops to separate methods with descriptive names
4. No nested functions beyond 2 levels
5. Create helper classes for related operations

For each long function:
1. Identify its responsibilities
2. Break into smaller functions
3. Suggest descriptive names
4. Show the refactored version
5. Add comprehensive documentation

Also add ABOUTME comment:
// ABOUTME: Brief description of what this file does
// ABOUTME: Second line with key responsibility
```

## Phase 3: Async Pattern Revolution (Week 3)

### 3.1 Future.delayed Genocide

**Checklist:**
- [ ] Find all Future.delayed usages (target: 38 → 0)
- [ ] Replace with proper async patterns
- [ ] Create AsyncUtils for common patterns
- [ ] Document each replacement pattern
- [ ] Add analyzer rule to ban Future.delayed

**AI Prompt for Async Migration:**
```
Find and eliminate all Future.delayed usage in this codebase. This is an anti-pattern that must be completely removed.

For each Future.delayed found:
1. Identify why the delay was added
2. Determine the proper async pattern to use instead:
   - Completer for operation completion
   - Stream for event sequences
   - State change listeners
   - Platform channel callbacks
3. Generate the replacement code
4. Add tests to verify behavior

Common patterns to use:
- Completer<T> for single async operations
- StreamController for event streams
- ChangeNotifier for state changes
- Future.wait for parallel operations
- AsyncUtils.waitForCondition for polling

Generate AsyncUtils class with helpers for common scenarios.
```

### 3.2 WebSocket Handler Rewrite

**Checklist:**
- [ ] Remove all timing-based reconnection logic
- [ ] Implement proper event-driven reconnection
- [ ] Add exponential backoff
- [ ] Create comprehensive connection state machine
- [ ] Test all edge cases

**AI Prompt for WebSocket Refactoring:**
```
Rewrite WebSocket handling to remove all timing hacks and implement proper event-driven patterns:

Current issues:
- Uses Future.delayed for reconnection
- No proper state management
- Race conditions in connection handling
- No exponential backoff

Requirements:
1. Implement complete connection state machine
2. Event-driven reconnection with exponential backoff
3. Proper error handling and recovery
4. Connection pooling for multiple relays
5. Health checking without delays

Generate:
1. Connection state enum and state machine
2. WebSocketManager with proper lifecycle
3. Reconnection strategy with backoff
4. Event stream for connection changes
5. Comprehensive tests for all states
```

## Phase 4: Provider Architecture Rewrite (Week 4)

### 4.1 Complete Provider Restructuring

**Checklist:**
- [ ] Delete main.dart provider setup (60+ providers)
- [ ] Create feature modules with focused providers
- [ ] Implement Riverpod throughout
- [ ] Add provider dependency visualization
- [ ] Lazy load all non-critical providers

**AI Prompt for Provider Migration:**
```
Migrate from 60+ providers in main.dart to modular Riverpod architecture:

Current state: All providers initialized in main.dart
Target state: Feature-based modules with lazy loading

For each feature module create:
1. feature_providers.dart with all providers for that feature
2. Proper scoping and lifecycle management
3. Lazy initialization where possible
4. Clear dependency graph

Features to modularize:
- Authentication (5-8 providers)
- Video (15-20 providers)
- Social (8-10 providers)
- Nostr (10-12 providers)
- Core (5-10 providers)

Show how to:
1. Structure each module
2. Handle inter-module dependencies
3. Implement lazy loading
4. Test provider initialization
```

### 4.2 Startup Performance Overhaul

**Checklist:**
- [ ] Profile current startup time
- [ ] Identify initialization bottlenecks
- [ ] Implement progressive initialization
- [ ] Defer non-critical services
- [ ] Target: 50% faster startup

**AI Prompt for Startup Optimization:**
```
Optimize Flutter app startup from 3.2s to under 1.6s:

Analyze startup and:
1. Identify what's initialized on startup
2. Categorize as critical vs deferrable
3. Implement progressive initialization
4. Create startup sequence coordinator
5. Add startup performance monitoring

Critical for startup:
- Basic UI rendering
- Auth state check
- Initial navigation

Can be deferred:
- Video processing
- Analytics
- Social features
- Non-visible content

Generate implementation with timing measurements.
```

## Phase 5: Testing Blitz (Week 5)

### 5.1 Test Infrastructure Setup

**Checklist:**
- [ ] Configure flutter_test with coverage
- [ ] Set up integration test framework
- [ ] Create test data builders (no mocks!)
- [ ] Add pre-commit test execution
- [ ] Configure 80% coverage requirement

**AI Prompt for Test Setup:**
```
Set up comprehensive Flutter testing infrastructure for pre-launch app:

Requirements:
1. Unit tests for all services (90% coverage)
2. Widget tests for all UI (80% coverage)
3. Integration tests for critical flows
4. NO MOCKS - only real implementations
5. Test data builders for all entities

Generate:
1. Test configuration files
2. Base test classes with helpers
3. Test data builder pattern implementation
4. In-memory service implementations for tests
5. GitHub Actions workflow for test execution

Critical flows needing integration tests:
- Video recording and upload
- Authentication flow
- Nostr event publishing
- Video feed loading
```

### 5.2 Mass Test Generation

**Checklist:**
- [ ] Generate tests for all services
- [ ] Generate widget tests for all screens
- [ ] Create integration test suite
- [ ] Add performance benchmarks
- [ ] Document test patterns

**AI Prompt for Test Generation:**
```
Generate comprehensive tests for this Flutter service following TDD principles:

For each public method:
1. Test happy path
2. Test error cases
3. Test edge cases
4. Test concurrent access
5. Test resource cleanup

Test patterns to follow:
- Arrange-Act-Assert
- One assertion per test
- Descriptive test names
- No mocks, only real implementations
- Test behavior, not implementation

Generate:
1. Complete test file
2. Test data builders needed
3. In-memory implementations
4. Performance benchmarks
5. Test documentation
```

## Phase 6: Documentation & Cleanup (Week 6)

### 6.1 Mass Documentation Generation

**Checklist:**
- [ ] Add ABOUTME to all files
- [ ] Generate Dartdoc for all public APIs
- [ ] Create architecture diagrams
- [ ] Document all design decisions
- [ ] Generate API documentation

**AI Prompt for Documentation:**
```
Generate comprehensive documentation for Flutter codebase:

For each file:
1. Add ABOUTME comment (2 lines starting with "ABOUTME: ")
2. Add Dartdoc to all public methods
3. Document parameters and return values
4. Add usage examples where helpful
5. Document any gotchas or warnings

Additional documentation:
1. Architecture overview diagram
2. Feature interaction diagram
3. Data flow documentation
4. State management guide
5. Testing guide

Use mermaid diagrams where applicable.
```

### 6.2 Final Cleanup Sweep

**Checklist:**
- [ ] Remove all TODO comments (resolve or track)
- [ ] Delete all commented code
- [ ] Remove unused imports
- [ ] Fix all analyzer warnings
- [ ] Ensure consistent formatting

**AI Prompt for Cleanup:**
```
Perform final cleanup sweep on Flutter codebase:

Tasks:
1. Find and resolve all TODO comments
2. Delete all commented-out code
3. Remove unused imports
4. Fix all analyzer warnings
5. Apply consistent formatting

For each TODO:
- Either implement it
- Or create a GitHub issue
- Then remove the TODO comment

Generate:
1. Script to find all issues
2. Cleanup automation where possible
3. Manual task list for remaining items
4. Validation script to ensure cleanliness
```

## Success Metrics (Aggressive Targets)

```
┌─────────────────────────────────────────────────┐
│        OpenVine Quality Metrics (6 weeks)       │
├─────────────────────────────────────────────────┤
│ Metric                  │ Before │ After │ Goal │
├─────────────────────────┼────────┼───────┼──────┤
│ Avg Function Length     │ 150+   │ 25    │ <30  │
│ Future.delayed Count    │ 38     │ 0     │ 0    │
│ Test Coverage          │ ~10%   │ 85%   │ 80%+ │
│ Root Provider Count    │ 60+    │ 0     │ 0    │
│ Module Provider Count   │ 0      │ 15-20 │ 20   │
│ Startup Time           │ 3.2s   │ 1.5s  │ <2s  │
│ Lines per File         │ 1300+  │ <200  │ 200  │
│ Code Duplication       │ High   │ 0%    │ <5%  │
└─────────────────────────┴────────┴───────┴──────┘
```

## Week-by-Week Execution Plan

### Week 1: Foundation & Restructuring
- Day 1-2: Complete directory restructuring
- Day 3-4: Mass rename operations
- Day 5: Quality gates and tooling

### Week 2: Service Destruction
- Day 1-2: VideoEventService decomposition
- Day 3-4: Other large service splits
- Day 5: Function extraction across codebase

### Week 3: Async Pattern Revolution
- Day 1-2: Future.delayed elimination
- Day 3-4: WebSocket rewrite
- Day 5: Stream-based architectures

### Week 4: Provider Rewrite
- Day 1-2: Provider modularization
- Day 3-4: Riverpod migration
- Day 5: Startup optimization

### Week 5: Testing Blitz
- Day 1-2: Test infrastructure
- Day 3-4: Service test generation
- Day 5: Integration tests

### Week 6: Documentation & Polish
- Day 1-2: Mass documentation
- Day 3-4: Final cleanup
- Day 5: Performance validation

## Risk Mitigation

Since this is pre-launch with no users:
1. **No Feature Flags Needed** - Direct replacement
2. **No Migration Path** - Clean break
3. **No Backward Compatibility** - Fresh start
4. **Aggressive Timeline** - No gradual rollout

## First Day Actions

1. **Hour 1-2**: Run directory restructuring script
2. **Hour 3-4**: Update all imports
3. **Hour 5-6**: Configure analysis_options.yaml
4. **Hour 7-8**: Set up pre-commit hooks

## AI Prompt for Daily Progress

```
Daily refactoring progress check:

1. What files were refactored today?
2. Which patterns were eliminated?
3. What tests were added?
4. Current metrics:
   - Future.delayed count
   - Average function length
   - Test coverage
   - Files over 200 lines

Generate:
1. Progress summary
2. Tomorrow's priority list
3. Blockers to address
4. Metrics dashboard update
```

This aggressive plan leverages the pre-launch status to perform a complete transformation in 6 weeks rather than 12, with no compatibility concerns and maximum efficiency.
# TDD Feature Flags Plan for OpenVine

## Test-First Development Order

### Phase 1: Core Domain Tests (Start Here)

#### 1.1 Feature Flag Enum Tests
```dart
// test/core/feature_flag_test.dart
group('FeatureFlag enum', () {
  test('should have display names', () {
    expect(FeatureFlag.newCameraUI.displayName, equals('New Camera UI'));
  });
  
  test('should have descriptions', () {
    expect(FeatureFlag.newCameraUI.description, isNotEmpty);
  });
  
  test('should have unique names', () {
    final names = FeatureFlag.values.map((f) => f.name).toSet();
    expect(names.length, equals(FeatureFlag.values.length));
  });
});
```

#### 1.2 Feature Flag State Tests
```dart
// test/models/feature_flag_state_test.dart
group('FeatureFlagState', () {
  test('should store flag values', () {
    final state = FeatureFlagState({
      FeatureFlag.newCameraUI: true,
      FeatureFlag.enhancedVideoPlayer: false,
    });
    
    expect(state.isEnabled(FeatureFlag.newCameraUI), isTrue);
    expect(state.isEnabled(FeatureFlag.enhancedVideoPlayer), isFalse);
  });
  
  test('should return false for undefined flags', () {
    final state = FeatureFlagState({});
    expect(state.isEnabled(FeatureFlag.newCameraUI), isFalse);
  });
  
  test('should be immutable', () {
    final state1 = FeatureFlagState({});
    final state2 = state1.copyWith(FeatureFlag.newCameraUI, true);
    
    expect(state1.isEnabled(FeatureFlag.newCameraUI), isFalse);
    expect(state2.isEnabled(FeatureFlag.newCameraUI), isTrue);
  });
});
```

### Phase 2: Service Layer Tests

#### 2.1 Build Configuration Tests
```dart
// test/services/build_config_test.dart
group('BuildConfiguration', () {
  test('should read from environment variables', () {
    // This tests compile-time constants
    const config = BuildConfiguration();
    
    expect(
      config.getDefault(FeatureFlag.debugTools),
      equals(bool.fromEnvironment('FF_DEBUG_TOOLS', defaultValue: true)),
    );
  });
  
  test('should provide defaults when env vars not set', () {
    const config = BuildConfiguration();
    
    // When FF_NEW_CAMERA_UI is not set
    expect(config.getDefault(FeatureFlag.newCameraUI), isFalse);
  });
});
```

#### 2.2 Feature Flag Service Tests
```dart
// test/services/feature_flag_service_test.dart
group('FeatureFlagService', () {
  late MockSharedPreferences mockPrefs;
  late FeatureFlagService service;
  
  setUp(() {
    mockPrefs = MockSharedPreferences();
    service = FeatureFlagService(mockPrefs, BuildConfiguration());
  });
  
  group('initialization', () {
    test('should load saved flags from preferences', () async {
      when(mockPrefs.getBool('ff_newCameraUI')).thenReturn(true);
      when(mockPrefs.getBool('ff_enhancedVideoPlayer')).thenReturn(false);
      
      await service.initialize();
      
      expect(service.isEnabled(FeatureFlag.newCameraUI), isTrue);
      expect(service.isEnabled(FeatureFlag.enhancedVideoPlayer), isFalse);
    });
    
    test('should use build defaults when no saved preference', () async {
      when(mockPrefs.getBool(any)).thenReturn(null);
      
      await service.initialize();
      
      expect(
        service.isEnabled(FeatureFlag.debugTools),
        equals(BuildConfiguration().getDefault(FeatureFlag.debugTools)),
      );
    });
    
    test('should prefer user settings over build defaults', () async {
      // Build default is false, user set to true
      when(mockPrefs.getBool('ff_newCameraUI')).thenReturn(true);
      
      await service.initialize();
      
      expect(service.isEnabled(FeatureFlag.newCameraUI), isTrue);
    });
  });
  
  group('flag management', () {
    test('should save flag changes to preferences', () async {
      await service.setFlag(FeatureFlag.newCameraUI, true);
      
      verify(mockPrefs.setBool('ff_newCameraUI', true)).called(1);
    });
    
    test('should notify listeners on flag change', () async {
      var notified = false;
      service.addListener(() => notified = true);
      
      await service.setFlag(FeatureFlag.newCameraUI, true);
      
      expect(notified, isTrue);
    });
    
    test('should reset flag to build default', () async {
      await service.setFlag(FeatureFlag.newCameraUI, true);
      await service.resetFlag(FeatureFlag.newCameraUI);
      
      verify(mockPrefs.remove('ff_newCameraUI')).called(1);
      expect(
        service.isEnabled(FeatureFlag.newCameraUI),
        equals(BuildConfiguration().getDefault(FeatureFlag.newCameraUI)),
      );
    });
    
    test('should reset all flags', () async {
      await service.setFlag(FeatureFlag.newCameraUI, true);
      await service.setFlag(FeatureFlag.enhancedVideoPlayer, true);
      
      await service.resetAllFlags();
      
      for (final flag in FeatureFlag.values) {
        verify(mockPrefs.remove('ff_${flag.name}')).called(1);
      }
    });
  });
  
  group('state queries', () {
    test('should identify user overrides', () async {
      when(mockPrefs.containsKey('ff_newCameraUI')).thenReturn(true);
      when(mockPrefs.containsKey('ff_enhancedVideoPlayer')).thenReturn(false);
      
      expect(service.hasUserOverride(FeatureFlag.newCameraUI), isTrue);
      expect(service.hasUserOverride(FeatureFlag.enhancedVideoPlayer), isFalse);
    });
    
    test('should provide flag metadata', () {
      final metadata = service.getFlagMetadata(FeatureFlag.newCameraUI);
      
      expect(metadata.flag, equals(FeatureFlag.newCameraUI));
      expect(metadata.isEnabled, isNotNull);
      expect(metadata.hasUserOverride, isNotNull);
      expect(metadata.buildDefault, isNotNull);
    });
  });
});
```

### Phase 3: Provider Tests

#### 3.1 Riverpod Provider Tests
```dart
// test/providers/feature_flag_provider_test.dart
group('FeatureFlagProvider', () {
  test('should provide service instance', () async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(MockSharedPreferences()),
      ],
    );
    
    final service = container.read(featureFlagServiceProvider);
    expect(service, isA<FeatureFlagService>());
  });
  
  test('should provide flag state', () async {
    final container = ProviderContainer();
    
    final state = container.read(featureFlagStateProvider);
    expect(state, isA<Map<FeatureFlag, bool>>());
  });
  
  test('should provide individual flag checks', () async {
    final container = ProviderContainer();
    final service = container.read(featureFlagServiceProvider);
    
    await service.setFlag(FeatureFlag.newCameraUI, true);
    
    final isEnabled = container.read(
      isFeatureEnabledProvider(FeatureFlag.newCameraUI)
    );
    expect(isEnabled, isTrue);
  });
});
```

### Phase 4: Widget Tests

#### 4.1 FeatureFlagWidget Tests
```dart
// test/widgets/feature_flag_widget_test.dart
group('FeatureFlagWidget', () {
  testWidgets('should show child when flag enabled', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          featureFlagStateProvider.overrideWithValue({
            FeatureFlag.newCameraUI: true,
          }),
        ],
        child: MaterialApp(
          home: FeatureFlagWidget(
            flag: FeatureFlag.newCameraUI,
            child: Text('Enabled'),
          ),
        ),
      ),
    );
    
    expect(find.text('Enabled'), findsOneWidget);
  });
  
  testWidgets('should show fallback when flag disabled', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          featureFlagStateProvider.overrideWithValue({
            FeatureFlag.newCameraUI: false,
          }),
        ],
        child: MaterialApp(
          home: FeatureFlagWidget(
            flag: FeatureFlag.newCameraUI,
            child: Text('Enabled'),
            disabled: Text('Disabled'),
          ),
        ),
      ),
    );
    
    expect(find.text('Disabled'), findsOneWidget);
    expect(find.text('Enabled'), findsNothing);
  });
  
  testWidgets('should show nothing when flag disabled and no fallback', 
    (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          featureFlagStateProvider.overrideWithValue({
            FeatureFlag.newCameraUI: false,
          }),
        ],
        child: MaterialApp(
          home: FeatureFlagWidget(
            flag: FeatureFlag.newCameraUI,
            child: Container(height: 100, width: 100),
          ),
        ),
      ),
    );
    
    expect(find.byType(Container), findsNothing);
  });
});
```

#### 4.2 Feature Flag Settings Screen Tests
```dart
// test/screens/feature_flag_screen_test.dart
group('FeatureFlagScreen', () {
  testWidgets('should display all flags', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: FeatureFlagScreen()),
      ),
    );
    
    for (final flag in FeatureFlag.values) {
      expect(find.text(flag.displayName), findsOneWidget);
      expect(find.text(flag.description), findsOneWidget);
    }
  });
  
  testWidgets('should toggle flags', (tester) async {
    final mockService = MockFeatureFlagService();
    
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          featureFlagServiceProvider.overrideWithValue(mockService),
        ],
        child: MaterialApp(home: FeatureFlagScreen()),
      ),
    );
    
    await tester.tap(find.byType(Switch).first);
    
    verify(mockService.setFlag(any, any)).called(1);
  });
  
  testWidgets('should show override indicators', (tester) async {
    final mockService = MockFeatureFlagService();
    when(mockService.hasUserOverride(FeatureFlag.newCameraUI))
      .thenReturn(true);
    
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          featureFlagServiceProvider.overrideWithValue(mockService),
        ],
        child: MaterialApp(home: FeatureFlagScreen()),
      ),
    );
    
    final switches = tester.widgetList<Switch>(find.byType(Switch));
    final firstSwitch = switches.first;
    
    expect(firstSwitch.activeColor, equals(Colors.blue));
  });
  
  testWidgets('should reset all flags on button press', (tester) async {
    final mockService = MockFeatureFlagService();
    
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          featureFlagServiceProvider.overrideWithValue(mockService),
        ],
        child: MaterialApp(home: FeatureFlagScreen()),
      ),
    );
    
    await tester.tap(find.byIcon(Icons.restore));
    
    verify(mockService.resetAllFlags()).called(1);
  });
});
```

### Phase 5: Integration Tests

#### 5.1 End-to-End Tests
```dart
// test/integration/feature_flag_integration_test.dart
group('Feature Flag Integration', () {
  testWidgets('should persist flag changes across app restarts', 
    (tester) async {
    final prefs = await SharedPreferences.getInstance();
    
    // First app launch
    await tester.pumpWidget(MyApp());
    
    // Navigate to settings
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    
    // Enable a flag
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    
    // Verify saved
    expect(prefs.getBool('ff_newCameraUI'), isTrue);
    
    // Restart app
    await tester.pumpWidget(MyApp());
    
    // Verify flag still enabled
    final service = ProviderScope.containerOf(
      tester.element(find.byType(MyApp))
    ).read(featureFlagServiceProvider);
    
    expect(service.isEnabled(FeatureFlag.newCameraUI), isTrue);
  });
});
```

## Implementation Order (TDD Style)

### Day 1: Core Domain
1. Write failing tests for FeatureFlag enum
2. Implement minimal FeatureFlag enum
3. Write failing tests for FeatureFlagState
4. Implement FeatureFlagState
5. Refactor for clarity

### Day 2: Service Layer  
1. Write failing tests for BuildConfiguration
2. Implement BuildConfiguration
3. Write failing tests for FeatureFlagService
4. Implement FeatureFlagService incrementally
5. Refactor service design

### Day 3: Providers & UI
1. Write failing provider tests
2. Implement providers
3. Write failing widget tests
4. Implement FeatureFlagWidget
5. Write failing screen tests
6. Implement settings screen

### Day 4: Integration & Polish
1. Write integration tests
2. Fix integration issues
3. Add edge case tests
4. Performance optimization
5. Documentation

## Test Coverage Goals

- **Unit Tests**: 95%+ coverage on business logic
- **Widget Tests**: All UI components tested
- **Integration Tests**: Critical user flows
- **Edge Cases**: Null states, errors, race conditions

## Benefits of TDD Approach

1. **Design emerges from usage** - Tests show how API should work
2. **No dead code** - Only write what tests require
3. **Refactoring confidence** - Tests ensure nothing breaks
4. **Documentation** - Tests demonstrate usage
5. **Regression prevention** - Catches bugs early

## Architecture Overview

### Feature Flag System Design

```
┌─────────────────────────────────────────────────────────┐
│                    FEATURE FLAG SYSTEM                 │
├─────────────────────┬───────────────────────────────────┤
│   LOCAL LAYER       │         REMOTE LAYER              │
│                     │                                   │
│ • FeatureFlag enum  │ • Cloudflare Workers API          │
│ • Riverpod Provider │ • User targeting/rollouts         │
│ • Local storage     │ • Real-time updates               │
│ • Developer tools   │ • Analytics integration           │
└─────────────────────┴───────────────────────────────────┘
                              │
                    ┌─────────────────┐
                    │  UI COMPONENTS  │
                    │                 │
                    │ • Conditional   │
                    │   rendering     │
                    │ • A/B testing   │
                    │ • Feature       │
                    │   rollouts      │
                    └─────────────────┘
```

### File Structure
```
lib/features/feature_flags/
├── models/
│   ├── feature_flag.dart           # Enum definitions
│   ├── feature_flag_state.dart     # Immutable state
│   └── flag_metadata.dart          # Flag information
├── services/
│   ├── build_configuration.dart    # Compile-time defaults
│   ├── feature_flag_service.dart   # Core flag logic
│   └── remote_config_service.dart  # API communication
├── providers/
│   ├── feature_flag_providers.dart # Riverpod providers
│   └── shared_preferences_provider.dart # Dependencies
├── widgets/
│   ├── feature_flag_widget.dart    # Conditional rendering
│   └── feature_flag_screen.dart    # Settings UI
└── constants/
    └── feature_flags.dart          # Flag definitions
```

### Key API Design
```dart
enum FeatureFlag {
  newCameraUI('New Camera UI', 'Enhanced camera interface with new controls'),
  experimentalVideoPlayer('Experimental Video Player', 'New video playback engine'),
  enhancedAnalytics('Enhanced Analytics', 'Detailed usage tracking'),
  newProfileLayout('New Profile Layout', 'Redesigned user profile screen'),
  livestreamingBeta('Livestreaming Beta', 'Live video streaming feature'),
  debugTools('Debug Tools', 'Developer debugging utilities');

  const FeatureFlag(this.displayName, this.description);
  final String displayName;
  final String description;
}

class FeatureFlagService extends ChangeNotifier {
  bool isEnabled(FeatureFlag flag);
  Future<void> setFlag(FeatureFlag flag, bool value);
  Future<void> resetFlag(FeatureFlag flag);
  Future<void> resetAllFlags();
  bool hasUserOverride(FeatureFlag flag);
  FlagMetadata getFlagMetadata(FeatureFlag flag);
}

class FeatureFlagWidget extends ConsumerWidget {
  const FeatureFlagWidget({
    required this.flag,
    required this.child,
    this.disabled,
    super.key,
  });
  
  final FeatureFlag flag;
  final Widget child;
  final Widget? disabled;
}
```

## Implementation Phases

### Phase 1: Foundation (Local Flags Only)
**Week 1**: Core infrastructure setup
- Type-safe FeatureFlag enum with metadata
- FeatureFlagService with SharedPreferences
- Riverpod provider integration
- Basic conditional rendering widget

### Phase 2: UI Integration
**Week 2**: Component integration
- FeatureFlagWidget for conditional rendering
- Settings screen for flag management
- Visual indicators for user overrides
- Testing utilities and mocks

### Phase 3: Remote Configuration
**Week 3**: Dynamic flag management
- Cloudflare Workers API design
- Remote config fetching service
- Local caching with fallbacks
- User targeting capabilities

### Phase 4: Analytics & Monitoring
**Week 4**: Feature usage measurement
- Analytics integration
- A/B test measurement
- Performance monitoring
- Rollback mechanisms

### Phase 5: Developer Experience
**Week 5**: Development tools
- Enhanced debug panel
- Documentation and guidelines
- Performance optimization
- Final testing and polish

## Integration with OpenVine

### Existing Architecture Integration
- **Riverpod State Management**: Seamless integration with existing providers
- **Analytics System**: Hooks into existing analytics worker
- **Cloudflare Workers**: Extends current backend infrastructure
- **SharedPreferences**: Uses existing local storage patterns

### Initial Feature Flags for OpenVine
1. **newCameraUI** - Camera screen improvements and experiments
2. **experimentalVideoPlayer** - Video playback engine testing
3. **enhancedAnalytics** - Advanced usage tracking features
4. **newProfileLayout** - Profile screen redesign experiments
5. **livestreamingBeta** - Live streaming feature development
6. **debugTools** - Always enabled in debug builds for development

### Performance Considerations
- **Flag Check Overhead**: Target <1ms per UI build
- **Memory Usage**: Minimal state footprint
- **Startup Impact**: Lazy initialization of remote config
- **Battery Life**: Efficient caching to minimize network requests

## Success Metrics

| Phase | Metric | Target |
|-------|--------|--------|
| 1 | Flag checking overhead | <1ms per UI build |
| 2 | Developer adoption | 90%+ for new features |
| 3 | Remote update speed | <30 seconds propagation |
| 4 | Analytics availability | <24 hours for usage data |
| 5 | Testing efficiency | <30 seconds to test any combination |

## Risk Mitigation

### Performance Risk
- **Mitigation**: Benchmark flag checking overhead early
- **Monitoring**: Continuous performance measurement
- **Fallback**: Local-only mode if remote config impacts performance

### Complexity Risk
- **Mitigation**: Start with minimal viable implementation
- **Approach**: Incremental feature addition
- **Validation**: Regular developer feedback sessions

### Integration Risk
- **Mitigation**: Test with existing Riverpod architecture early
- **Approach**: Single component proof of concept first
- **Fallback**: Local flags work independently of remote config

### Adoption Risk
- **Mitigation**: Build debug tools in parallel with core functionality
- **Support**: Clear documentation and examples
- **Training**: Developer workshops and code reviews

This TDD approach ensures that the feature flag system is built with solid foundations, comprehensive test coverage, and clear API design that emerges naturally from usage patterns defined in tests.
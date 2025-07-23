// ABOUTME: Comprehensive test for ShareVideoMenu Riverpod migration
// ABOUTME: Tests widget builds with Riverpod providers and service interactions work correctly

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:openvine/models/video_event.dart';
import 'package:openvine/services/content_deletion_service.dart';
import 'package:openvine/services/content_reporting_service.dart';
import 'package:openvine/services/curated_list_service.dart';
import 'package:openvine/services/nostr_service_interface.dart';
import 'package:openvine/services/social_service.dart';
import 'package:openvine/services/user_profile_service.dart';
import 'package:openvine/services/video_sharing_service.dart';
import 'package:openvine/widgets/share_video_menu.dart';
import 'package:openvine/providers/app_providers.dart';

// Generate mocks for services
@GenerateMocks([
  INostrService,
  ContentDeletionService,
  ContentReportingService,
  CuratedListService,
  SocialService,
  UserProfileService,
  VideoSharingService,
])
import 'share_video_menu_riverpod_test.mocks.dart';

void main() {
  group('ShareVideoMenu Riverpod Migration Tests', () {
    // Test video event for consistent testing
    final now = DateTime.now();
    final testVideo = VideoEvent(
      id: 'test_video_id',
      pubkey: 'test_pubkey_123',
      createdAt: now.millisecondsSinceEpoch,
      content: 'Test video content',
      timestamp: now,
      title: 'Test Video Title',
    );

    // Mock services
    late MockINostrService mockNostrService;
    late MockContentDeletionService mockContentDeletionService;
    late MockContentReportingService mockContentReportingService;
    late MockCuratedListService mockCuratedListService;
    late MockSocialService mockSocialService;
    late MockUserProfileService mockUserProfileService;
    late MockVideoSharingService mockVideoSharingService;

    setUp(() {
      // Initialize mocks
      mockNostrService = MockINostrService();
      mockContentDeletionService = MockContentDeletionService();
      mockContentReportingService = MockContentReportingService();
      mockCuratedListService = MockCuratedListService();
      mockSocialService = MockSocialService();
      mockUserProfileService = MockUserProfileService();
      mockVideoSharingService = MockVideoSharingService();

      // Setup mock defaults
      when(mockNostrService.publicKey).thenReturn('test_user_pubkey');
      when(mockContentReportingService.hasBeenReported(any)).thenReturn(false);
      when(mockCuratedListService.getDefaultList()).thenReturn(null);
      when(mockCuratedListService.isVideoInDefaultList(any)).thenReturn(false);
      when(mockCuratedListService.lists).thenReturn([]);
      when(mockSocialService.followingPubkeys).thenReturn(<String>[]);
    });

    testWidgets('ShareVideoMenu builds with Riverpod providers', (tester) async {
      // This test should FAIL initially because ShareVideoMenu is still using Provider
      final container = ProviderContainer(
        overrides: [
          // Override all providers with mocks
          nostrServiceProvider.overrideWithValue(mockNostrService),
          contentDeletionServiceProvider.overrideWithValue(mockContentDeletionService),
          contentReportingServiceProvider.overrideWithValue(mockContentReportingService),
          curatedListServiceProvider.overrideWithValue(mockCuratedListService),
          socialServiceProvider.overrideWithValue(mockSocialService),
          userProfileServiceProvider.overrideWithValue(mockUserProfileService),
          videoSharingServiceProvider.overrideWithValue(mockVideoSharingService),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: ShareVideoMenu(video: testVideo),
            ),
          ),
        ),
      );

      // Should find the share video menu
      expect(find.text('Share Video'), findsOneWidget);
      expect(find.text('Test Video Title'), findsOneWidget);
      expect(find.text('Share With'), findsOneWidget);
      expect(find.text('Add to List'), findsOneWidget);
      expect(find.text('Content Actions'), findsOneWidget);
    });

    testWidgets('INostrService access through ref.read() works', (tester) async {
      // Setup user as content owner to trigger delete section
      when(mockNostrService.publicKey).thenReturn('test_pubkey_123');

      final container = ProviderContainer(
        overrides: [
          nostrServiceProvider.overrideWithValue(mockNostrService),
          contentDeletionServiceProvider.overrideWithValue(mockContentDeletionService),
          contentReportingServiceProvider.overrideWithValue(mockContentReportingService),
          curatedListServiceProvider.overrideWithValue(mockCuratedListService),
          socialServiceProvider.overrideWithValue(mockSocialService),
          userProfileServiceProvider.overrideWithValue(mockUserProfileService),
          videoSharingServiceProvider.overrideWithValue(mockVideoSharingService),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: ShareVideoMenu(video: testVideo),
            ),
          ),
        ),
      );

      // Should show delete section for own content
      expect(find.text('Manage Content'), findsOneWidget);
      expect(find.text('Delete Video'), findsOneWidget);
    });

    testWidgets('ContentReportingService Consumer integration works', (tester) async {
      // Test that the Consumer<ContentReportingService> is properly converted
      when(mockContentReportingService.hasBeenReported('test_video_id')).thenReturn(true);

      final container = ProviderContainer(
        overrides: [
          nostrServiceProvider.overrideWithValue(mockNostrService),
          contentDeletionServiceProvider.overrideWithValue(mockContentDeletionService),
          contentReportingServiceProvider.overrideWithValue(mockContentReportingService),
          curatedListServiceProvider.overrideWithValue(mockCuratedListService),
          socialServiceProvider.overrideWithValue(mockSocialService),
          userProfileServiceProvider.overrideWithValue(mockUserProfileService),
          videoSharingServiceProvider.overrideWithValue(mockVideoSharingService),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: ShareVideoMenu(video: testVideo),
            ),
          ),
        ),
      );

      // Should show "Already Reported" for reported content
      expect(find.text('Already Reported'), findsOneWidget);
      expect(find.text('You have reported this content'), findsOneWidget);
    });

    testWidgets('CuratedListService Consumer integration works', (tester) async {
      // Mock list service with default list
      final now = DateTime.now();
      final mockDefaultList = CuratedList(
        id: CuratedListService.defaultListId,
        name: 'My List',
        description: 'My default list',
        isPublic: true,
        videoEventIds: ['test_video_id'],
        createdAt: now,
        updatedAt: now,
      );

      when(mockCuratedListService.getDefaultList()).thenReturn(mockDefaultList);
      when(mockCuratedListService.isVideoInDefaultList('test_video_id')).thenReturn(true);
      when(mockCuratedListService.lists).thenReturn([mockDefaultList]);

      final container = ProviderContainer(
        overrides: [
          nostrServiceProvider.overrideWithValue(mockNostrService),
          contentDeletionServiceProvider.overrideWithValue(mockContentDeletionService),
          contentReportingServiceProvider.overrideWithValue(mockContentReportingService),
          curatedListServiceProvider.overrideWithValue(mockCuratedListService),
          socialServiceProvider.overrideWithValue(mockSocialService),
          userProfileServiceProvider.overrideWithValue(mockUserProfileService),
          videoSharingServiceProvider.overrideWithValue(mockVideoSharingService),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: ShareVideoMenu(video: testVideo),
            ),
          ),
        ),
      );

      // Should show "Remove from My List" for videos in default list
      expect(find.text('Remove from My List'), findsOneWidget);
    });

    testWidgets('Video sharing functionality works with ref.read()', (tester) async {
      when(mockVideoSharingService.generateShareUrl(any)).thenReturn('https://test.url');

      final container = ProviderContainer(
        overrides: [
          nostrServiceProvider.overrideWithValue(mockNostrService),
          contentDeletionServiceProvider.overrideWithValue(mockContentDeletionService),
          contentReportingServiceProvider.overrideWithValue(mockContentReportingService),
          curatedListServiceProvider.overrideWithValue(mockCuratedListService),
          socialServiceProvider.overrideWithValue(mockSocialService),
          userProfileServiceProvider.overrideWithValue(mockUserProfileService),
          videoSharingServiceProvider.overrideWithValue(mockVideoSharingService),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: ShareVideoMenu(video: testVideo),
            ),
          ),
        ),
      );

      // Tap copy link button
      await tester.tap(find.text('Copy Link'));
      await tester.pump();

      // Verify service was called
      verify(mockVideoSharingService.generateShareUrl(testVideo)).called(1);
    });

    testWidgets('Send to user dialog uses Riverpod providers', (tester) async {
      // Mock social service for user contacts
      when(mockSocialService.followingPubkeys).thenReturn(['friend_pubkey']);
      when(mockUserProfileService.hasProfile(any)).thenReturn(false);
      when(mockUserProfileService.getCachedProfile(any)).thenReturn(null);

      final container = ProviderContainer(
        overrides: [
          nostrServiceProvider.overrideWithValue(mockNostrService),
          contentDeletionServiceProvider.overrideWithValue(mockContentDeletionService),
          contentReportingServiceProvider.overrideWithValue(mockContentReportingService),
          curatedListServiceProvider.overrideWithValue(mockCuratedListService),
          socialServiceProvider.overrideWithValue(mockSocialService),
          userProfileServiceProvider.overrideWithValue(mockUserProfileService),
          videoSharingServiceProvider.overrideWithValue(mockVideoSharingService),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: ShareVideoMenu(video: testVideo),
            ),
          ),
        ),
      );

      // Tap "Send to Viner" button
      await tester.tap(find.text('Send to Viner'));
      await tester.pumpAndSettle();

      // Should show dialog
      expect(find.text('Send to Viner'), findsWidgets);
      expect(find.text('Your Contacts'), findsOneWidget);
    });

    group('Dialog Classes Riverpod Migration', () {
      testWidgets('_CreateListDialog uses ref.read() for CuratedListService', (tester) async {
        final container = ProviderContainer(
          overrides: [
            curatedListServiceProvider.overrideWithValue(mockCuratedListService),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => const CreateListDialogWrapper(),
                    ),
                    child: const Text('Show Dialog'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Create New List'), findsOneWidget);
        expect(find.text('List Name'), findsOneWidget);
      });

      testWidgets('_SelectListDialog Consumer conversion works', (tester) async {
        when(mockCuratedListService.lists).thenReturn([]);

        final container = ProviderContainer(
          overrides: [
            curatedListServiceProvider.overrideWithValue(mockCuratedListService),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => const SelectListDialogWrapper(),
                    ),
                    child: const Text('Show Dialog'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Add to List'), findsOneWidget);
      });

      testWidgets('_ReportContentDialog uses ref.read() for ContentReportingService', (tester) async {
        final container = ProviderContainer(
          overrides: [
            contentReportingServiceProvider.overrideWithValue(mockContentReportingService),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => const ReportContentDialogWrapper(),
                    ),
                    child: const Text('Show Dialog'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Report Content'), findsOneWidget);
        expect(find.text('Why are you reporting this content?'), findsOneWidget);
      });
    });
  });
}

// Wrapper classes for testing dialog widgets with dummy video data
class CreateListDialogWrapper extends StatelessWidget {
  const CreateListDialogWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final testVideo = VideoEvent(
      id: 'test_video_id',
      pubkey: 'test_pubkey',
      createdAt: now.millisecondsSinceEpoch,
      content: 'Test content',
      timestamp: now,
    );
    
    // This will fail initially because the dialog classes aren't converted yet
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: const Text('CreateListDialog placeholder'),
      ),
    );
  }
}

class SelectListDialogWrapper extends StatelessWidget {
  const SelectListDialogWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final testVideo = VideoEvent(
      id: 'test_video_id',
      pubkey: 'test_pubkey',
      createdAt: now.millisecondsSinceEpoch,
      content: 'Test content',
      timestamp: now,
    );
    
    // This will fail initially because the dialog classes aren't converted yet
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: const Text('SelectListDialog placeholder'),
      ),
    );
  }
}

class ReportContentDialogWrapper extends StatelessWidget {
  const ReportContentDialogWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final testVideo = VideoEvent(
      id: 'test_video_id',
      pubkey: 'test_pubkey',
      createdAt: now.millisecondsSinceEpoch,
      content: 'Test content',
      timestamp: now,
    );
    
    // This will fail initially because the dialog classes aren't converted yet
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: const Text('ReportContentDialog placeholder'),
      ),
    );
  }
}
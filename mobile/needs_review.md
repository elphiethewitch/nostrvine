# Complex Issues Requiring Review

## Test Infrastructure Issues
These files have structural problems that may require architectural decisions:

### Missing AuthState Model
- `test/builders/auth_state_builder.dart` - Trying to construct AuthState as class, but it's an enum
- `test/in_memory/in_memory_auth_service.dart` - Same issue
- Multiple test files reference non-existent AuthState constructor

**Decision needed**: Should AuthState be:
1. Keep as enum and create separate AuthData/AuthInfo class for test builders?
2. Convert to a class with static state values?
3. Remove these test files if they're obsolete?

### Generated Test Files (IDENTIFIED FOR REMOVAL)
- `test/generated/` directory contains placeholder tests with undefined methods
- These are clearly incomplete code generation artifacts causing 66+ undefined_method errors
- Files contain placeholder methods like `someMethodThatFails()` that don't exist

**Files to remove/disable**:
- `test/generated/auth_result_test.dart` - Placeholder test with non-existent methods
- `test/generated/auth_service_test.dart` - Same issue
- `test/generated/feed_screen_v2_test.dart` - Non-functional template
- `test/generated/video_event_service_test.dart` - Incomplete artifacts
- `test/generated/video_upload_integration_test.dart` - Template only

**Recommendation**: These should be deleted as they're non-functional test artifacts.

### Type Argument Issues
Most common warning (549 instances): `inference_failure_on_instance_creation`
- Example: `Future.delayed()` without type arguments
- Most are in test files with `Future.delayed(Duration(...))`

**Action**: Auto-fixable by adding `<void>` type parameter to Future.delayed calls
EOF < /dev/null
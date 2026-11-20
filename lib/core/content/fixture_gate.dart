import 'content_issue.dart';
import 'content_models.dart';

/// Build flag for device testing of a release APK while the book is still
/// FAKE content: `--dart-define=ALLOW_FIXTURE_IN_RELEASE=true`. The final
/// store build must NOT set it.
const allowFixtureInReleaseFlag =
    bool.fromEnvironment('ALLOW_FIXTURE_IN_RELEASE');

/// FAKE fixture content is allowed in debug/profile builds, and in release
/// only when the override flag is set explicitly.
bool fixtureAllowed({required bool release, required bool override}) =>
    !release || override;

/// Throws the standard `fixture-in-release` validation error when [manifest]
/// is FAKE content and the build does not allow it.
void enforceFixtureGate(ContentManifest manifest, {required bool allowed}) {
  if (manifest.fixture && !allowed) {
    throw ContentValidationException(ValidationReport(const [
      ContentIssue(
        severity: IssueSeverity.error,
        code: 'fixture-in-release',
        file: 'manifest.json',
        path: 'fixture',
        message: 'FAKE fixture content must not be included in a release build.',
      ),
    ]));
  }
}

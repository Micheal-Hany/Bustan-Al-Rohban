import 'dart:math';

/// A random id that identifies this install to the rate limiter. It is NOT a
/// login and carries no personal data (SPEC 7.5).
String newInstallationId() {
  final r = Random.secure();
  final bytes = List<int>.generate(12, (_) => r.nextInt(256));
  return 'inst-${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
}

final installationIdPattern = RegExp(r'^[A-Za-z0-9_-]{16,64}$');

abstract class InstallationIdStore {
  Future<String> get();
}

class InMemoryInstallationIdStore implements InstallationIdStore {
  InMemoryInstallationIdStore([this._id]);

  String? _id;

  @override
  Future<String> get() async => _id ??= newInstallationId();
}

/// Supplies the app-attestation token for a request. The nonce of a real
/// Play Integrity token must be base64url(sha256(requestId)) (see
/// backend/docs/ABUSE_PROTECTION.md).
abstract class AttestationProvider {
  Future<String?> tokenFor(String requestId);
}

class NoAttestationProvider implements AttestationProvider {
  const NoAttestationProvider();

  @override
  Future<String?> tokenFor(String requestId) async => null;
}

/// Development/CI only: a fixed token for the backend's `test` mode.
class FixedAttestationProvider implements AttestationProvider {
  const FixedAttestationProvider(this.token);

  final String token;

  @override
  Future<String?> tokenFor(String requestId) async => token;
}

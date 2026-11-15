/// Where content files come from. Paths are relative to the content root
/// (for example `manifest.json` or `saints/saint-fake-one.json`).
abstract class ContentSource {
  Future<String> readString(String relativePath);
}

# Spike S1 - Arabic TTS feasibility

**Status:** code written, **no device findings yet**. Everything under "Findings" must be filled in from real devices; nothing here has been tested.
**Code:** `lib/spikes/tts/` (throwaway; revisit in Task 8). Debug-only screen "تجربة النطق (S1)" on the home screen.
**Owner decision needed after testing:** background audio (SPEC section 19, item 8).

## 1. One-time Android setup (needed on Android 11+)

`flutter create` generates `android/`; it is not in the repo. Add this inside `<manifest>` (next to `<application>`) in `android/app/src/main/AndroidManifest.xml`, otherwise the plugin may report no engines or voices:

```xml
<queries>
  <intent>
    <action android:name="android.intent.action.TTS_SERVICE" />
  </intent>
</queries>
```

## 2. How to run the checks (real device, debug build)

1. `flutter run`, open "تجربة النطق (S1)".
2. Tap "فحص الجهاز", then "نسخ التقرير" and paste the result into section 4.
3. Choose language `ar`, `ar-SA`, `ar-EG` and, if listed, an Arabic voice.
4. Long FAKE passage, **airplane mode on**: play to the end. Check that no chunk is skipped or repeated.
5. Pause, resume (the current chunk restarts, by design), change speed, stop.
6. "نص مشكول" vs "نص غير مشكول": compare pronunciation.
7. Lock the screen / switch app while playing and note what happens.

## 3. Design facts the spike relies on (to confirm on devices)

- Android TTS has no true pause. The player stops and replays the current chunk on resume.
- Chunk size defaults to 300 characters; the engine's own limit is reported by "max input length".
- Only our own stop produces "cancelled". The plugin's cancel callback is not used, because a late callback from an old utterance could end the next one.
- Position callbacks are mapped to offsets in the original text; whether the engine sends them is a finding.
- Background playback needs, at least: a foreground service, a media-playback service type declared in the manifest (Android 14+ rules), notification controls, and audio-focus handling. `flutter_tts` does not provide these by itself; a separate audio-service integration would be needed. **Not validated.**

## 4. Findings (fill in)

| Device / Android | TTS engine | Arabic voices | Offline works? | Position callbacks? | Notes |
|---|---|---|---|---|---|
| | | | | | |

Pronunciation of unvowelled text:

Chunking / order problems:

Pause/resume behavior:

Background (screen locked / app in background):

## 5. Recommendation (after testing)

- Offline Arabic TTS viable on target devices: ?
- Background audio in V1: ? (owner decides)
- Changes needed in Task 8: ?

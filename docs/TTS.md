# Text-to-speech (Task 8)

**Code:** `lib/features/audio/` (domain: `chunk_splitter`, `speech_plan`, `tts_engine`, `speech_cubit`; UI: `speech_bar`). Reader integration in `reader_screen.dart`.
**Status:** implemented and unit/widget tested with a fake engine. **Not yet verified on a real device** (see `docs/TTS_SPIKE.md`, findings still empty).

## Behaviour
- Reads the open section paragraph by paragraph. Long paragraphs are split into chunks of at most 300 characters (sentence ends preferred). Chunks never span paragraphs, so the position is always one paragraph ID.
- Play starts at the paragraph at the top of the screen. The spoken paragraph is highlighted and kept in view.
- **Pause/resume:** Android TTS has no real pause. Pause stops the engine; resume repeats the current chunk from its start. No chunk is skipped.
- **Speed:** 0.5x, 0.75x, 1x, 1.25x, 1.5x (button cycles). Changing speed while playing restarts the current chunk at the new speed. Not persisted yet.
- **Arabic voice check (first play):** `offline` (a voice reports it needs no network; badge shown), `onlineOnly` / `missing` (nothing is spoken; message explains how to install a voice; never silently switches to an online service), `unknown` (engine does not say; plays, no offline claim).
- An engine error shows a message and can be retried; an interruption leaves playback paused and recoverable.
- Leaving the section stops speech.

## Not done (needs the owner's decision and device tests)
- **Background playback** (screen locked / app in background / notification controls / audio focus): not implemented. It needs a foreground media service and Android 14 service-type rules; decide in SPEC section 19 item 8 after S1 results.
- Audio caching (SPEC 9.4): out of scope for V1.
- Speaking from a bookmark/search anchor offset inside a paragraph: position is paragraph-level only.

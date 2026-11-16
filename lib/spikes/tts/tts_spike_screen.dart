import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'chunk_player.dart';
import 'tts_engine.dart';

/// Spike S1 (throwaway, debug only): device check for Arabic TTS.
/// Not production UI; findings go to docs/TTS_SPIKE.md.
class TtsSpikeScreen extends StatefulWidget {
  const TtsSpikeScreen({super.key, this.engineFactory});

  /// Injectable for tests; defaults to the real `flutter_tts` engine.
  final TtsEngine Function()? engineFactory;

  @override
  State<TtsSpikeScreen> createState() => _TtsSpikeScreenState();
}

// Generic sample sentences. NOT book content.
const _vowelled = 'السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ.';
const _plain = 'السلام عليكم ورحمة الله وبركاته.';

String _longFake() => '[تجريبي] ${List.generate(
      14,
      (i) => 'هذه الجملة التجريبية رقم ${i + 1} للتأكد من تسلسل المقاطع.',
    ).join(' ')}';

class _TtsSpikeScreenState extends State<TtsSpikeScreen> {
  late final TtsEngine _engine =
      widget.engineFactory?.call() ?? FlutterTtsEngine();
  late final ChunkPlayer _player = ChunkPlayer(_engine);
  final _text = TextEditingController(text: _longFake());

  List<String> _report = const [];
  List<TtsVoice> _voices = const [];
  TtsVoice? _voice;
  String _language = 'ar';
  double _rate = 0.5;

  @override
  void initState() {
    super.initState();
    _player.addListener(() => setState(() {}));
    _loadVoices();
  }

  Future<void> _loadVoices() async {
    try {
      final v = await _engine.arabicVoices();
      if (mounted) setState(() => _voices = v);
    } catch (_) {
      // Shown in the diagnostics report instead.
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _engine.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _diagnose() async {
    final lines = await _engine.diagnose();
    if (mounted) setState(() => _report = lines);
  }

  Future<void> _play() async {
    await _engine.setLanguage(_language);
    await _engine.setRate(_rate);
    await _player.load(_text.text);
    await _player.play();
  }

  String get _reportText => [
        ..._report,
        'selected language: $_language',
        'selected voice: ${_voice ?? '(default)'}',
        'speed: ${_rate.toStringAsFixed(2)}',
        'chunks: ${_player.chunks.length}',
      ].join('\n');

  @override
  Widget build(BuildContext context) {
    final s = _player.state;
    return Scaffold(
      key: const Key('tts-spike-screen'),
      appBar: AppBar(title: const Text('تجربة النطق (S1)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(spacing: 8, children: [
            FilledButton(
              key: const Key('tts-diagnose-button'),
              onPressed: _diagnose,
              child: const Text('فحص الجهاز'),
            ),
            OutlinedButton(
              key: const Key('tts-copy-report'),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _reportText));
              },
              child: const Text('نسخ التقرير'),
            ),
          ]),
          if (_report.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SelectableText(
                _report.join('\n'),
                key: const Key('tts-report'),
                textDirection: TextDirection.ltr,
              ),
            ),
          const SizedBox(height: 8),
          DropdownButton<String>(
            key: const Key('tts-language'),
            value: _language,
            items: const [
              DropdownMenuItem(value: 'ar', child: Text('ar')),
              DropdownMenuItem(value: 'ar-SA', child: Text('ar-SA')),
              DropdownMenuItem(value: 'ar-EG', child: Text('ar-EG')),
            ],
            onChanged: (v) => setState(() => _language = v ?? 'ar'),
          ),
          if (_voices.isNotEmpty)
            DropdownButton<TtsVoice>(
              key: const Key('tts-voice'),
              isExpanded: true,
              value: _voice,
              hint: const Text('الصوت الافتراضي'),
              items: [
                for (final v in _voices)
                  DropdownMenuItem(value: v, child: Text('$v')),
              ],
              onChanged: (v) async {
                setState(() => _voice = v);
                if (v != null) await _engine.setVoice(v);
              },
            ),
          Wrap(spacing: 8, children: [
            TextButton(
              key: const Key('tts-sample-vowelled'),
              onPressed: () => _text.text = _vowelled,
              child: const Text('نص مشكول'),
            ),
            TextButton(
              key: const Key('tts-sample-plain'),
              onPressed: () => _text.text = _plain,
              child: const Text('نص غير مشكول'),
            ),
            TextButton(
              key: const Key('tts-sample-long'),
              onPressed: () => _text.text = _longFake(),
              child: const Text('نص طويل'),
            ),
          ]),
          TextField(
            key: const Key('tts-text'),
            controller: _text,
            maxLines: 5,
          ),
          Row(children: [
            const Text('السرعة'),
            Expanded(
              child: Slider(
                key: const Key('tts-speed'),
                value: _rate,
                min: 0.2,
                max: 1.0,
                onChanged: (v) {
                  setState(() => _rate = v);
                  _player.setRate(v);
                },
              ),
            ),
            Text(_rate.toStringAsFixed(2)),
          ]),
          Wrap(spacing: 8, children: [
            FilledButton(
              key: const Key('tts-play'),
              onPressed: s == PlayerState.playing || s == PlayerState.paused
                  ? null
                  : _play,
              child: const Text('تشغيل'),
            ),
            FilledButton.tonal(
              key: const Key('tts-pause'),
              onPressed: s == PlayerState.playing ? _player.pause : null,
              child: const Text('إيقاف مؤقت'),
            ),
            FilledButton.tonal(
              key: const Key('tts-resume'),
              onPressed: s == PlayerState.paused ? _player.resume : null,
              child: const Text('استئناف'),
            ),
            OutlinedButton(
              key: const Key('tts-stop'),
              onPressed: s == PlayerState.idle ? null : _player.stop,
              child: const Text('إيقاف'),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              '${s.name} - chunk ${_player.chunks.isEmpty ? 0 : _player.index + 1}'
              '/${_player.chunks.length} - offset ${_player.currentOffset}',
              key: const Key('tts-status'),
              textDirection: TextDirection.ltr,
            ),
          ),
        ],
      ),
    );
  }
}

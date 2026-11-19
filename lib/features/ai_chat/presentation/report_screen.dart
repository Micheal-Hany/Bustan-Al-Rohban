import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/strings.dart';
import '../domain/report.dart';

String reasonLabel(ReportReason r) => switch (r) {
      ReportReason.wrongOrInvented => AppStrings.reportReasonWrong,
      ReportReason.notFromBook => AppStrings.reportReasonNotBook,
      ReportReason.offensiveOrUnsafe => AppStrings.reportReasonOffensive,
      ReportReason.doctrinalConcern => AppStrings.reportReasonDoctrinal,
      ReportReason.other => AppStrings.reportReasonOther,
    };

/// Confirmation screen for "report this answer": shows EXACTLY what would be
/// sent (SPEC 7.8) and nothing else. Sending is wired in Task 12a; until then
/// the sender reports "unavailable" and nothing leaves the device.
class ReportScreen extends StatefulWidget {
  const ReportScreen({
    super.key,
    required this.answerText,
    required this.question,
    required this.citedParagraphIds,
    required this.contentVersion,
    required this.provider,
    required this.model,
  });

  final String answerText;
  final String question;
  final List<String> citedParagraphIds;
  final int? contentVersion;
  final String? provider;
  final String? model;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _note = TextEditingController();
  ReportReason? _reason;
  String? _message;
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final reason = _reason;
    if (reason == null || _busy) return;
    final sender = context.read<ReportSender>();
    setState(() {
      _busy = true;
      _message = null;
    });
    String message;
    try {
      await sender.send(ReportPayload(
        reason: reason,
        note: _note.text,
        answerText: widget.answerText,
        question: widget.question,
        citedParagraphIds: widget.citedParagraphIds,
        contentVersion: widget.contentVersion ?? 0,
        provider: widget.provider ?? 'unknown',
        model: widget.model ?? 'unknown',
      ));
      message = AppStrings.reportSentThanks;
    } on ReportUnavailable {
      message = AppStrings.reportUnavailable;
    } catch (_) {
      message = AppStrings.chatErrServer;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = message;
    });
  }

  Widget _field(String label, String value, String key) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          Text(value, key: Key(key)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final cites = widget.citedParagraphIds.isEmpty
        ? AppStrings.reportNoCitations
        : widget.citedParagraphIds.join('، ');
    return Scaffold(
      key: const Key('report-screen'),
      appBar: AppBar(title: const Text(AppStrings.reportTitle)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(AppStrings.reportWhatIsSent,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _field(AppStrings.reportFieldAnswer, widget.answerText, 'report-field-answer'),
        _field(AppStrings.reportFieldQuestion, widget.question, 'report-field-question'),
        _field(AppStrings.reportFieldCitations, cites, 'report-field-citations'),
        _field(
          AppStrings.reportFieldVersion,
          widget.contentVersion?.toString() ?? AppStrings.reportUnknown,
          'report-field-version',
        ),
        _field(
          AppStrings.reportFieldModel,
          '${widget.provider ?? AppStrings.reportUnknown} / ${widget.model ?? AppStrings.reportUnknown}',
          'report-field-model',
        ),
        const Text(AppStrings.reportNotSent, key: Key('report-not-sent')),
        const Divider(height: 32),
        Text(AppStrings.reportFieldReason,
            style: Theme.of(context).textTheme.titleSmall),
        RadioGroupCompat(
          value: _reason,
          onChanged: (r) => setState(() => _reason = r),
        ),
        TextField(
          key: const Key('report-note'),
          controller: _note,
          maxLength: 500,
          maxLines: 3,
          decoration:
              const InputDecoration(labelText: AppStrings.reportFieldNote),
        ),
        const SizedBox(height: 8),
        FilledButton(
          key: const Key('report-send'),
          onPressed: _reason == null || _busy ? null : _send,
          child: const Text(AppStrings.reportSend),
        ),
        if (_reason == null)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(AppStrings.reportChooseReason),
          ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_message!, key: const Key('report-result')),
          ),
      ]),
    );
  }
}

/// Radio list for the reasons (works on Flutter 3.24 without RadioGroup).
class RadioGroupCompat extends StatelessWidget {
  const RadioGroupCompat({super.key, required this.value, required this.onChanged});

  final ReportReason? value;
  final ValueChanged<ReportReason> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      for (final r in ReportReason.values)
        RadioListTile<ReportReason>(
          key: Key('report-reason-${r.code}'),
          value: r,
          groupValue: value,
          title: Text(reasonLabel(r)),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
    ]);
  }
}

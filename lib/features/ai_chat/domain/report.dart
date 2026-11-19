/// Reason categories of "report this answer" (same codes as the backend).
enum ReportReason {
  wrongOrInvented('wrong_or_invented'),
  notFromBook('not_from_book'),
  offensiveOrUnsafe('offensive_or_unsafe'),
  doctrinalConcern('doctrinal_concern'),
  other('other');

  const ReportReason(this.code);

  final String code;
}

/// Exactly what a report contains (SPEC 7.8): never the conversation history.
class ReportPayload {
  const ReportPayload({
    required this.reason,
    this.note,
    required this.answerText,
    required this.question,
    required this.citedParagraphIds,
    required this.contentVersion,
    required this.provider,
    required this.model,
  });

  final ReportReason reason;
  final String? note;
  final String answerText;
  final String question;
  final List<String> citedParagraphIds;
  final int contentVersion;
  final String provider;
  final String model;

  Map<String, dynamic> toJson() => {
        'reason': reason.code,
        if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
        'answerText': answerText,
        'question': question,
        'citedParagraphIds': citedParagraphIds,
        'contentVersion': contentVersion,
        'provider': provider,
        'model': model,
      };
}

class ReportUnavailable implements Exception {
  const ReportUnavailable();
}

abstract class ReportSender {
  /// Throws [ReportUnavailable] until the endpoint is wired (Task 12a).
  Future<void> send(ReportPayload payload);
}

class UnavailableReportSender implements ReportSender {
  const UnavailableReportSender();

  @override
  Future<void> send(ReportPayload payload) async =>
      throw const ReportUnavailable();
}

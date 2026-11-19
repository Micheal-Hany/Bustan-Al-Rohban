import 'dart:convert';

/// What kind of text a block is (SPEC 6.2): the UI shows each differently.
enum BlockType { quotation, paraphrase, inference }

/// A validated source the backend returned for a block.
class SourceRef {
  const SourceRef({
    required this.paragraphId,
    required this.saintId,
    required this.saintTitle,
    required this.sectionId,
    required this.sectionTitle,
    this.page,
  });

  factory SourceRef.fromJson(Map<String, dynamic> j) => SourceRef(
        paragraphId: _str(j, 'paragraphId'),
        saintId: _str(j, 'saintId'),
        saintTitle: _str(j, 'saintTitle'),
        sectionId: _str(j, 'sectionId'),
        sectionTitle: _str(j, 'sectionTitle'),
        page: j['page'] is int ? j['page'] as int : null,
      );

  final String paragraphId;
  final String saintId;
  final String saintTitle;
  final String sectionId;
  final String sectionTitle;
  final int? page;

  Map<String, dynamic> toJson() => {
        'paragraphId': paragraphId,
        'saintId': saintId,
        'saintTitle': saintTitle,
        'sectionId': sectionId,
        'sectionTitle': sectionTitle,
        'page': page,
      };
}

class AnswerBlock {
  const AnswerBlock({
    required this.type,
    required this.text,
    required this.references,
  });

  factory AnswerBlock.fromJson(Map<String, dynamic> j) {
    final type = BlockType.values.where((t) => t.name == j['type']);
    if (type.isEmpty) throw const FormatException('unknown block type');
    final refs = j['references'];
    return AnswerBlock(
      type: type.first,
      text: _str(j, 'text'),
      references: refs is List
          ? [
              for (final r in refs)
                SourceRef.fromJson(Map<String, dynamic>.from(r as Map)),
            ]
          : const [],
    );
  }

  final BlockType type;
  final String text;
  final List<SourceRef> references;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'text': text,
        'references': [for (final r in references) r.toJson()],
      };
}

/// The backend's answer to one question. Parsing is strict: anything that is
/// not one of the three known shapes is a [FormatException].
sealed class AssistantReply {
  const AssistantReply();

  factory AssistantReply.fromJson(Map<String, dynamic> j) {
    switch (j['status']) {
      case 'answered':
        final blocks = j['blocks'];
        if (blocks is! List || blocks.isEmpty) {
          throw const FormatException('answered without blocks');
        }
        final meta = j['meta'];
        return AnsweredReply(
          blocks: [
            for (final b in blocks)
              AnswerBlock.fromJson(Map<String, dynamic>.from(b as Map)),
          ],
          pastoralNote:
              j['pastoralNote'] is String ? j['pastoralNote'] as String : null,
          provider: meta is Map && meta['provider'] is String
              ? meta['provider'] as String
              : null,
          model: meta is Map && meta['model'] is String
              ? meta['model'] as String
              : null,
        );
      case 'refused':
        final ids = j['suggestedSaintIds'];
        return RefusedReply(
          reason: _str(j, 'reason'),
          message: _str(j, 'message'),
          suggestedSaintIds: ids is List ? [for (final i in ids) '$i'] : const [],
        );
      case 'safety':
        final ref = j['referral'];
        return SafetyReply(
          category: _str(j, 'category'),
          message: _str(j, 'message'),
          referral: ref is List ? [for (final r in ref) '$r'] : const [],
        );
    }
    throw const FormatException('unknown reply status');
  }

  /// Text kept as the message content (readable even without the structure).
  String get plainText;

  Map<String, dynamic> toJson();
}

class AnsweredReply extends AssistantReply {
  const AnsweredReply({
    required this.blocks,
    this.pastoralNote,
    this.provider,
    this.model,
  });

  final List<AnswerBlock> blocks;
  final String? pastoralNote;
  final String? provider;
  final String? model;

  /// Every distinct cited paragraph id, in order of first use.
  List<String> get citedParagraphIds => {
        for (final b in blocks)
          for (final r in b.references) r.paragraphId,
      }.toList();

  @override
  String get plainText => [
        for (final b in blocks) b.text,
        if (pastoralNote != null) pastoralNote!,
      ].join('\n\n');

  @override
  Map<String, dynamic> toJson() => {
        'status': 'answered',
        'blocks': [for (final b in blocks) b.toJson()],
        if (pastoralNote != null) 'pastoralNote': pastoralNote,
        'meta': {'provider': provider, 'model': model},
      };
}

class RefusedReply extends AssistantReply {
  const RefusedReply({
    required this.reason,
    required this.message,
    this.suggestedSaintIds = const [],
  });

  final String reason;
  final String message;
  final List<String> suggestedSaintIds;

  @override
  String get plainText => message;

  @override
  Map<String, dynamic> toJson() => {
        'status': 'refused',
        'reason': reason,
        'message': message,
        'suggestedSaintIds': suggestedSaintIds,
      };
}

class SafetyReply extends AssistantReply {
  const SafetyReply({
    required this.category,
    required this.message,
    this.referral = const [],
  });

  final String category;
  final String message;
  final List<String> referral;

  @override
  String get plainText => message;

  @override
  Map<String, dynamic> toJson() => {
        'status': 'safety',
        'category': category,
        'message': message,
        'referral': referral,
      };
}

String _str(Map<String, dynamic> j, String key) {
  final v = j[key];
  if (v is String && v.isNotEmpty) return v;
  throw FormatException('missing $key');
}

/// A reply as stored in a message's `metaJson`, with the content version of
/// the installed book at the time (needed by "report this answer").
class StoredReply {
  const StoredReply(this.reply, this.contentVersion);

  final AssistantReply reply;
  final int? contentVersion;
}

String encodeStoredReply(AssistantReply reply, int? contentVersion) =>
    jsonEncode({'v': 1, 'contentVersion': contentVersion, 'reply': reply.toJson()});

/// Null when there is no (valid) structured reply: the UI then shows the
/// plain message content instead.
StoredReply? decodeStoredReply(String? metaJson) {
  if (metaJson == null) return null;
  try {
    final j = jsonDecode(metaJson);
    if (j is! Map || j['v'] != 1) return null;
    return StoredReply(
      AssistantReply.fromJson(Map<String, dynamic>.from(j['reply'] as Map)),
      j['contentVersion'] is int ? j['contentVersion'] as int : null,
    );
  } catch (_) {
    return null;
  }
}

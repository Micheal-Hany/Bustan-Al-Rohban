import '../../../app/strings.dart';
import '../../../core/content/content_models.dart';

/// "ص 3" / "ص 3-5" / "الصفحة غير معروفة".
String pageLabel(Section s) {
  final start = s.pageStart;
  final end = s.pageEnd;
  if (start == null || end == null) return AppStrings.pagesUnknown;
  return start == end
      ? '${AppStrings.pageWord} $start'
      : '${AppStrings.pageWord} $start-$end';
}

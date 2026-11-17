/// Arabic UI strings for Task 0. Moves to proper localization if more
/// languages are ever needed (not in Version 1).
class AppStrings {
  const AppStrings._();

  static const appTitle = 'بستان الرهبان';
  static const homeSubtitle = 'قراءة ودراسة كتاب بستان الرهبان';
  static const library = 'المكتبة';
  static const search = 'البحث';
  static const bookmarks = 'العلامات المرجعية';
  static const chat = 'المساعد';
  static const settings = 'الإعدادات';
  static const underConstruction = 'هذه الصفحة قيد الإنشاء';

  // Spike S1 (debug only)
  static const ttsSpike = 'تجربة النطق (S1)';

  // Library (Task 2)
  static const bookOverview = 'نظرة عامة على الكتاب';
  static const saintsList = 'القديسون';
  static const sectionsList = 'الأقسام';
  static const viewSaints = 'عرض القديسين';
  static const saintsWord = 'قديسين';
  static const retry = 'إعادة المحاولة';
  static const loadFailed = 'تعذر تحميل المحتوى';
  static const unexpectedError = 'حدث خطأ غير متوقع';
  static const notFound = 'العنصر غير موجود';
  static const emptyLibrary = 'لا يوجد محتوى بعد';
  static const emptySaints = 'لا يوجد قديسون';
  static const emptySections = 'لا توجد أقسام لهذا القديس';
  static const contentVersionLabel = 'إصدار المحتوى';
  static const editionLabel = 'الطبعة';
  static const authorLabel = 'المؤلف';
  static const publisherLabel = 'الناشر';
  static const yearLabel = 'السنة';
  static const attributionLabel = 'الإسناد';
  static const aliasesLabel = 'أسماء أخرى';
  // Settings (Task 6)
  static const readingSection = 'القراءة';
  static const fontSizeLabel = 'حجم الخط';
  static const lineSpacingLabel = 'تباعد الأسطر';
  static const lineSpacingCompact = 'متقارب';
  static const lineSpacingNormal = 'عادي';
  static const lineSpacingRelaxed = 'واسع';
  static const previewLabel = 'معاينة';
  static const previewSample =
      '[تجريبي] هذه فقرة تجريبية لمعاينة حجم الخط وتباعد الأسطر. ليست من الكتاب.';
  static const resetSize = 'الحجم الافتراضي';
  static const resetAll = 'استعادة الإعدادات الافتراضية';
  static const prefsSaveFailed = 'تعذر حفظ الإعدادات';

  // Bookmarks and progress (Task 5)
  static const addBookmark = 'إضافة إشارة مرجعية';
  static const removeBookmark = 'إزالة الإشارة المرجعية';
  static const bookmarkLoadFailed = 'تعذر تحميل الإشارات المرجعية';
  static const bookmarkSaveFailed = 'تعذر حفظ الإشارة المرجعية';
  static const bookmarksEmpty = 'لا توجد إشارات مرجعية بعد';
  static const bookmarkUnavailable = 'هذا المحتوى لم يعد متاحا بعد التحديث';
  static const deleteBookmark = 'حذف';
  static const continueReading = 'متابعة القراءة';

  // Search (Task 4)
  static const searchHint = 'ابحث في الكتاب';
  static const searchClear = 'مسح';
  static const searchIdle = 'اكتب كلمة أو أكثر للبحث في نص الكتاب';
  static const searchNoResults = 'لا توجد نتائج مطابقة';
  static const searchResultsWord = 'نتيجة';

  // Reader (Task 3)
  static const textSmaller = 'تصغير الخط';
  static const textLarger = 'تكبير الخط';
  static const editorialLabel = 'إضافة تحريرية - ليست من نص الكتاب';
  static const emptyParagraphs = 'لا توجد فقرات في هذا القسم';

  // Content preview (debug only)
  static const contentPreview = 'معاينة المحتوى';
  static const loadInvalid = 'تحميل ملف غير صالح';
  static const reloadValid = 'إعادة تحميل الملف الصحيح';
  static const contentInvalid = 'المحتوى غير صالح';
  static const fakeBanner = 'محتوى تجريبي (FAKE) - ليس من الكتاب';
  static const saintsCount = 'عدد القديسين';
  static const warningsCount = 'التحذيرات';
  static const sectionsWord = 'أقسام';
  static const paragraphsWord = 'فقرات';
  static const pageWord = 'ص';
  static const pagesUnknown = 'الصفحة غير معروفة';
}

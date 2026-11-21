/// Arabic UI strings for Task 0. Moves to proper localization if more
/// languages are ever needed (not in Version 1).
class AppStrings {
  const AppStrings._();

  static const appTitle = 'بستان الرهبان';
  static const homeSubtitle = 'قراءة ودراسة كتاب بستان الرهبان';
  static const homeTagline = 'قراءة وروحانية .. لحياة أعمق';
  static const startNow = 'ابدأ الآن';
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
  static const appearanceSection = 'المظهر';
  static const themeSystem = 'حسب الجهاز';
  static const themeLight = 'فاتح';
  static const themeDark = 'داكن';
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

  // Insights (Task 7)
  static const insights = 'الرؤى المُعدّة';
  static const insightsLabel = 'رؤى مُعدّة - ليست من نص الكتاب';
  static const insightSummary = 'الملخص';
  static const insightKeyPoints = 'النقاط الرئيسية';
  static const insightLessons = 'الدروس الروحية';
  static const insightKeywords = 'كلمات مفتاحية';
  static const insightSources = 'فقرات الكتاب المرتبطة';
  static const insightOriginAi = 'مسودة بالذكاء الاصطناعي';
  static const insightOriginHuman = 'إعداد بشري';
  static const insightApproved = 'معتمد';
  static const insightNotApproved = 'غير معتمد - للمراجعة فقط';
  static const insightsNone = 'لا توجد رؤى لهذا القسم';
  static const backToText = 'العودة إلى النص الأصلي';
  static const paragraphWord = 'فقرة';

  // Text-to-speech (Task 8)
  static const ttsPlay = 'تشغيل القراءة';
  static const ttsPause = 'إيقاف مؤقت';
  static const ttsStop = 'إيقاف القراءة';
  static const ttsSpeed = 'سرعة القراءة';
  static const ttsOfflineVoice = 'صوت عربي يعمل دون إنترنت';
  static const ttsMissingVoice =
      'لا يوجد صوت عربي على هذا الجهاز. ثبّت صوتًا عربيًا من إعدادات الجهاز: '
      'الإعدادات › النظام › اللغات › تحويل النص إلى كلام.';
  static const ttsOnlineOnly =
      'الأصوات العربية المتاحة تحتاج إلى الإنترنت، ولن يتم استخدام خدمة عبر '
      'الإنترنت تلقائيًا. ثبّت صوتًا عربيًا يعمل دون إنترنت.';
  static const ttsError = 'تعذر تشغيل القراءة. حاول مرة أخرى.';

  // Chat history (Task 9)
  static const chatHistoryTitle = 'المحادثات';
  static const chatPrivacyNote =
      'تُحفظ المحادثات على جهازك فقط، ولا تُنسخ احتياطيًا. حذف التطبيق أو '
      'مسح بياناته يحذفها. يمكنك قراءة المحادثات القديمة دون إنترنت.';
  static const chatEmpty = 'لا توجد محادثات بعد';
  static const chatNewConversation = 'محادثة جديدة';
  static const chatDelete = 'حذف المحادثة';
  static const chatClearAll = 'حذف كل المحادثات';
  static const chatClearConfirmTitle = 'حذف كل المحادثات؟';
  static const chatClearConfirmBody =
      'سيتم حذف كل المحادثات من هذا الجهاز نهائيًا.';
  static const chatConfirm = 'حذف';
  static const chatCancel = 'إلغاء';
  static const chatLoadFailed = 'تعذر تحميل المحادثات';
  static const chatScopeBook = 'كل الكتاب';
  static const chatScopeSaint = 'قديس واحد';
  static const chatScopeSection = 'قسم واحد';
  static const chatMessageFailed = 'لم تُرسل';
  static const chatMessagePending = 'جارٍ الإرسال';
  static const chatEmptyConversation = 'لا توجد رسائل في هذه المحادثة';
  static const chatSend = 'إرسال';

  // Privacy (Task 12a)
  static const privacyTitle = 'الخصوصية والبيانات';
  static const privacyIntro =
      'هذه الصفحة تشرح بالتفصيل ما يُحفظ على جهازك، وما يُرسل عند استخدام '
      'المساعد، وما لا نفعله.';
  static const privacyContactLabel = 'للتواصل بشأن الخصوصية';
  static const privacyOpen = 'الخصوصية والبيانات';
  static const chatNoticeTitle = 'قبل إرسال أول سؤال';
  static const chatNoticeBody =
      'عند الإرسال يُرسل سؤالك وبعض رسائل المحادثة الأخيرة إلى خادم التطبيق، '
      'ثم إلى مزوّد ذكاء اصطناعي لصياغة الإجابة من نص الكتاب. لا يحفظ الخادم '
      'محادثاتك، ويبقى سجلّك على جهازك فقط. لا تكتب معلومات شخصية أو '
      'اعترافات في الأسئلة.';
  static const chatNoticeReadMore = 'قراءة الخصوصية كاملة';
  static const chatNoticeAccept = 'موافق، تابع';

  // AI chat (Task 11)
  static const chatBookOnly = 'إجابات من كتاب بستان الرهبان فقط';
  static const chatScopeLabel = 'النطاق';
  static const chatScopeBookFull = 'كل الكتاب';
  static const chatScopeSaintOf = 'القديس';
  static const chatScopeSectionOf = 'قسم من';
  static const chatScopeChange = 'تغيير النطاق';
  static const chatScopeChangeNote =
      'يبدأ هذا محادثة جديدة بالنطاق الذي تختاره، وتبقى هذه المحادثة كما هي.';
  static const chatScopeChooseSaint = 'أو اختر قديسًا';
  static const chatAskPrompt =
      'اسأل عن ما ورد في كتاب بستان الرهبان. لن تُعطى إجابة إلا من نصوص الكتاب.';
  static const chatInputHint = 'اكتب سؤالك';
  static const chatSending = 'جارٍ البحث في الكتاب…';
  static const chatSendRetry = 'إعادة المحاولة';
  static const chatDismiss = 'إغلاق';
  static const chatSendFailedKept = 'نصّ سؤالك محفوظ في خانة الكتابة.';
  static const chatErrOffline = 'لا يوجد اتصال بالإنترنت. اتصل بالشبكة ثم أعد المحاولة.';
  static const chatErrTimeout = 'استغرق الرد وقتًا أطول من المعتاد. أعد المحاولة.';
  static const chatErrRateLimited = 'أرسلت أسئلة كثيرة في وقت قصير. حاول بعد قليل.';
  static const chatErrUnavailable =
      'المساعد غير متاح مؤقتًا. حاول لاحقًا. يمكنك متابعة قراءة الكتاب.';
  static const chatErrAttestation = 'تعذّر التحقق من التطبيق. حدّث التطبيق من المتجر ثم أعد المحاولة.';
  static const chatErrServer = 'حدث خطأ في الخدمة. أعد المحاولة لاحقًا.';
  static const chatErrBadResponse = 'وصل رد غير مفهوم. أعد المحاولة.';
  static const chatErrStorage = 'وصلت الإجابة لكن تعذّر حفظها على الجهاز.';
  static const chatErrNotConfigured = 'خدمة المساعد غير مُعدّة في هذا الإصدار.';
  static const chatSecondsWord = 'ثانية';
  static const chatBlockQuotation = 'اقتباس من الكتاب';
  static const chatBlockParaphrase = 'تلخيص لما في الكتاب';
  static const chatBlockInference = 'استنتاج حذر (ليس نصًا من الكتاب)';
  static const chatSources = 'المصادر';
  static const chatPageShort = 'ص';
  static const chatRefusedAskBook = 'اسأل في كل الكتاب';
  static const chatSafetyTitle = 'ملاحظة مهمة';
  static const chatReportAnswer = 'الإبلاغ عن هذه الإجابة';
  static const reportTitle = 'الإبلاغ عن إجابة';
  static const reportWhatIsSent = 'ما سيُرسل بالضبط';
  static const reportNotSent = 'لن تُرسل بقية المحادثة ولا أي رسالة أخرى.';
  static const reportFieldAnswer = 'نص الإجابة';
  static const reportFieldQuestion = 'السؤال الذي أنتج الإجابة';
  static const reportFieldCitations = 'أرقام الفقرات المستشهد بها';
  static const reportFieldVersion = 'إصدار محتوى الكتاب';
  static const reportFieldModel = 'المزوّد والنموذج';
  static const reportFieldReason = 'سبب الإبلاغ';
  static const reportFieldNote = 'ملاحظة (اختياري)';
  static const reportNoCitations = 'لا يوجد';
  static const reportUnknown = 'غير معروف';
  static const reportSend = 'إرسال البلاغ';
  static const reportUnavailable =
      'الإبلاغ غير متاح الآن، ولم يُرسل شيء. حاول لاحقًا.';
  static const reportSentThanks = 'شكرًا. وصل بلاغك.';
  static const reportReasonWrong = 'معلومة خاطئة أو مختلقة';
  static const reportReasonNotBook = 'ليست من الكتاب';
  static const reportReasonOffensive = 'مسيئة أو غير آمنة';
  static const reportReasonDoctrinal = 'ملاحظة عقائدية';
  static const reportReasonOther = 'سبب آخر';
  static const reportChooseReason = 'اختر سببًا';
  static const askAboutSaint = 'اسأل المساعد عن هذا القديس';
}

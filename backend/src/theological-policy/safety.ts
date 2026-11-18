import { normalize } from '../retrieval/arabic';

export type SafetyCategory = 'self_harm' | 'medical_personal' | 'ascetic_personal' | 'confession_sacrament';
export type Referral = 'confession_father' | 'professional' | 'emergency';

/**
 * First line of defence, BEFORE any model call: a conservative lexicon (in
 * normalized form) for questions where the assistant must not give guidance
 * itself (SPEC 6.4). A match returns a fixed, owner-reviewed response and the
 * model is never called. This is a floor, not a classifier: the evaluation
 * set measures it, and the owner extends it. Historical questions about what
 * a saint did ("كيف صام القديس؟") are NOT matched.
 */
const SELF_HARM = [
  'انتحر', 'اقتل نفسي', 'اقتل نفسى', 'اوذي نفسي', 'اؤذي نفسي', 'ايذاء نفسي', 'اريد ان اموت',
  'لا اريد ان اعيش', 'انهي حياتي', 'اجرح نفسي', 'اتمني الموت', 'تعبت من الحياه',
];
const MEDICAL = [
  'اعاني من', 'عندي مرض', 'اخذ دواء', 'ادويتي', 'مريض بالسكر', 'مريضه بالسكر', 'انا حامل',
  'انا مصاب', 'نوبات هلع', 'اضطراب نفسي', 'اكتئاب', 'جرعه',
];
const FIRST_PERSON_INTENT = [
  'هل استطيع', 'هل يمكنني', 'هل يجوز لي', 'هل ينبغي لي', 'اريد ان', 'انوي', 'سوف', 'ساقوم',
  'افكر في', 'اود ان', 'هل اصوم', 'هل اسهر', 'اقرر ان', 'قررت ان', 'هل اعتزل', 'هل اترك',
];
const SEVERE_PRACTICE = [
  'بدون طعام', 'دون طعام', 'بدون ماء', 'دون ماء', 'ايام متواصله', 'ايام متتاليه', 'بلا طعام',
  'لا انام', 'بدون نوم', 'دون نوم', 'بلا نوم', 'اسهر الليل كله', 'اعتزل الناس', 'انعزل عن',
  'اجلد نفسي', 'اعذب جسدي', 'اقسو علي جسدي', 'اقسي علي جسدي', 'انقطاع تام', 'صوم تام',
  'احرم نفسي', 'اجوع نفسي', 'ساجوع',
];
const CONFESSION = [
  'اعترف لك', 'اعترافي لك', 'حللني', 'احللني', 'اعطني الحل', 'اعطني حلا', 'هل يغفر الله لي',
  'هل غفرت خطيتي', 'هل خطيتي مغفوره', 'هل خطيئتي مغفوره', 'هل اتناول', 'هل يجوز ان اتناول',
  'هل استطيع ان اتناول', 'اتناول من الاسرار', 'اعطني التوبه', 'ما هي توبتي', 'ما توبتي',
  'قانون التوبه الخاص بي', 'هل ابطل زواجي', 'هل اطلق', 'هل اتزوج',
];

function hit(padded: string, phrases: readonly string[]): boolean {
  return phrases.some((p) => padded.includes(` ${normalize(p)} `) || padded.includes(normalize(p)));
}

export function classifySafety(text: string): SafetyCategory | null {
  const padded = ` ${normalize(text)} `;
  // Order = priority: danger to life first.
  if (hit(padded, SELF_HARM)) return 'self_harm';
  if (hit(padded, MEDICAL)) return 'medical_personal';
  if (hit(padded, SEVERE_PRACTICE) && hit(padded, FIRST_PERSON_INTENT)) return 'ascetic_personal';
  if (hit(padded, CONFESSION)) return 'confession_sacrament';
  return null;
}

export interface SafetyResponse {
  category: SafetyCategory;
  referral: Referral[];
  message: string;
}

/**
 * Fixed responses (Arabic). OWNER REVIEW REQUIRED before release (ROADMAP
 * Task 10b, SPEC 6.5): wording, tone and what to refer to.
 */
export const SAFETY_RESPONSES: Record<SafetyCategory, SafetyResponse> = {
  self_harm: {
    category: 'self_harm',
    referral: ['emergency', 'professional', 'confession_father'],
    message:
      'أنا آسف لأنك تمر بهذا الألم، وسلامتك أهم ما في الأمر الآن. إن كنت في خطر أو تفكر في إيذاء نفسك، ' +
      'فاتصل بالإسعاف أو بخدمات الطوارئ في بلدك فورًا، أو اطلب من شخص تثق به أن يكون معك الآن. ' +
      'وتحدث أيضًا مع أب اعترافك أو كاهن كنيستك، ومع طبيب أو أخصائي نفسي مؤهل. ' +
      'هذا التطبيق يجيب عن أسئلة عن كتاب بستان الرهبان فقط، ولا يقدّم دعمًا نفسيًا أو طبيًا.',
  },
  medical_personal: {
    category: 'medical_personal',
    referral: ['professional', 'confession_father'],
    message:
      'لا أستطيع تقديم مشورة طبية أو نفسية، وهذا التطبيق لا يغني عن الطبيب أو المختص. ' +
      'استشر طبيبك في أمر صحتك قبل أي صوم أو ممارسة روحية، وتحدث مع أب اعترافك في ما يخص حياتك الروحية.',
  },
  ascetic_personal: {
    category: 'ascetic_personal',
    referral: ['confession_father', 'professional'],
    message:
      'يروي الكتاب ممارسات نسكية قاسية عن بعض القديسين على سبيل التاريخ، وليست توجيهًا أو وصفة لأحد، ' +
      'وأنا لا أنصح بأي ممارسة من هذا النوع ولا أقدّم مشورة طبية أو نفسية. ' +
      'ما يخصك شخصيًا يُعرض على أب اعترافك الذي يعرفك ويرشدك، ومع طبيب إن كان الأمر يمسّ صحتك. ' +
      'يمكنني أن أنقل لك ما يقوله الكتاب عن قديس معيّن، كتاريخ فقط.',
  },
  confession_sacrament: {
    category: 'confession_sacrament',
    referral: ['confession_father'],
    message:
      'لا أستطيع أن أمنح حلًّا أو أصدر حكمًا في الاعتراف أو التناول أو الأسرار؛ فهذا من اختصاص الكاهن وأب الاعتراف، ' +
      'ولا يحلّ هذا التطبيق محلّ الاعتراف أو الإرشاد الكنسي. تحدث مع أب اعترافك في ما يخصك.',
  },
};

/** Topics where an answer from the book carries a pastoral note (SPEC 6.4). */
const SENSITIVE_TOPICS = [
  'صوم', 'صيام', 'اعتراف', 'توبه', 'زواج', 'تناول', 'سر', 'اسرار', 'عقيده', 'عقائد', 'لاهوت',
  'نسك', 'نساك', 'سهر', 'عزله', 'انفراد', 'ازمه', 'خطيه', 'خطيئه',
];

export function isSensitiveTopic(text: string): boolean {
  const tokens = normalize(text)
    .split(' ')
    .filter(Boolean)
    .map((t) => t.replace(/^(وال|بال|لل|ال|و)/, ''));
  const topics = SENSITIVE_TOPICS.map(normalize);
  // Short roots (e.g. سر) must match exactly; longer ones also as a prefix
  // so that اعترافه / الاعتراف / صيامه are caught.
  return topics.some((t) => tokens.some((k) => k === t || (t.length >= 3 && k.startsWith(t))));
}

/** Added to answers on sensitive topics: refer personal decisions onward. */
export const PASTORAL_NOTE =
  'هذا ما ورد في الكتاب فقط، وليس إرشادًا شخصيًا أو بيانًا رسميًا من الكنيسة. ' +
  'للقرارات الخاصة بك استشر أب اعترافك أو كاهنك.';

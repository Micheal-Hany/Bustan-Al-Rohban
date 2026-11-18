import { normalize, stem, terms, tokenize } from '../src/retrieval/arabic';

describe('Arabic normalization', () => {
  it('drops diacritics, tatweel and zero-width marks', () => {
    expect(normalize('بِسْمِ اللّٰهِ')).toBe('بسم الله');
    expect(normalize('كـــتاب')).toBe('كتاب');
    expect(normalize('ك​تاب')).toBe('كتاب');
  });

  it('folds alef, ya and ta marbuta variants', () => {
    expect(normalize('أإآٱ')).toBe('اااا');
    expect(normalize('على مصطفى')).toBe('علي مصطفي');
    expect(normalize('الصلاة')).toBe('الصلاه');
  });

  it('folds Arabic-Indic and Persian digits and lowercases Latin', () => {
    expect(tokenize('صفحة ١٢٣ و ۴۵ ABC')).toEqual(['صفحه', '123', 'و', '45', 'abc']);
  });

  it('keeps hamza on waw and ya', () => {
    expect(normalize('مؤمن شيء رئيس')).toBe('مؤمن شيء رئيس');
  });

  it('splits on punctuation and keeps tokens whole', () => {
    expect(tokenize('قال: «الصوم، والصلاة».')).toEqual(['قال', 'الصوم', 'والصلاه']);
  });

  it('stems only the definite article prefixes and keeps short words', () => {
    expect(stem('الصوم')).toBe('صوم');
    expect(stem('والصلاه')).toBe('صلاه');
    expect(stem('بالطاعه')).toBe('طاعه');
    expect(stem('الله')).toBe('الله'); // would leave 2 letters
    expect(stem('صوم')).toBe('صوم');
  });

  it('terms removes stop words and stems', () => {
    expect(terms('ما هو الصوم في الكتاب والعبادة؟')).toEqual(['صوم', 'عباده']);
    expect(terms('هل من في على')).toEqual([]);
  });

  it('the same word with and without diacritics gives the same term', () => {
    expect(terms('الصَّوْمُ')).toEqual(terms('الصوم'));
  });
});

let translations: Record<string, string> = {};

export function setUiTranslations(next: unknown) {
  translations = next && typeof next === 'object'
    ? next as Record<string, string>
    : {};
}

export function t(key: string, fallback: string) {
  const value = translations[key];
  return typeof value === 'string' && value.length > 0 ? value : fallback;
}

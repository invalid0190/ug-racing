Locales = Locales or {}

local function ResolveLocaleValue(locale, key)
    local value = locale and locale[key]
    if value ~= nil then return value end

    value = locale
    for part in tostring(key):gmatch('[^.]+') do
        if type(value) ~= 'table' then return nil end
        value = value[part]
    end
    return value
end

function GetLocaleName()
    local configured = type(Config.Locale) == 'string' and Config.Locale:lower() or 'en'
    return Locales[configured] and configured or 'en'
end

function _L(key, ...)
    if type(key) ~= 'string' then return key end

    local selected = Locales[GetLocaleName()] or {}
    local fallback = Locales.en or {}
    local value = ResolveLocaleValue(selected, key)
        or ResolveLocaleValue(fallback, key)
        or key

    if type(value) ~= 'string' then return key end
    if select('#', ...) == 0 then return value end

    local ok, formatted = pcall(string.format, value, ...)
    return ok and formatted or value
end

function LocalizeNotification(data)
    if type(data) ~= 'table' then return data end

    local localized = {}
    for key, value in pairs(data) do localized[key] = value end
    if type(localized.title) == 'string' then localized.title = _L(localized.title) end
    if type(localized.description) == 'string' then localized.description = _L(localized.description) end
    return localized
end

function GetLocalePayload()
    local name = GetLocaleName()
    local selected = Locales[name] or Locales.en or {}
    return {
        locale = name,
        translations = selected.ui or (Locales.en and Locales.en.ui) or {}
    }
end

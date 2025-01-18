Localization = {}

local UIText = {
  modName = "Gamma Controls",
  dragFloatName = " Gamma ",
  dragFloatStepValue = " Step Value ",
  warnInsideMenuText1 = "We are currently inside the Menu.",
  warnInsideMenuText2 = "Gamma values can not be changed.",
  warnInsideMenuText3 = "Uncheck \"Default Gamma in Menus\" if you want to change the values.",
  warnInsidePhotoModeText1 = "We are currently inside the Photo Mode.",
  warnInsidePhotoModeText2 = "Gamma values can not be changed.",
  warnInsidePhotoModeText3 = "Uncheck \"Default Gamma in Photo Mode\" if you want to change the values.",
  saveButton = " Save ",
  loadButton = " Load ",
  resetDefaultsButton = " Reset Defaults ",
  defaultGammainMenuToggle = "Default Gamma in Menus",
  defaultGammainMenuTooltip =
  "Set default gamma on game settings, menu, phone popup, radio controls popup, vehicle call controls popup, weapon wheel, loading screen, read shard and tutorial popups.",
  defaultGammainPhotoModeToggle = "Default Gamma in Photo Mode",
  defaultGammainPhotoModeTooltip = "Set default gamma in Photo Mode.",
  showNotificaitonToggle = "Show Notification",
  showNotificaitonTooltip = "Disable it if you experience crashes when rapidly toggling settings.Current.",
  gammaNotChangedNotificaiton = " Gamma cannot be changed ",
  gammaSetToNotificaiton = " Gamma set to ",
  increaseGammaRegisterInput = "Increase Gamma",
  decreaseGammaRegisterInput = "Decrease Gamma",
}

local modDefaultLang = "en-us"

local FallbackBoard = {}

function Deepcopy(contents)
  if contents == nil then return contents end

  local contentsType = type(contents)
  local copy

  if contentsType == 'table' then
    copy = {}

    for key, value in next, contents, nil do
      copy[Deepcopy(key)] = Deepcopy(value)
    end

    setmetatable(copy, Deepcopy(getmetatable(contents)))
  else
    copy = contents
  end

  return copy
end

function SafeMergeTables(mergeTo, mergeA)
  if mergeA == nil then return mergeTo end

  for key, value in pairs(mergeA) do
    if mergeTo[key] ~= nil then -- Only proceed if the key exists in mergeTo
      if type(value) == "table" and type(mergeTo[key]) == "table" then
        mergeTo[key] = SafeMergeTables(mergeTo[key], value)
      else
        mergeTo[key] = value
      end
    end
  end

  return mergeTo
end

function SetFallback(owner, contents, key)
  local copiedContents = Deepcopy(contents)

  if key then
    FallbackBoard[owner] = FallbackBoard[owner] or {}
    FallbackBoard[owner][key] = copiedContents
  else
    FallbackBoard[owner] = copiedContents
  end
end

function GetFallback(owner, key)
  if FallbackBoard[owner] == nil then return nil end
  if key and FallbackBoard[owner] and FallbackBoard[owner][key] == nil then return nil end

  if key then
    return FallbackBoard[owner][key]
  else
    return FallbackBoard[owner]
  end
end

function Localization.GetUIText()
  return UIText
end

function Localization.GetOnScreenLanguage()
  return Game.NameToString(Game.GetSettingsSystem():GetVar("/language", "OnScreen"):GetValue())
end

local function GetNewLocalization(sourceTable, key, currentLang)
  if GetFallback("Localization", key) == nil then
    SetFallback("Localization", sourceTable, key)
  else
    sourceTable = SafeMergeTables(sourceTable, GetFallback("Localization", key))
  end

  local translationFile = "Translations/" .. currentLang .. ".lua"
  local chunk = loadfile(translationFile)

  if chunk then
    local translation = chunk()
    return SafeMergeTables(sourceTable, translation[key])
  else
    return sourceTable
  end
end

local function GetDefaultLocalization(sourceTable, key)
  local fallback = GetFallback("Localization", key)
  return fallback and SafeMergeTables(sourceTable, fallback) or sourceTable
end

function Localization.GetTranslation(sourceTable, key)
  local currentLang = Localization.GetOnScreenLanguage()

  if currentLang == modDefaultLang then return GetDefaultLocalization(sourceTable, key) end

  if currentLang == modDefaultLang then
    return GetDefaultLocalization(sourceTable, key)
  else
    return GetNewLocalization(sourceTable, key, currentLang)
  end
end

return Localization

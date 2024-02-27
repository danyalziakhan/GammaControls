local GameSettings = require('Modules/GameSettings')
local GameSession = require('Modules/GameSession')
local GameUI = require('Modules/GameUI')
local Cron = require('Modules/Cron')

local isPhoto = false
local isPopup = false
local isWeaponWheel = false
local isShard = false
local isTutorial = false

local minValue = 0.500
local maxValue = 2.000

local isOverlayOpen = false
local notificationVisible = false
local notificationSeconds = 1
local notificationText = ""
local r, g, b = 0.486, 0.988, 0

local configFileName = "config.json"
local settings = {
    value = 1.000,
    stepValue = 0.010,
    isDefaultGammainMenus = false,
    isEnabledNotification = true
}

function LoadSettings()
    local file = io.open(configFileName, "r")
    if file ~= nil then
        local configStr = file:read("*a")
        settings = json.decode(configStr)
        file:close()
    end
end

function SaveSettings()
    local file = io.open(configFileName, "w")
    if file ~= nil then
        local jconfig = json.encode(settings)
        file:write(jconfig)
        file:close()
    end
end

function Tooltip(text)
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.SetTooltip(text)
        ImGui.EndTooltip()
    end
end

function DrawNoti()
    ImGui.SetNextWindowPos(3, 3)
    ImGui.Begin("Notification", true,
        ImGuiWindowFlags.AlwaysAutoResize + ImGuiWindowFlags.NoMove + ImGuiWindowFlags.NoTitleBar +
        ImGuiWindowFlags.NoScrollbar)
    ImGui.TextColored(r, g, b, 1.0, notificationText)
    ImGui.End()
end

registerForEvent("onOverlayOpen", function()
    isOverlayOpen = true
end)

registerForEvent("onOverlayClose", function()
    isOverlayOpen = false
end)

registerForEvent("onDraw", function()
    if notificationVisible then
        DrawNoti()
        return
    end

    if not isOverlayOpen then
        return
    end

    ImGui.PushStyleVar(ImGuiStyleVar.WindowMinSize, 300, 40)
    ImGui.Begin("Gamma Controls", ImGuiWindowFlags.AlwaysAutoResize)

    local isGammaChanged = false
    local isStepValueChanged = false

    if settings.isDefaultGammainMenus then
        if not IsInMenu() and not isPopup and not isWeaponWheel and not isShard and not isTutorial then
            settings.value, isGammaChanged = ImGui.DragFloat(" Gamma ", settings.value, 0.001, minValue, maxValue, "%.3f",
                ImGuiSliderFlags.ClampOnInput)
            settings.stepValue, isStepValueChanged = ImGui.DragFloat(" Step Value ", settings.stepValue, 0.001, 0.001,
                0.1,
                "%.3f", ImGuiSliderFlags.ClampOnInput)
        else
            ImGui.Spacing()
            ImGui.Spacing()
            ImGui.PushStyleColor(ImGuiCol.Text, 1.0, 0.23, 0.23, 1.0)
            ImGui.Text("We are currently inside the Menu.")
            ImGui.Text("Gamma values can not be changed.")
            ImGui.Text("Uncheck \"Default Gamma in Menus\" if you want to change the values.")
            ImGui.PopStyleColor(1)
            ImGui.Spacing()
            ImGui.Spacing()

            _, _ = ImGui.DragFloat(" Gamma ", settings.value, 0.0, 0.0, 0.0)
            _, _ = ImGui.DragFloat(" Step Value ", settings.stepValue, 0.0, 0.0,
                0.0)
        end
    else
        settings.value, isGammaChanged = ImGui.DragFloat(" Gamma ", settings.value, 0.001, minValue, maxValue, "%.3f",
            ImGuiSliderFlags.ClampOnInput)
        settings.stepValue, isStepValueChanged = ImGui.DragFloat(" Step Value ", settings.stepValue, 0.001, 0.001,
            0.1,
            "%.3f", ImGuiSliderFlags.ClampOnInput)
    end

    if isGammaChanged then
        if settings.isDefaultGammainMenus then
            if not IsInMenu() and not isPopup and not isWeaponWheel and not isShard and not isTutorial then
                SetGamma(settings.value)
            end
        else
            SetGamma(settings.value)
        end
        SaveSettings()
    end

    if isStepValueChanged then
        SaveSettings()
    end

    ImGui.Spacing()
    if ImGui.Button(" Reset Defaults ") then
        if settings.isDefaultGammainMenus then
            if not IsInMenu() and not isPopup and not isWeaponWheel and not isShard and not isTutorial then
                settings.value = 1.000
                settings.stepValue = 0.010
                SaveSettings()
                SetGamma(1.000)
            end
        else
            settings.value = 1.000
            settings.stepValue = 0.010
            SaveSettings()
            SetGamma(1.000)
        end
    end

    ImGui.Spacing()
    settings.isDefaultGammainMenus, isDefaultGammainMenusChanged = ImGui.Checkbox("Default Gamma in Menus",
        settings.isDefaultGammainMenus)

    if isDefaultGammainMenusChanged then
        SaveSettings()
    end

    text =
    "Set default gamma on game settings, menu, phone popup, radio controls popup, vehicle call controls popup, weapon wheel, loading screen, read shard and tutorial popups."
    Tooltip(text)

    ImGui.Spacing()
    settings.isEnabledNotification, isNotificationSettingChanged = ImGui.Checkbox("Show Notification",
        settings.isEnabledNotification)

    if isNotificationSettingChanged then
        SaveSettings()
    end

    text = "Disable it if you experience crashes when rapidly toggling settings."
    Tooltip(text)

    ImGui.End()
    ImGui.PopStyleVar(1)
end)

function IsInMenu()
    local ui_System = Game.GetAllBlackboardDefs().UI_System
    return Game.GetBlackboardSystem():Get(ui_System):GetBool(ui_System.IsInMenu)
end

function GetGamma()
    return GameSettings.Get('/video/display/Gamma')
end

function SetGamma(value)
    GameSettings.Set('/video/display/Gamma', value)
end

function SetDefaultGamma()
    GameSettings.Set('/video/display/Gamma', 1.0)
end

function IncreaseGamma()
    if settings.isDefaultGammainMenus then
        if IsInMenu() or isPopup or isWeaponWheel or isShard or isTutorial then
            return
        end
    end

    local currentGamma = GetGamma()
    local newGamma = tonumber(string.format("%.3f", currentGamma + settings.stepValue))

    if newGamma <= maxValue then
        SetGamma(newGamma)
    end

    if settings.isEnabledNotification then
        notificationText = "Gamma set to " .. string.format("%.3f", (newGamma <= maxValue) and newGamma or currentGamma)
        notificationVisible = true
        Cron.After(notificationSeconds, function()
            notificationVisible = false
        end)
    end

    settings.value = newGamma
    SaveSettings()
end

function DecreaseGamma()
    if settings.isDefaultGammainMenus then
        if IsInMenu() or isPopup or isWeaponWheel or isShard or isTutorial then
            return
        end
    end

    local currentGamma = GetGamma()
    local newGamma = tonumber(string.format("%.3f", currentGamma - settings.stepValue))

    if newGamma >= minValue then
        SetGamma(newGamma)
    end

    if settings.isEnabledNotification then
        notificationText = "Gamma set to " .. string.format("%.3f", (newGamma >= minValue) and newGamma or currentGamma)
        notificationVisible = true
        Cron.After(notificationSeconds, function()
            notificationVisible = false
        end)
    end

    settings.value = newGamma
    SaveSettings()
end

registerForEvent('onInit', function()
    LoadSettings()

    -- Start Menu
    Observe('SingleplayerMenuGameController', 'OnInitialize', function()
        if settings.isDefaultGammainMenus then
            SetDefaultGamma()
        else
            SetGamma(settings.value)
        end
    end)

    GameUI.Listen("MenuNav", function(state)
        -- Set custom Gamma when inside Gamma correction screen
        if settings.isDefaultGammainMenus and state.submenu ~= nil and state.submenu == "Brightness" then
            SetGamma(settings.value)
        end
        if state.lastSubmenu ~= nil and state.lastSubmenu == "Brightness" then
            -- Reflect the new Gamma in the GUI after the user has set it on Gamma correction screen
            settings.value = GetGamma()
            SaveSettings()

            -- Set default Gamma when outside Gamma correction screen
            if settings.isDefaultGammainMenus then
                SetDefaultGamma()
            end
        end
    end)

    GameUI.Listen("PhotoModeOpen", function(_)
        isPhoto = true
    end)

    GameUI.Listen("PhotoModeClose", function(_)
        isPhoto = false
    end)

    GameSession.Listen("Pause", function(_)
        -- Set default Gamma in all Pause scenarios except during Photo mode because it's not desirable to set custom Gamma when taking screenshots
        if settings.isDefaultGammainMenus and not isPhoto then
            SetDefaultGamma()
        end
    end)

    GameSession.Listen("Resume", function(state)
        -- Since we are already listening to blurred events (popups, wheel, etc.), we don't need to change Gamma twice in such cases
        if settings.isDefaultGammainMenus and not state.wasBlurred then
            SetGamma(settings.value)
        end
    end)

    ObserveBefore('LoadingScreenProgressBarController', 'OnInitialize', function(_)
        if settings.isDefaultGammainMenus then
            SetDefaultGamma()
        end
    end)

    Observe('LoadingScreenProgressBarController', 'SetProgress', function(_, progress)
        -- for some fucking reason, the progress doesn't always set to 1.0 when loading is finished
        -- will change Gamma just before the loading screen is ended, but it's a small compromise
        if settings.isDefaultGammainMenus and progress > 0.91 then
            SetGamma(settings.value)
        end
    end)

    GameUI.Listen("PopupOpen", function(_)
        isPopup = true
        if settings.isDefaultGammainMenus then
            SetDefaultGamma()
        end
    end)

    GameUI.Listen("PopupClose", function(_)
        isPopup = false
        if settings.isDefaultGammainMenus then
            SetGamma(settings.value)
        end
    end)

    GameUI.Listen("WheelOpen", function(_)
        isWeaponWheel = true
        if settings.isDefaultGammainMenus then
            SetDefaultGamma()
        end
    end)

    GameUI.Listen("WheelClose", function(_)
        isWeaponWheel = false
        if settings.isDefaultGammainMenus then
            SetGamma(settings.value)
        end
    end)

    GameUI.Listen("ShardOpen", function(_)
        isShard = true
        if settings.isDefaultGammainMenus then
            SetDefaultGamma()
        end
    end)

    GameUI.Listen("ShardClose", function(_)
        isShard = false
        if settings.isDefaultGammainMenus then
            SetGamma(settings.value)
        end
    end)

    GameUI.Listen("TutorialOpen", function(_)
        isTutorial = true
        if settings.isDefaultGammainMenus then
            SetDefaultGamma()
        end
    end)

    GameUI.Listen("TutorialClose", function(_)
        isTutorial = false
        if settings.isDefaultGammainMenus then
            SetGamma(settings.value)
        end
    end)

    -- These are buggy/not consistent, so commenting them out for now just for the future reference
    -- GameUI.Listen("LoadingStart", function(state)
    -- end)

    -- GameUI.Listen("LoadingFinish", function(state)
    -- end)

    -- GameUI.Listen("FastTravelStart", function(state)
    -- end)

    -- GameUI.Listen("FastTravelFinish", function(state)
    -- end)
end)

registerForEvent('onUpdate', function(delta)
    -- This is required for Cron to function
    Cron.Update(delta)
end)

registerInput("GammaIncrease", "Increase Gamma", function(isKeyDown)
    if not isKeyDown then
        return
    end
    IncreaseGamma()
end)

registerInput("GammaDecrease", "Decrease Gamma", function(isKeyDown)
    if not isKeyDown then
        return
    end
    DecreaseGamma()
end)

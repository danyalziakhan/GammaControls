local GameSettings = require('Modules/GameSettings')
local GameUI = require('Modules/GameUI')
local Cron = require('Modules/Cron')

local isPhotoMode = false

local minValue = 0.500
local maxValue = 2.000

local isOverlayOpen = false
local notificationVisible = false
local notificationSeconds = 1
local notificationText = ""
local r, g, b = 0.486, 0.988, 0

local configFileName = "config.json"
local settings = {
    Current = {
        value = 1.000,
        stepValue = 0.010,
    },
    Preset = {
        value = 1.000,
        stepValue = 0.010,
    },
    isDefaultGammainMenus = false,
    isDefaultGammainPhotoMode = false,
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
    end

    if not isOverlayOpen then
        return
    end

    ImGui.Begin("Gamma Controls", ImGuiWindowFlags.AlwaysAutoResize)

    local isGammaChanged = false
    local isStepValueChanged = false

    if not settings.isDefaultGammainMenus and not settings.isDefaultGammainPhotoMode then
        settings.Current.value, isGammaChanged = ImGui.DragFloat(" Gamma ", settings.Current.value,
        settings.Current.stepValue, minValue,
        maxValue, "%.3f",
        ImGuiSliderFlags.ClampOnInput)
    settings.Current.stepValue, isStepValueChanged = ImGui.DragFloat(" Step Value ", settings.Current.stepValue,
        0.001, 0.001,
        0.1,
        "%.3f", ImGuiSliderFlags.ClampOnInput)
    elseif settings.isDefaultGammainMenus and not IsInMenu() and not settings.isDefaultGammainPhotoMode then
        settings.Current.value, isGammaChanged = ImGui.DragFloat(" Gamma ", settings.Current.value,
        settings.Current.stepValue, minValue,
        maxValue, "%.3f",
        ImGuiSliderFlags.ClampOnInput)
    settings.Current.stepValue, isStepValueChanged = ImGui.DragFloat(" Step Value ", settings.Current.stepValue,
        0.001, 0.001,
        0.1,
        "%.3f", ImGuiSliderFlags.ClampOnInput)
    elseif settings.isDefaultGammainPhotoMode and not isPhotoMode and not settings.isDefaultGammainMenus then
        settings.Current.value, isGammaChanged = ImGui.DragFloat(" Gamma ", settings.Current.value,
        settings.Current.stepValue, minValue,
        maxValue, "%.3f",
        ImGuiSliderFlags.ClampOnInput)
    settings.Current.stepValue, isStepValueChanged = ImGui.DragFloat(" Step Value ", settings.Current.stepValue,
        0.001, 0.001,
        0.1,
        "%.3f", ImGuiSliderFlags.ClampOnInput)
    elseif (settings.isDefaultGammainPhotoMode and not isPhotoMode) and (settings.isDefaultGammainMenus and not IsInMenu()) then
        settings.Current.value, isGammaChanged = ImGui.DragFloat(" Gamma ", settings.Current.value,
        settings.Current.stepValue, minValue,
        maxValue, "%.3f",
        ImGuiSliderFlags.ClampOnInput)
    settings.Current.stepValue, isStepValueChanged = ImGui.DragFloat(" Step Value ", settings.Current.stepValue,
        0.001, 0.001,
        0.1,
        "%.3f", ImGuiSliderFlags.ClampOnInput)
    end

    if settings.isDefaultGammainMenus then
        if IsInMenu() then
            ImGui.Spacing()
            ImGui.Spacing()
            ImGui.PushStyleColor(ImGuiCol.Text, 1.0, 0.23, 0.23, 1.0)
            ImGui.Text("We are currently inside the Menu.")
            ImGui.Text("Gamma values can not be changed.")
            ImGui.Text("Uncheck \"Default Gamma in Menus\" if you want to change the values.")
            ImGui.PopStyleColor(1)
            ImGui.Spacing()
            ImGui.Spacing()

            _, _ = ImGui.DragFloat(" Gamma ", settings.Current.value, 0.0)
            _, _ = ImGui.DragFloat(" Step Value ", settings.Current.stepValue, 0.0)
        end
    end
    if settings.isDefaultGammainPhotoMode then
        if isPhotoMode then
            ImGui.Spacing()
            ImGui.Spacing()
            ImGui.PushStyleColor(ImGuiCol.Text, 1.0, 0.23, 0.23, 1.0)
            ImGui.Text("We are currently inside the Photo Mode.")
            ImGui.Text("Gamma values can not be changed.")
            ImGui.Text("Uncheck \"Default Gamma in Photo Mode\" if you want to change the values.")
            ImGui.PopStyleColor(1)
            ImGui.Spacing()
            ImGui.Spacing()

            _, _ = ImGui.DragFloat(" Gamma ", settings.Current.value, 0.0)
            _, _ = ImGui.DragFloat(" Step Value ", settings.Current.stepValue, 0.0)
        end
    end

    if isGammaChanged then
        if settings.isDefaultGammainMenus and not IsInMenu() then SetGamma(settings.Current.value) end
        if settings.isDefaultGammainPhotoMode and not isPhotoMode then SetGamma(settings.Current.value) end
        if not settings.isDefaultGammainMenus and not settings.isDefaultGammainPhotoMode then SetGamma(settings.Current.value) end
        SaveSettings()
    end

    if isStepValueChanged then
        SaveSettings()
    end

    ImGui.Spacing()
    if ImGui.Button(" Save ") then
        settings.Preset.value = settings.Current.value
        settings.Preset.stepValue = settings.Current.stepValue
        SaveSettings()
    end

    ImGui.SameLine()
    if ImGui.Button(" Load ") then
        if not settings.isDefaultGammainMenus and not settings.isDefaultGammainPhotoMode then
            settings.Current.value = settings.Preset.value
            settings.Current.stepValue = settings.Preset.stepValue
            SaveSettings()
            SetGamma(settings.Current.value)
        elseif settings.isDefaultGammainMenus and not IsInMenu() then
            if settings.isDefaultGammainPhotoMode and not isPhotoMode then
                settings.Current.value = settings.Preset.value
                settings.Current.stepValue = settings.Preset.stepValue
                SaveSettings()
                SetGamma(settings.Current.value)
            elseif not settings.isDefaultGammainPhotoMode then
                settings.Current.value = settings.Preset.value
                settings.Current.stepValue = settings.Preset.stepValue
                SaveSettings()
                SetGamma(settings.Current.value)
            end
        elseif settings.isDefaultGammainPhotoMode and not isPhotoMode then
            if settings.isDefaultGammainMenus and not IsInMenu() then
                settings.Current.value = settings.Preset.value
                settings.Current.stepValue = settings.Preset.stepValue
                SaveSettings()
                SetGamma(settings.Current.value)
            elseif not settings.isDefaultGammainMenus then
                settings.Current.value = settings.Preset.value
                settings.Current.stepValue = settings.Preset.stepValue
                SaveSettings()
                SetGamma(settings.Current.value)
            end
        end
    end

    ImGui.Spacing()
    ImGui.Spacing()
    if ImGui.Button(" Reset Defaults ") then
        if not settings.isDefaultGammainMenus and not settings.isDefaultGammainPhotoMode then
            settings.Current.value = 1.000
            settings.Current.stepValue = 0.010
            SaveSettings()
            SetDefaultGamma()
        elseif settings.isDefaultGammainMenus and not IsInMenu() then
            if settings.isDefaultGammainPhotoMode and not isPhotoMode then
                settings.Current.value = 1.000
                settings.Current.stepValue = 0.010
                SaveSettings()
                SetDefaultGamma()
            elseif not settings.isDefaultGammainPhotoMode then
                settings.Current.value = 1.000
                settings.Current.stepValue = 0.010
                SaveSettings()
                SetDefaultGamma()
            end
        elseif settings.isDefaultGammainPhotoMode and not isPhotoMode then
            if settings.isDefaultGammainMenus and not IsInMenu() then
                settings.Current.value = 1.000
                settings.Current.stepValue = 0.010
                SaveSettings()
                SetDefaultGamma()
            elseif not settings.isDefaultGammainMenus then
                settings.Current.value = 1.000
                settings.Current.stepValue = 0.010
                SaveSettings()
                SetDefaultGamma()
            end
        end
    end

    ImGui.Spacing()
    settings.isDefaultGammainMenus, isDefaultGammainMenusChanged = ImGui.Checkbox("Default Gamma in Menus",
        settings.isDefaultGammainMenus)

    if isDefaultGammainMenusChanged then
        SaveSettings()
        if settings.isDefaultGammainMenus then
            if IsInMenu() then
                SetDefaultGamma()
            else
                if settings.isDefaultGammainPhotoMode and isPhotoMode then
                    SetDefaultGamma()
                else
                    SetGamma(settings.Current.value)
                end
            end
        else
            if settings.isDefaultGammainPhotoMode and isPhotoMode then
                SetDefaultGamma()
            else
                SetGamma(settings.Current.value)
            end
        end
    end

    text =
    "Set default gamma on game settings, menu, phone popup, radio controls popup, vehicle call controls popup, weapon wheel, loading screen, read shard and tutorial popups."
    Tooltip(text)

    ImGui.Spacing()
    settings.isDefaultGammainPhotoMode, isDefaultGammainPhotoModeChanged = ImGui.Checkbox("Default Gamma in Photo Mode",
        settings.isDefaultGammainPhotoMode)

    if isDefaultGammainPhotoModeChanged then
        SaveSettings()

        if settings.isDefaultGammainPhotoMode then
            if isPhotoMode then
                SetDefaultGamma()
            else
                if settings.isDefaultGammainMenus and IsInMenu() then
                    SetDefaultGamma()
                else
                    SetGamma(settings.Current.value)
                end
            end
        else
            if settings.isDefaultGammainMenus and IsInMenu() then
                SetDefaultGamma()
            else
                SetGamma(settings.Current.value)
            end
        end

    end

    text =
    "Set default gamma in Photo Mode."
    Tooltip(text)

    ImGui.Spacing()
    settings.isEnabledNotification, isNotificationSettingChanged = ImGui.Checkbox("Show Notification",
        settings.isEnabledNotification)

    if isNotificationSettingChanged then
        SaveSettings()
    end

    text = "Disable it if you experience crashes when rapidly toggling settings.Current."
    Tooltip(text)

    ImGui.End()
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
    if (settings.isDefaultGammainMenus and IsInMenu()) or (settings.isDefaultGammainPhotoMode and isPhotoMode) then
        if settings.isEnabledNotification then
            r, g, b = 1.0, 0.23, 0.23
            notificationText = " Gamma cannot be changed "
            notificationVisible = true
            Cron.After(notificationSeconds, function()
                notificationVisible = false
                r, g, b = 0.486, 0.988, 0
            end)
        end

        return
    end

    local currentGamma = GetGamma()
    local newGamma = tonumber(string.format("%.3f", currentGamma + settings.Current.stepValue))

    if newGamma <= maxValue then
        SetGamma(newGamma)
    end

    if settings.isEnabledNotification then
        notificationText = " Gamma set to " ..
        string.format("%.3f ", (newGamma <= maxValue) and newGamma or currentGamma)
        notificationVisible = true
        Cron.After(notificationSeconds, function()
            notificationVisible = false
        end)
    end

    settings.Current.value = newGamma
    SaveSettings()
end

function DecreaseGamma()
    if (settings.isDefaultGammainMenus and IsInMenu()) or (settings.isDefaultGammainPhotoMode and isPhotoMode) then
        if settings.isEnabledNotification then
            r, g, b = 1.0, 0.23, 0.23
            notificationText = " Gamma cannot be changed "
            notificationVisible = true
            Cron.After(notificationSeconds, function()
                notificationVisible = false
                r, g, b = 0.486, 0.988, 0
            end)
        end

        return
    end

    local currentGamma = GetGamma()
    local newGamma = tonumber(string.format("%.3f", currentGamma - settings.Current.stepValue))

    if newGamma >= minValue then
        SetGamma(newGamma)
    end

    if settings.isEnabledNotification then
        notificationText = " Gamma set to " ..
        string.format("%.3f ", (newGamma >= minValue) and newGamma or currentGamma)
        notificationVisible = true
        Cron.After(notificationSeconds, function()
            notificationVisible = false
        end)
    end

    settings.Current.value = newGamma
    SaveSettings()
end

registerForEvent('onInit', function()
    LoadSettings()

    GameUI.Listen("MenuNav", function(state)
        -- Set custom Gamma when inside Gamma correction screen
        if settings.isDefaultGammainMenus and state.submenu ~= nil and state.submenu == "Brightness" then
            SetGamma(settings.Current.value)
        end
        if state.lastSubmenu ~= nil and state.lastSubmenu == "Brightness" then
            -- Reflect the new Gamma in the GUI after the user has set it on Gamma correction screen
            settings.Current.value = GetGamma()
            SaveSettings()

            -- Set default Gamma when outside Gamma correction screen
            if settings.isDefaultGammainMenus then
                SetDefaultGamma()
            end
        end
    end)

    -- Start Menu
    Observe('SingleplayerMenuGameController', 'OnInitialize', function()
        if settings.isDefaultGammainMenus then
            SetDefaultGamma()
        else
            SetGamma(settings.Current.value)
        end
    end)

    -- Different menus (inventory, map, etc.)
    Observe('gameuiPopupsManager', 'OnMenuUpdate', function(_, IsInMenu)
        if IsInMenu then
            if settings.isDefaultGammainMenus then
                SetDefaultGamma()
            end
        else
            if settings.isDefaultGammainMenus then
                SetGamma(settings.Current.value)
            end
        end
    end)

    -- Set default Gamma in all Pause scenarios except during Photo mode because it's not desirable to set custom Gamma when taking screenshots
    Observe('gameuiPhotoModeMenuController', 'OnShow', function()
        isPhotoMode = true
        if settings.isDefaultGammainPhotoMode then
            SetDefaultGamma()
        end
    end)

    Observe('gameuiPhotoModeMenuController', 'OnHide', function()
        isPhotoMode = false
        if settings.isDefaultGammainPhotoMode then
            SetGamma(settings.Current.value)
        end
    end)

    Observe('gameuiTutorialPopupGameController', 'PauseGame', function(_, isTutorialActive)
        if isTutorialActive then
            if settings.isDefaultGammainMenus then
                SetDefaultGamma()
            end
        else
            if settings.isDefaultGammainMenus then
                SetGamma(settings.Current.value)
            end
        end
    end)

    -- Weapon Wheel
    Observe('RadialWheelController', 'OnOpenWheelRequest', function(_, _)
        if settings.isDefaultGammainMenus then
            SetDefaultGamma()
        end
    end)

    Observe('RadialWheelController', 'Shutdown', function(_, _)
        if settings.isDefaultGammainMenus then
            SetGamma(settings.Current.value)
        end
    end)

    -- Observe('VehicleRadioPopupGameController', 'OnInitialize', function(_, _)
    --     if settings.isDefaultGammainMenus then
    --         SetDefaultGamma()
    --     end
    -- end)

    -- Vehicle and Radio menu
    Observe('VehicleRadioPopupGameController', 'OnClose', function(_, _)
        if settings.isDefaultGammainMenus then
            SetGamma(settings.Current.value)
        end
    end)

    Observe('VehiclesManagerPopupGameController', 'OnInitialize', function(_, _)
        if settings.isDefaultGammainMenus then
            SetDefaultGamma()
        end
    end)

    Observe('VehiclesManagerPopupGameController', 'OnClose', function(_, _)
        if settings.isDefaultGammainMenus then
            SetGamma(settings.Current.value)
        end
    end)

    -- Phone dialer
    Observe('NewHudPhoneGameController', 'OnContactListSpawned', function(_, _)
        if settings.isDefaultGammainMenus then
            SetDefaultGamma()
        end
    end)

    Observe('NewHudPhoneGameController', 'OnContactListClosed', function(_, _)
        if settings.isDefaultGammainMenus then
            SetGamma(settings.Current.value)
        end
    end)

    Observe('FastTravelSystem', 'OnLoadingScreenFinished', function(_, _)
        if settings.isDefaultGammainMenus then
            SetGamma(settings.Current.value)
        end
    end)

    Observe('LoadingScreenProgressBarController', 'OnInitialize', function(_)
        if settings.isDefaultGammainMenus then
            SetDefaultGamma()
        end
    end)

    Observe('LoadingScreenProgressBarController', 'SetProgress', function(_, progress)
        -- for some fucking reason, the progress doesn't always set to 1.0 when loading is finished
        -- will change Gamma just before the loading screen is ended, but it's a small compromise
         if progress > 0.91 then
            if settings.isDefaultGammainMenus then
                SetGamma(settings.Current.value)
            end
        end
    end)

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

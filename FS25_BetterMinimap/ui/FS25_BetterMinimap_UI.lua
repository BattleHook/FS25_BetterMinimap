--
-- Mod: FS25_BetterMinimap
--
-- Author: original  FS17:jDanek; FS25:SupremeClicker
-- email: gvdhaak (at) gmail (dot) com
-- @Date: 28.02.2025
-- @Version: 1.0.0.0

-- TODO: NOTE:Total lua script has to be debugged togetheer with UI xml.

local myName = "FS25_BetterMinimap_UI"

-- FS25_BetterMinimap_UI: Handles UI interactions for FS25 Better Minimap

source(g_currentModDirectory .. "lib/DialogHelper.lua")

FS25_BetterMinimap_UI = {}
local FS25_BetterMinimap_UI_mt = Class(FS25_BetterMinimap_UI, ScreenElement)

--- Constructor for the UI screen.
function FS25_BetterMinimap_UI:new(target, custom_mt)
    if custom_mt == nil then
        custom_mt = FS25_BetterMinimap_UI_mt
    end
    local self = ScreenElement:new(target, custom_mt)
    self.returnScreenName = ""
    return self
end

--- Called when the UI screen opens.
function FS25_BetterMinimap_UI:onOpen()
    FS25_BetterMinimap_UI:superClass().onOpen(self)
    
    -- Populate dropdown with refresh rate options
    self.refreshRateDropdown:setTexts({"15s", "30s", "45s", "60s"})
    
    -- Set currently selected refresh rate
    local currentRate = tostring(FS25_BetterMinimap.config.refreshRate) .. "s"
    for i, option in ipairs({"15s", "30s", "45s", "60s"}) do
        if option == currentRate then
            self.refreshRateDropdown:setState(i)
            break
        end
    end
end

--- Called when the user selects a new refresh rate.
function FS25_BetterMinimap_UI:onRefreshRateChange(element)
    local selectedIndex = element:getState()
    local refreshOptions = {15, 30, 45, 60}
    FS25_BetterMinimap.config.refreshRate = refreshOptions[selectedIndex]
end

--- Saves the new settings and closes the UI.
function FS25_BetterMinimap_UI:onSaveSettings()
    DialogHelper:showConfirmationDialog("Save Changes", "Do you want to save the new minimap settings?",
            function()
                FS25_BetterMinimap:saveSettings()
                g_gui:closeGui()
            end
        )
end

--- Closes the UI without saving changes.
function FS25_BetterMinimap_UI:onClose()
    g_gui:closeGui()
end

--
-- Mod: FS25_BetterMinimap
--
-- Author: original  FS17:jDanek; FS25: SupremeClicker
-- email: gvdhaak (at) gmail (dot) com
-- @Date: 28.02.2025
-- @Version: 1.0.0.0
--[[
CHANGELOG

TODO: - Change the size of the minimap (normal / wide / larger)
TODO: - Remembers the selected size during play
TODO: - Switching transparency
TODO: - Zoom in and out of the minimap

TODO: Settings Utils
TODO: Sounds when changing modes and refreshing
]] --

local myName = "FS25_BetterMinimap"

FS25_BetterMinimap = Mod:init()

--- Initializes settings, keybindings, and UI elements before the map loads.
function FS25_BetterMinimap:beforeLoadMap()
end

--- Called when the map has finished loading.
function FS25_BetterMinimap:loadMap(filename)
    Log:info("--> loaded  <--")
    if g_inputBinding then
        self:registerActionEvents()
    else
        Log:error("loadMap: g_inputBinding is NIL! Cannot register keybindings!")
    end

    Log:info("Initializing settings")
    self:initializeSettings()
    self.lastUpdateTime = 0
end

--- Initializes settings by ensuring files exist and loading values from XML.
function FS25_BetterMinimap:initializeSettings()
    if ModSettings then -- Ensure ModSettings is available before using it
        self.settings = ModSettings:new(self)
        self.settings:init("FS25_BetterMinimap", "defaultSettings.xml", "userSettings.xml")
        self.settings:load(function(xmlReader)
            self.config = {
                visible = xmlReader:readBool("settings", "visible", true),
                minimapMode = xmlReader:readInt("settings", "minimapMode", 2), -- Default to 2 FruitType Mode
                refreshRate = xmlReader:readInt("settings", "refreshRate", 60) -- Default to 60 seconds
            }
            Log:info("LOADED SETTINGS: minimapMode = " .. tostring(self.config.minimapMode))
        end)
    else
        Log:warning("ModSettings not available, applying default settings.")
        self.config = {
            visible = true,
            minimapMode = 2,
            refreshRate = 60
        }
    end
end

--- Called when the mission starts.
function FS25_BetterMinimap:startMission()
    FS25_BetterMinimap_Debug:runAllChecks()
    self:registerActionEvents()
    Log:info("Mission started.")
end

--- Modifies the minimap to display overlays for different states such as fruit type, growth stage, soil state, fertilizer, plowing, and lime.
function FS25_BetterMinimap:modifyDefaultMinimap()
    Log:info("modifyDefaultMinimap called ...") -- NOTE: for development only
    Log:trace("Applying minimap mode: " .. self.config.minimapMode)
    local overlay = g_currentMission.hud.ingameMap.mapOverlay
    if overlay then
        local modeToOverlay = {
            [2] = MapOverlayGenerator.OVERLAY_FRUIT_TYPES, -- FruitType Mode
            [3] = MapOverlayGenerator.OVERLAY_GROWTH,      -- GrowthStage Mode
            [4] = MapOverlayGenerator.OVERLAY_SOIL,        -- SoilState Mode
            [5] = MapOverlayGenerator.OVERLAY_FERTILIZER,  -- Fertilizer Mode
            [6] = MapOverlayGenerator.OVERLAY_PLOWING,     -- Plowing Mode
            [7] = MapOverlayGenerator.OVERLAY_LIME         -- Lime Mode
        }

        local overlayType = modeToOverlay[self.config.minimapMode]
        if overlayType then
            Log:info("Setting overlay type: " .. overlayType)
            if overlay.setOverlayType then
                overlay:setOverlayType(overlayType)
            elseif overlay.applyOverlay then
                overlay:applyOverlay(overlayType)
            else
                Log:error("No valid overlay function found in mapOverlay!")
            end
        else
            Log:error("Invalid minimap mode selected!")
        end
    else
        Log:warning("overlay is nil. Cannot apply overlay.")
    end
end

--- Registers keybindings for minimap controls.
function FS25_BetterMinimap:registerActionEvents()
    local actions = {
        "FS25_BetterMinimap_SHOW_CONFIG_GUI",
        "FS25_BetterMinimap_RELOAD",
        "FS25_BetterMinimap_PREV",
        "FS25_BetterMinimap_NEXT"
    }
    for _, action in pairs(actions) do
        local _, eventId = g_inputBinding:registerActionEvent(action, self, self.onActionEvent, false, true, false, true)
        if eventId then
            g_inputBinding:setActionEventTextVisibility(eventId, true)
            Log:trace("Registered action event: " .. action)
        else
            Log:trace("Failed to register action event: " .. action)
        end
    end
end

--- Handles keybinding events for minimap actions.
function FS25_BetterMinimap.onActionEvent(actionName, keyStatus)
    Log:trace("Action Triggered: " .. actionName)
    if actionName == "FS25_BetterMinimap_SHOW_CONFIG_GUI" then
        -- Open configuration UI
    elseif actionName == "FS25_BetterMinimap_RELOAD" then
        Log:info("RELOAD key pressed, refreshing")
        FS25_BetterMinimap:modifyDefaultMinimap()
    elseif actionName == "FS25_BetterMinimap_PREV" then
        Log:info("PREV key pressed, changing mode")
        FS25_BetterMinimap:changeMode(-1)
    elseif actionName == "FS25_BetterMinimap_NEXT" then
        Log:info("NEXT key pressed, changing mode")
        FS25_BetterMinimap:changeMode(1)
    end
    FS25_BetterMinimap:saveSettings()
end

--- Changes the minimap mode based on user input.
function FS25_BetterMinimap:changeMode(direction)
    local numModes = 7 -- Number of available modes
    local oldMode = self.config.minimapMode
    self.config.minimapMode = math.max(2, math.min(self.config.minimapMode + direction, numModes))
    Log:info("minimapMode Changed: " .. oldMode .. "->" .. self.config.minimapMode)
    self:modifyDefaultMinimap()
end

--- Saves the current settings to userSettings.xml.
function FS25_BetterMinimap:saveSettings()
    if self.settings then
        self.settings:save(function(xmlWriter)
            xmlWriter:saveBool("settings", "visible", self.config.visible)
            xmlWriter:saveInt("settings", "minimapMode", self.config.minimapMode)
            xmlWriter:saveInt("settings", "refreshRate", self.config.refreshRate)
        end)
    end
end

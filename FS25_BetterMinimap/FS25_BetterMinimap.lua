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
TODO: Sounds when changing modes en refreshing

]] --

local myName = "FS25_BetterMinimap"

FS25_BetterMinimap = Mod:init()

--- TODO: Load the UI Lua script
--- TODO: FS25_BetterMinimap:source("ui/FS25_BetterMinimap_UI.lua")

--- Called before the map loads; initializes settings, keybindings, and UI elements.
function FS25_BetterMinimap:beforeLoadMap() -- Super early event, caution!
end--function

function FS25_BetterMinimap:loadMap(filename) -- Executed when the map has finished loading, a good place to begin your mod initialization
    -- print("--> loaded FS25_BetterMinimap version " .. modDescVersion .. " (by SupremeClicker) <--")
    Log:info("--> loaded FS25_BetterMinimap (by SupremeClicker) <--")
    --replaces the default minimap
    --self:disableDefaultMinimap()
    self:initializeSettings()
    -- TODO: self:initializeUI()
    self:registerActionEvents()
    self:modifyDefaultMinimap()
    self.lastUpdateTime = 0
    --FSBaseMission.draw = Utils.appendedFunction(FSBaseMission.draw, FS25_BetterMinimap.drawCustomMinimap) --not implemented
end--function

--- TODO: Initializes the UI elements for the minimap.
function FS25_BetterMinimap:initializeUI()
    if g_gui ~= nil then
        self.minimapUI = g_gui:loadGui(g_currentModDirectory .. "ui/FS25_BetterMinimap_UI.xml", "FS25BetterMinimapUI", FS25_BetterMinimap_UI)
        self.minimapUIScreen = FS25_BetterMinimap_UI:new(nil)
    end
end

function FS25_BetterMinimap:beforeStartMission()
    -- When user selects "Start" (but as early as possible in that event chain)
end--function

function FS25_BetterMinimap:startMission()
    -- When user selects "Start"
end--function

--- Disables the default Farming Simulator minimap.
--- NOTE:not implemented
function FS25_BetterMinimap:disableDefaultMinimap()
    if g_currentMission.hud and g_currentMission.hud.ingameMap then
        g_currentMission.hud.ingameMap:setVisible(false)
    end
end

--- Modifies the default minimap to display overlays for fruit type, growth stage, or soil state.
function FS25_BetterMinimap:modifyDefaultMinimap()
    local function onOverlayGenerated(overlayId)
        Log:debug("Overlay generated successfully: " .. tostring(overlayId))
    end

    if g_currentMission.hud.ingameMap.setOverlayType ~= nil then
        if self.config.minimapMode == 2 then -- FruitType Mode
            g_currentMission.hud.ingameMap:setOverlayType("FRUIT")
       elseif self.config.minimapMode == 3 then -- GrowthStage Mode
           g_currentMission.hud.ingameMap:setOverlayType("GROWTH")
       elseif self.config.minimapMode == 4 then -- SoilState Mode
           g_currentMission.hud.ingameMap:setOverlayType("SOIL")
       end
    else
        Log:warning("FS25_BetterMinimap: setOverlayType method not found!")
    end
end


--- Draws the custom FS25 minimap.
--- NOTE:not implemented
function FS25_BetterMinimap:drawCustomMinimap() 
    if self.config.visible then
        -- Replace this with Farming Simulator GUI rendering logic
        renderText(0.8, 0.8, 0.02, "FS25 Minimap Active")
    end
end

--- Toggles the FS25 minimap visibility.
--- NOTE:not implemented
function FS25_BetterMinimap:toggleMinimap() 
    self.config.visible = not self.config.visible
    Log:info("FS25 Minimap visibility toggled: " .. tostring(self.config.visible))
    self:saveSettings()
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
        local _, eventId = g_inputBinding:registerActionEvent(action, self, FS25_BetterMinimap.onActionEvent, false, true, false, true)
        if eventId then
            g_inputBinding:setActionEventTextVisibility(eventId, true)
        end
    end
    local _, eventId = g_inputBinding:registerActionEvent("MINIMAP_TOGGLE", self, FS25_BetterMinimap.toggleMinimap, false, true, false, true)
    g_inputBinding:setActionEventTextVisibility(eventId, false)
end

--- Handles keybinding events for minimap actions.
function FS25_BetterMinimap.onActionEvent(actionName, keyStatus)
    if actionName == "FS25_BetterMinimap_SHOW_CONFIG_GUI" then
        -- TODO: FS25_BetterMinimap:toggleConfigMenu()
    elseif actionName == "FS25_BetterMinimap_RELOAD" then
        FS25_BetterMinimap:modifyDefaultMinimap()
    elseif actionName == "FS25_BetterMinimap_PREV" then
        FS25_BetterMinimap:changeMode(-1)
    elseif actionName == "FS25_BetterMinimap_NEXT" then
        FS25_BetterMinimap:changeMode(1)
    end
    FS25_BetterMinimap:saveSettings()
end

--- Changes the minimap mode based on user input.
function FS25_BetterMinimap:changeMode(direction)
    local numModes = 4  -- Number of available modes
    self.config.minimapMode = (self.config.minimapMode + direction - 1) % numModes + 1
    self:modifyDefaultMinimap()
end

--- Initializes settings by ensuring files exist and loading values from XML.
function FS25_BetterMinimap:initializeSettings()
    if ModSettings then -- Ensure ModSettings is available before using it
        self.settings = ModSettings:new(self)
        self.settings:init("FS25_BetterMinimap", "defaultSettings.xml", "userSettings.xml")
        self.settings:load(function(xmlReader)
            self.config = {
                visible = xmlReader:readBool("settings", "visible", true),
                minimapMode = xmlReader:readInt("settings", "minimapMode", 1),
                refreshRate = xmlReader:readInt("settings", "refreshRate", 60) -- Default to 60 seconds
            }
        end)
    else
        Log:warning("ModSettings not available, applying default settings.") --NOTE: FIXED
        self.config = { -- Apply default settings if ModSettings is missing
            visible = true,
            minimapMode = 1,
            refreshRate = 60
        }
    end
end--function

--- TODO: Opens/closes the configuration UI for the minimap.
function FS25_BetterMinimap:toggleConfigMenu()
    Log:info("Opening Configuration UI")
        if self.minimapUIScreen ~= nil then
        g_gui:showGui("FS25BetterMinimapUI")
    else
        Log:warning("UI Screen is not initialized!")
    end
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

function FS25_BetterMinimap:update(dt)
    -- Looped as long game is running (CAUTION! Can severely impact performance if not used properly)
    --- Updates the minimap refresh cycle.
    if self.config.minimapMode ~= 1 then -- Only refresh when not in BaseGame mode
        self.lastUpdateTime = self.lastUpdateTime + dt
        local timeLeft = math.ceil((self.config.refreshRate * 1000 - self.lastUpdateTime) / 1000)
        
        -- Render text below minimap
        setTextAlignment(RenderText.ALIGN_LEFT)
        setTextBold(false)
        setTextColor(1, 1, 1, 1) -- White color
        renderText(0.85, 0.15, 0.02, string.format("%02ds", timeLeft))
        
        local modeText = {"", "Fruit", "Growth", "Soil"}
        renderText(0.85, 0.12, 0.02, modeText[self.config.minimapMode])
        
        if self.lastUpdateTime >= self.config.refreshRate * 1000 then
            self:modifyDefaultMinimap()
            self.lastUpdateTime = 0
        end
    end
end --function

--
-- Mod: FS25_BetterMinimap
--
-- Author: original  FS17:jDanek; FS25: SupremeClicker
-- email: gvdhaak (at) gmail (dot) com
-- @Date: 22.02.2025
-- @Version: 1.0.0.0
--[[
CHANGELOG


]] --
local myName = "FS25_BetterMinimap"

FS25_BetterMinimap = {}

addModEventListener(FS25_BetterMinimap)
local FS25_BetterMinimap_mt = Class(FS25_BetterMinimap)

-- #############################################################################

function FS25_BetterMinimap:new(mission, modDirectory, modName, i18n, gui, inputManager, messageCenter)
    if debug > 1 then
        print("-> " .. myName .. ": new ")
    end

    local self = {}

    setmetatable(self, FS25_BetterMinimap_mt)

    self.mission = mission
    self.modDirectory = modDirectory
    self.modName = modName
    self.i18n = i18n
    self.gui = gui
    self.inputManager = inputManager
    self.messageCenter = messageCenter

    local modDesc = loadXMLFile("modDesc", modDirectory .. "modDesc.xml")
    self.version = getXMLString(modDesc, "modDesc.version")

    self.mapEvents = {}

    --- Constants ---
    self.const = {}
    -- self.const.settings_file = modDirectory .. "../modSettings/FS25_BetterMinimap_Settings.xml"
    self.const.frequency = {15, 30, 45, 60} -- refresh frequency (in sec)
    self.const.mapSizes = {{456, 350}, {800, 350}, {800, 600}} -- minimap sizes {width, height}
    self.const.mapNames = {g_i18n:getText("gui_FS25_BetterMinimap_MAPSIZE_N"),
                           g_i18n:getText("gui_FS25_BetterMinimap_MAPSIZE_W"),
                           g_i18n:getText("gui_FS25_BetterMinimap_MAPSIZE_L")}
    self.const.transparent = {0.3, 0.5, 0.7}

    --- Settings ---
    self.settings = {}

    self.visible = true
    self.help_min = true
    self.frequency = 4
    self.sizeMode = 1
    self.transparent = false
    self.transMode = 3

    self.settings.init = false
    self.settings.mapUpdate = false
    self.settings.saveConfig = false
    self.settings.help_full = false
    self.settings.fullscreen = false
    self.settings.state = 0

    self.overlayPosX = 0.02
    self.overlayPosY = 0.04
    self.zoomFactor = 0.0007
    self.visWidth = 0.3

    self.pixelWidth = (1 / 3) / 1024.0
    self.pixelHeight = self.pixelWidth * g_screenAspectRatio

    -- set default map properties
    self.mapWidth = self.const.mapSizes[self.sizeMode][1] * self.pixelWidth
    self.mapHeight = self.const.mapSizes[self.sizeMode][2] * self.pixelHeight

    -- some global stuff - DONT touch
    FS25_BetterMinimap.actions = {"FS25_BetterMinimap_SHOW_CONFIG_GUI", "FS25_BetterMinimap_TOGGLE_HELP",
                                  "FS25_BetterMinimap_RELOAD", "FS25_BetterMinimap_NEXT", "FS25_BetterMinimap_PREV",
                                  "FS25_BetterMinimap_ZOOM_IN", "FS25_BetterMinimap_ZOOM_OUT"}

    -- for key press delay
    FS25_BetterMinimap.nextActionTime = 0
    FS25_BetterMinimap.deltaActionTime = 500
    FS25_BetterMinimap.minActionTime = 31.25

    -- some colors
    FS25_BetterMinimap.color = {
        black = {0, 0, 0, 1},
        white = {1, 1, 1, 1},
        red = {255 / 255, 0 / 255, 0 / 255, 1}, -- #ff0000
        darkred = {128 / 255, 0 / 255, 0 / 255, 1}, -- #800000
        green = {0 / 255, 255 / 255, 0 / 255, 1}, -- #00ff00
        blue = {0 / 255, 0 / 255, 255 / 255, 1}, -- #0000ff
        yellow = {255 / 255, 255 / 255, 0 / 255, 1}, -- #ffff00
        gray = {128 / 255, 128 / 255, 128 / 255, 1}, -- #808080
        lgray = {178 / 255, 178 / 255, 178 / 255, 1}, -- #b2b2b2
        dmg = {255 / 255, 174 / 255, 0 / 255, 1}, -- #ffae00
        fuel = {178 / 255, 214 / 255, 22 / 255, 1}, -- #b2d616
        adblue = {48 / 255, 78 / 255, 249 / 255, 1}, -- #304ef9
        electric = {255 / 255, 255 / 255, 0 / 255, 1}, -- #ffff00
        methane = {0 / 255, 198 / 255, 255 / 255, 1}, -- #00c6ff
        fs19orange = {253 / 255, 99 / 255, 3 / 255, 1}, -- #fd6303
        fs22blue = {0 / 255, 198 / 255, 253 / 255, 1}, -- #00c6fd
        fs25green = {60 / 255, 118 / 255, 0 / 255, 1} -- #3c7600
    }
    -- load sound effects
    --[[
    if g_dedicatedServerInfo == nil then
        local file, id
        FS25_BetterMinimap.sounds = {}
        for _, id in ipairs({"mouseclick", "refresh", "zoom"}) do
            FS25_BetterMinimap.sounds[id] = createSample(id)
            file = self.modDirectory .. "resources/" .. id .. ".ogg"
            loadSample(FS25_BetterMinimap.sounds[id], file, false)
        end
    end
    --]]
    return self
end

--- Better Minimap Methods ---

function FS25_BetterMinimap:delete()
    if debug > 1 then
        print("-> " .. myName .. ": delete ")
    end
    -- delete our UI
    FS25_BetterMinimap.ui_menu:delete()
end

-- #############################################################################

function FS25_BetterMinimap:onMissionLoaded(mission)
    if debug > 1 then
        print("-> " .. myName .. ": onMissionLoaded ")
    end
    -- create configuration dialog
    FS25_BetterMinimap.ui_menu = FS25_BetterMinimap_UI.new()
    g_gui:loadGui(self.modDirectory .. "ui/FS25_BetterMinimap_UI.xml", "FS25_BetterMinimap_UI",
        FS25_BetterMinimap.ui_menu)
end

-- #############################################################################

function FS25_BetterMinimap:loadMap()
    -- print("--> loaded FS25_BetterMinimap version " .. modDescVersion .. " (by SupremeClicker) <--")
    print("--> loaded FS25_BetterMinimap (by SupremeClicker) <--")
    -- first set our current and default config to default values
    FS25_BetterMinimap:resetConfig()
    -- then read values from disk and "overwrite" current config
    lC:readConfig()
    -- then write current config (which is now a merge between default values and from disk)
    lC:writeConfig()
    -- and finally activate current config
    FS25_BetterMinimap:activateConfig()
    Enterable.onRegisterActionEvents = Utils.appendedFunction(Enterable.onRegisterActionEvents,
        FS25_BetterMinimap.registerActionEvents);

end

-- #############################################################################

function FS25_BetterMinimap:unloadMap()
    -- print("--> unloaded FS25_BetterMinimap version " .. modDescVersion .. " (by SupremeClicker) <--")
    print("--> unloaded FS25_BetterMinimap (by SupremeClicker) <--")
end

-- #############################################################################

function FS25_BetterMinimap.prerequisitesPresent(specializations)
    if debug > 1 then
        print("-> " .. myName .. ": prerequisites ")
    end

    return true
end

-- #############################################################################

function FS25_BetterMinimap:onLoad(savegame)
    if debug > 1 then
        print("-> " .. myName .. ": onLoad" .. mySelf(self))
    end
end

-- #############################################################################

function FS25_BetterMinimap:onUpdate(dt)
    if debug > 2 then
        print("-> " .. myName .. ": onUpdate " .. dt .. ", S: " .. tostring(self.isServer) .. ", C: " ..
                  tostring(self.isClient) .. mySelf(self))
    end

    -- activate mod if not activated
    if (not self.settings.init) then
        self.settings.init = true
        -- was:g_currentMission.ingameMap.state = IngameMap.STATE_MINIMAP
        g_currentMission.hud.ingameMap.state = IngameMap.STATE_MINIMAP
        self:show()
    end

    -- TARDIS mod compatibility
    if g_modIsLoaded["FS25_TARDIS"] then
        if (g_currentMission.tardisBase.tardisOn ~= nil and self.settings.fullscreen) then
            self:hide()
        else
            g_currentMission.hud.ingameMap.state = IngameMap.STATE_MINIMAP
            self:show()
        end
    end
    -- was:local ingameMap = g_currentMission.ingameMap
    local ingameMap = g_currentMission.hud.ingameMap

    if (g_gui:getIsGuiVisible() and g_gui.currentGuiName == "InGameMenu") then
        self.needUpdateFruitOverlay = true
    end

    if (self.timer < (self.const.frequency[self.frequency] * 1000)) then
        self.timer = self.timer + dt
    else
        self.needUpdateFruitOverlay = true
    end
    if (self.settings.init and g_gui.currentGui == nil) then
        if (self.help_min) then
            g_InputBinding:setActionEventTextVisibility(actionName, true)
            g_InputBinding:setActionEventTextPriority(actionName, GS_PRIO_HIGH)
        end
        -- update overlay
        if (self.needUpdateFruitOverlay) then
            self.needUpdateFruitOverlay = false
            self:generateFruitOverlay()
        end
        -- refresh map properties by settings
        if (self.settings.mapUpdate) then
            self:renderSelectedMinimap()
        end
        -- save settings to XML
        if (self.settings.saveConfig) then
            self:saveConfig()
        end
    end
end

-- #############################################################################

function FS25_BetterMinimap:registerActionEvents()
    if debug > 1 then
        print("-> " .. myName .. ": registerActionEvents, S: " .. tostring(self.isServer) .. ", C: " ..
                  tostring(self.isClient) .. mySelf(self))
    end

    -- continue on client side only
    if not self.isClient then -- or not self:getIsActiveForInput(true, true)
        return
    end
    -- assemble list of actions to attach
    local actionList = FS25_BetterMinimap.actions

    FS25_BetterMinimap.events = {}

    local function registerMinimapAction(actionName)
        local result, eventName = g_inputBinding:registerActionEvent(actionName, self, FS25_BetterMinimap.onActionCall,
            false, true, false, true)
        if result then
            table.insert(FS25_BetterMinimap.events, eventName)
            FS25_BetterMinimap:helpMenuPrio(actionName, eventName)
        end
    end

    -- registreren van elke actie
    for i = 1, #actionList do
        registerMinimapAction(actionList[i])
    end

end

-- #############################################################################

function FS25_BetterMinimap:helpMenuPrio(actionName, eventName)
    -- help menu priorization
    if g_inputBinding ~= nil and g_inputBinding.events ~= nil and g_inputBinding.events[eventName] ~= nil then
        if actionName == "FS25_BetterMinimap_SHOW_CONFIG_GUI" or actionName == "FS25_BetterMinimap_TOGGLE_HELP" or
            actionName == "FS25_BetterMinimap_RELOAD" or actionName == "FS25_BetterMinimap_NEXT" or actionName ==
            "FS25_BetterMinimap_PREV" or actionName == "FS25_BetterMinimap_ZOOM_IN" or actionName ==
            "FS25_BetterMinimap_ZOOM_OUT" then
            g_inputBinding:setActionEventTextVisibility(eventName, true)
            g_inputBinding:setActionEventTextPriority(eventName, GS_PRIO_VERY_LOW)
        else
            g_inputBinding:setActionEventTextVisibility(eventName, false)
            g_inputBinding:setActionEventTextPriority(eventName, GS_PRIO_VERY_LOW)
        end
    end
    -- GS_PRIO_VERY_HIGH = 1
    -- GS_PRIO_HIGH = 2
    -- GS_PRIO_NORMAL = 3
    -- GS_PRIO_LOW = 4
    -- GS_PRIO_VERY_LOW = 5
end

-- #############################################################################

function FS25_BetterMinimap:onActionCall(actionName, keyStatus, arg4, arg5, arg6)
    if debug > 1 then
        print("-> " .. myName .. ": onActionCall " .. actionName .. ", keyStatus: " .. keyStatus .. mySelf(self))
    end
    if debug > 2 then
        print(arg4)
        print(arg5)
        print(arg6)
    end
    if actionName == "FS25_BetterMinimap_CONFIG_GUI" then
        if not self.isClient then
            return
        end
        if not g_currentMission.isSynchronizingWithPlayers then
            if not g_gui:getIsGuiVisible() then
                FS25_BetterMinimap.ui_menu:setVehicle(self)
                g_gui:showDialog("FS25_BetterMinimap_UI")
            end
        end
    elseif actionName == "FS25_BetterMinimap_TOGGLE_HELP" then
        self.settings.help_full = not self.settings.help_full
    elseif actionName == "FS25_BetterMinimap_RELOAD" then
        self.needUpdateFruitOverlay = true
    elseif actionName == "FS25_BetterMinimap_NEXT" then
        self.settings.state = self.settings.state + 1
        if (self.settings.state > (self.numberOfFruitPages + 2)) then
            self.settings.state = 0
        end
        if (self.settings.state ~= 0) then
            self.needUpdateFruitOverlay = true
        end
    elseif actionName == "FS25_BetterMinimap_PREV" then
        self.settings.state = self.settings.state - 1
        if (self.settings.state < 0) then
            self.settings.state = (self.numberOfFruitPages + 2)
        end
        if (self.settings.state ~= 0) then
            self.needUpdateFruitOverlay = true
        end
    elseif actionName == "TOGGLE_MAP_SIZE" then
        -- reload field states if change size map
        self.needUpdateFruitOverlay = true
        -- toggle fulscreen
        self.settings.fullscreen = not self.settings.fullscreen

        -- g_currentMission.ingameMap.state = self.settings.fullscreen and IngameMap.STATE_MAP or IngameMap.STATE_MINIMAP
        g_currentMission.hud.ingameMap.state = self.settings.fullscreen and IngameMap.STATE_MAP or
                                                   IngameMap.STATE_MINIMAP

        if (self.settings.fullscreen) then
            -- self.mapWidth, self.mapHeight = ingameMap.maxMapWidth, ingameMap.maxMapHeight
            self.mapWidth, self.mapHeight = getNormalizedScreenValues(unpack(ingameMap.SIZE.SELF))

            self.alpha = self.const.transparent[self.transMode]
            -- self.visWidth = ingameMap.mapVisWidthMax --??
            self.visWidth = ingameMap.mapOverlay.width -- ??
        else
            self.settings.mapUpdate = true
        end
    elseif not self.settings.fullscreen and actionName == "FS25_BetterMinimap_ZOOM_IN" then
        ingameMap:zoom(-self.zoomFactor * dt)
        self.visWidth = ingameMap.mapVisWidthMin
    elseif not self.settings.fullscreen and actionName == "FS25_BetterMinimap_ZOOM_OUT" then
        ingameMap:zoom(self.zoomFactor * dt)
        self.visWidth = ingameMap.mapVisWidthMin
    end
end

-- #############################################################################

function mySelf(obj)
    return " (rootNode: " .. obj.rootNode .. ", typeName: " .. obj.typeName .. ", typeDesc: " .. obj.typeDesc .. ")"
end

-- #############################################################################

function FS25_BetterMinimap:draw()
    if (self.visible) then
        -- local ingameMap = g_currentMission.ingameMap
        local ingameMap = g_currentMission.hud.ingameMap

        -- to do
        -- to do ingameMap:zoom(0)
        -- to do IngameMap.iconZoom = ingameMap.maxIconZoom -- ??

        ingameMap:updatePlayerPosition()
        --to do: remove debug line
            if debug > 1 then
                print("-> " .. myName .. ": setPosition (overlayPosX: " .. self.overlayPosX .. ", overlayPosY: " .. self.overlayPosY .. ")" )
                print("-> " .. myName .. ": setSize (mapwidth: " .. self.mapWidth .. ", mapHeight: " .. self.mapHeight .. ")" )
            end
        ingameMap:setPosition(self.overlayPosX, self.overlayPosY)
        ingameMap:setSize(self.mapWidth, self.mapHeight)

        if (self.settings.fullscreen) then
            ingameMap.mapVisWidthMin = 1
        else
            ingameMap.mapVisWidthMin = self.visWidth
        end

        ingameMap.centerXPos = ingameMap.normalizedPlayerPosX
        ingameMap.centerZPos = ingameMap.normalizedPlayerPosZ

        local leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached = ingameMap:drawMap(
            self.alpha)
        local foliageOverlay = g_inGameMenu.foliageStateOverlay

        if (self.settings.state ~= 0 and getIsFoliageStateOverlayReady(foliageOverlay)) then
            setOverlayUVs(foliageOverlay, unpack(ingameMap.mapUVs))
            renderOverlay(foliageOverlay, self.overlayPosX, self.overlayPosY, self.mapWidth, self.mapHeight)
        end

        self:renderMapMode()

        ingameMap:renderHotspots(leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached, false,
            self.settings.fullscreen)
        -- ingameMap:renderPlayerArrows(false, leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached, true)
        ingameMap:drawPlayerArrows(false, leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached,
            true)
        ingameMap:renderHotspots(leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached, true,
            self.settings.fullscreen)
        -- ingameMap:renderPlayersCoordinates()
        ingameMap:drawPlayersCoordinates()
        ingameMap:drawLatencyToServer()
        -- ingameMap:drawInputBinding()
    end
end

-- #############################################################################

function FS25_BetterMinimap:activate()
    if (not g_inGameMenu.mapSelectorMapping) then
        g_inGameMenu:setupMapOverview()
    end
end

-- #############################################################################

function FS25_BetterMinimap:deactivate()
    -- local ingameMap = g_currentMission.ingameMap
    local ingameMap = g_currentMission.hud.ingameMap
    ingameMap:resetSettings()
end

-- #############################################################################

function FS25_BetterMinimap:show()
    self.visible = true
    -- g_currentMission.ingameMap:setVisible(false)
    g_currentMission.hud.ingameMap:setVisible(false)
    self:activate()
end

-- #############################################################################

function FS25_BetterMinimap:hide()
    self.visible = false
    self:deactivate()
    -- g_currentMission.ingameMap:setVisible(true)
    g_currentMission.hud.ingameMap:setVisible(true)
end

-- #############################################################################

function FS25_BetterMinimap:frequencytime(frequency)
    self.visible = false
    self:deactivate()
    -- g_currentMission.ingameMap:setVisible(true)
    g_currentMission.hud.ingameMap:setVisible(true)
end

-- #############################################################################

function printTable(tbl, indent)
    indent = indent or ""  -- Default to an empty string if no indent is provided

    for k, v in pairs(tbl) do
        if type(v) == "table" then
            -- If the value is a table, print the key and recurse into the table
            print(indent .. k .. " = {")
            printTable(v, indent .. "  ")  -- Increase indent for nested table
            print(indent .. "}")
        else
            -- If the value is not a table, just print the key-value pair
            print(indent .. k .. " = " .. tostring(v))
        end
    end
end

-- #############################################################################

function FS25_BetterMinimap:renderMapMode()
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextBold(false)
    setTextColor(1, 1, 1, 1)
    -- time to refresh
    if (self.settings.state ~= 0) then
        local frequencytime = self.const.frequency[self.frequency]
        -- to do: remove debugline
        if debug > 1 then print("-> " .. myName .. ": renderMapMode: " .. frequencytime ) end

        renderText(self.overlayPosX + 0.003, self.overlayPosY + 0.007, 0.013,
            "[" .. math.ceil((self.const.frequency[self.frequency]) - (self.timer / 1000)) .. "]")
    end
    -- map mode info (more fruits = more pages)
    local modeInfo = g_i18n:getText("FS25_BetterMinimap_MapMode_S" .. self.settings.state)
    if (self.numberOfFruitPages > 1) then
        if (self.settings.state == 0) then
            -- default
        elseif (self.settings.state > 0) and (self.settings.state < self.numberOfFruitPages + 1) then
            modeInfo = g_i18n:getText("FS25_BetterMinimap_MapMode_S1") .. " " .. self.settings.state
        else
            modeInfo = g_i18n:getText("FS25_BetterMinimap_MapMode_S" ..
                                          (self.settings.state - (self.numberOfFruitPages - 1)))
        end
    end
    renderText(self.overlayPosX, self.overlayPosY - 0.02, 0.015,
        g_i18n:getText("FS25_BetterMinimap_MapMode") .. " " .. modeInfo)
    setTextAlignment(RenderText.ALIGN_LEFT) -- reset
end

-- #############################################################################

function FS25_BetterMinimap:renderSelectedMinimap()
    self.mapWidth = self.const.mapSizes[self.sizeMode][1] * self.pixelWidth
    self.mapHeight = self.const.mapSizes[self.sizeMode][2] * self.pixelHeight
    self.alpha = self.transparent and self.const.transparent[self.transMode] or 1
    self.visWidth = 0.3
    -- mapupdate
    self.settings.mapUpdate = false
end

-- #############################################################################

function FS25_BetterMinimap:generateFruitOverlay()
    -- local origState = g_inGameMenu.mapOverviewSelector.state
    -- g_inGameMenu.mapOverviewSelector.state = self.settings.state
    -- g_inGameMenu:generateFruitOverlay()
    -- g_inGameMenu.mapOverviewSelector.state = origState
    local origState = inGameMap.state
    inGameMap.state = self.settings.state
    MapOverlayGenerator:generateFruitTypeOverlay()
    inGameMap.state = origState
    self.timer = 0
end

-- #############################################################################

function strtoboolean(str)
    local bool = false
    if str == "true" then
        bool = true
    end
    return bool
end

-- #############################################################################

function FS25_BetterMinimap:activateConfig()
    -- here we will "move" our config from the libConfig internal storage to the variables we actually use
     
    FS25_BetterMinimap.visible = strtoboolean(lC:getConfigValue("settings", "visible"))
    FS25_BetterMinimap.help_min = strtoboolean(lC:getConfigValue("settings", "help_min"))
    FS25_BetterMinimap.frequency = tonumber(lC:getConfigValue("settings", "frequency"))
    FS25_BetterMinimap.sizeMode = tonumber(lC:getConfigValue("settings", "sizeMode"))
    FS25_BetterMinimap.transparent = strtoboolean(lC:getConfigValue("settings", "transparant"))
    FS25_BetterMinimap.transMode = tonumber(lC:getConfigValue("settings", "transMode"))
end

-- #############################################################################

function FS25_BetterMinimap:resetConfig(disable)
    if debug > 0 then
        print("-> " .. myName .. ": resetConfig ")
    end
    disable = false or disable
    -- start fresh
    lC:clearConfig()
    -- addConfigValue(section, name, typ, value, newLine)
    -- typ: bool int float, newline: bool (empty defaults to false)
    lC:addConfigValue("settings", "visible", "bool", true, true)
    lC:addConfigValue("settings", "help_min", "bool", true, true)
    lC:addConfigValue("settings", "frequency", "int", 4, true)
    lC:addConfigValue("settings", "sizeMode", "int", 1, true)
    lC:addConfigValue("settings", "transparant", "bool", false, true)
    lC:addConfigValue("settings", "transMode", "int", 3, true)
end

-- #############################################################################

function FS25_BetterMinimap:saveConfig(disable)
    if debug > 0 then
        print("-> " .. myName .. ": saveConfig ")
    end
    disable = false or disable
    -- start fresh
    lC:clearConfig()
    -- addConfigValue(section, name, typ, value, newLine)
    -- typ: bool int float, newline: bool (empty defaults to false)
    lC:addConfigValue("settings", "visible", "bool", FS25_BetterMinimap.visible, true)
    lC:addConfigValue("settings", "help_min", "bool", FS25_BetterMinimap.help_min, true)
    lC:addConfigValue("settings", "frequency", "int", FS25_BetterMinimap.frequency, true)
    lC:addConfigValue("settings", "sizeMode", "int", FS25_BetterMinimap.sizeMode, true)
    lC:addConfigValue("settings", "transparant", "bool", FS25_BetterMinimap.transparent, true)
    lC:addConfigValue("settings", "transMode", "int", FS25_BetterMinimap.transMode, true)
end

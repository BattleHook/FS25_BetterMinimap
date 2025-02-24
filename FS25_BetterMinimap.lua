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
    self.mapEvents = {}

    local modDesc = loadXMLFile("modDesc", modDirectory .. "modDesc.xml")
    self.version = getXMLString(modDesc, "modDesc.version")

    --- Constants ---
    self.const = {}
    self.const.settings_file = modsDirectory .. "../modSettings/FS25_BetterMinimap_Settings.xml"
    self.const.frequency = {15, 30, 45, 60} -- refresh frequency (in sec)
    self.const.mapSizes = {{456, 350}, {800, 350}, {800, 600}} -- minimap sizes {width, height}
    self.const.mapNames = {g_i18n:getText("gui_FS25_BetterMinimap_MAPSIZE_N"),
                           g_i18n:getText("gui_FS25_BetterMinimap_MAPSIZE_W"),
                           g_i18n:getText("gui_FS25_BetterMinimap_MAPSIZE_L")}
    self.const.transparent = {0.3, 0.5, 0.7}

    --- Settings ---
    self.settings = {}
    self.settings.init = false
    self.settings.mapUpdate = false
    self.settings.saveSettings = false
    self.settings.visible = true
    self.settings.help_min = true
    self.settings.help_full = false
    self.settings.fullscreen = false
    self.settings.frequency = 4
    self.settings.sizeMode = 1
    self.settings.transparent = false
    self.settings.transMode = 3
    self.settings.state = 0


    -- some global stuff - DONT touch
    FS25_BetterMinimap.actions = {}
    FS25_BetterMinimap.actions.global = {
        "FS25_BetterMinimap_SHOW_CONFIG_GUI", 
        "FS25_BetterMinimap_TOGGLE_HELP", 
        "FS25_BetterMinimap_RELOAD", 
        "FS25_BetterMinimap_NEXT", 
        "FS25_BetterMinimap_PREV", 
        "FS25_BetterMinimap_ZOOM_IN", 
        "FS25_BetterMinimap_ZOOM_OUT" }
    --FS25_BetterMinimap.actions.minimap = {"FS25_BetterMinimap_TOGGLE_HELP", "FS25_BetterMinimap_RELOAD", "FS25_BetterMinimap_NEXT", "FS25_BetterMinimap_PREV", "FS25_BetterMinimap_ZOOM_IN", "FS25_BetterMinimap_ZOOM_OUT"}

    -- for key press delay
    FS25_BetterMinimap.nextActionTime = 0
    FS25_BetterMinimap.deltaActionTime = 500
    FS25_BetterMinimap.minActionTime = 31.25

    -- some colors
    FS25_BetterMinimap.color = {
        black = {0, 0, 0, 1},
        white = {1, 1, 1, 1},
        red = {255 / 255, 0 / 255, 0 / 255, 1},
        darkred = {128 / 255, 0 / 255, 0 / 255, 1},
        green = {0 / 255, 255 / 255, 0 / 255, 1},
        blue = {0 / 255, 0 / 255, 255 / 255, 1},
        yellow = {255 / 255, 255 / 255, 0 / 255, 1},
        gray = {128 / 255, 128 / 255, 128 / 255, 1},
        lgray = {178 / 255, 178 / 255, 178 / 255, 1},
        dmg = {255 / 255, 174 / 255, 0 / 255, 1},
        fuel = {178 / 255, 214 / 255, 22 / 255, 1},
        adblue = {48 / 255, 78 / 255, 249 / 255, 1},
        electric = {255 / 255, 255 / 255, 0 / 255, 1},
        methane = {0 / 255, 198 / 255, 255 / 255, 1},
        ls22blue = {0 / 255, 198 / 255, 253 / 255, 1},
        fs25green = {60 / 255, 118 / 255, 0 / 255, 1}
    }
    -- load sound effects
    if g_dedicatedServerInfo == nil then
        local file, id
        FS25_BetterMinimap.sounds = {}
        for _, id in ipairs({"mouseclick", "refresh", "zoom"}) do
            FS25_BetterMinimap.sounds[id] = createSample(id)
            file = self.modDirectory .. "resources/" .. id .. ".ogg"
            loadSample(FS25_BetterMinimap.sounds[id], file, false)
        end
    end

    return self
end

--- Better Minimap Methods ---

-- #############################################################################
function FS25_BetterMinimap:init()
    self.overlayPosX = 0.02
    self.overlayPosY = 0.04
    self.zoomFactor = 0.0007
    self.visWidth = 0.3

    self.pixelWidth = (1 / 3) / 1024.0
    self.pixelHeight = self.pixelWidth * g_screenAspectRatio

    -- set default map properties
    self.mapWidth = self.const.mapSizes[self.settings.sizeMode][1] * self.pixelWidth
    self.mapHeight = self.const.mapSizes[self.settings.sizeMode][2] * self.pixelHeight
end

-- #############################################################################
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
    g_gui:loadGui(self.modDirectory .. "ui/FS25_BetterMinimap_UI.xml", "FS25_BetterMinimap_UI", FS25_BetterMinimap.ui_menu)
end

-- #############################################################################
function FS25_BetterMinimap:loadMap()
    print("--> loaded FS25_BetterMinimap version " .. self.version .. " (by SupremeClicker) <--")
    -- first set our current and default config to default values
    FS25_BetterMinimap:resetConfig()
    FS25_BetterMinimap:loadSettings()
    -- then read values from disk and "overwrite" current config
    lC:readConfig()
    -- then write current config (which is now a merge between default values and from disk)
    lC:writeConfig()
    -- and finally activate current config
    FS25_BetterMinimap:activateConfig()
end

-- #############################################################################
function FS25_BetterMinimap:unloadMap()
    print("--> unloaded FS25_BetterMinimap version " .. self.version .. " (by SupremeClicker) <--")
end

-- #############################################################################
--[[
function FS25_BetterMinimap.installSpecializations(vehicleTypeManager, specializationManager, modDirectory, modName)
    if debug > 1 then
        print("-> " .. myName .. ": installSpecializations ")
    end

    specializationManager:addSpecialization("BetterMinimap", "FS25_BetterMinimap",
        Utils.getFilename("FS25_BetterMinimap.lua", modDirectory), nil)

    if specializationManager:getSpecializationByName("BetterMinimap") == nil then
        print("ERROR: unable to add specialization 'FS25_BetterMinimap'")
    else
        for typeName, typeDef in pairs(vehicleTypeManager.types) do
            if SpecializationUtil.hasSpecialization(Drivable, typeDef.specializations) and
                SpecializationUtil.hasSpecialization(Enterable, typeDef.specializations) and
                SpecializationUtil.hasSpecialization(Motorized, typeDef.specializations) and
                not SpecializationUtil.hasSpecialization(Locomotive, typeDef.specializations) and
                not SpecializationUtil.hasSpecialization(ConveyorBelt, typeDef.specializations) and
                not SpecializationUtil.hasSpecialization(AIConveyorBelt, typeDef.specializations) then
                if debug > 1 then
                    print("--> attached specialization 'BetterMinimap' to vehicleType '" .. tostring(typeName) .. "'")
                end
                vehicleTypeManager:addSpecialization(typeName, modName .. ".BetterMinimap")
            end
        end
    end
end
--]]

-- #############################################################################
function FS25_BetterMinimap.prerequisitesPresent(specializations)
    if debug > 1 then
        print("-> " .. myName .. ": prerequisites ")
    end

    return true
end

-- #############################################################################
function FS25_BetterMinimap.registerEventListeners(vehicleType)
    if debug > 1 then
        print("-> " .. myName .. ": registerEventListeners ")
    end

    for _, n in pairs({"onLoad", "onPostLoad", "saveToXMLFile", "onUpdate", "onReadStream", "onWriteStream",
                       "onReadUpdateStream", "onWriteUpdateStream", "onRegisterActionEvents", "onEnterVehicle",
                       "onLeaveVehicle", "onPostAttachImplement", "onPostDetachImplement"}) do
        SpecializationUtil.registerEventListener(vehicleType, n, FS25_BetterMinimap)
    end
end

-- #############################################################################
function FS25_BetterMinimap:activateConfig()
    -- here we will "move" our config from the libConfig internal storage to the variables we actually use

    -- functions

    -- globals
    FS25_BetterMinimap.showKeysInHelpMenu = lC:getConfigValue("global.misc", "showKeysInHelpMenu")
    FS25_BetterMinimap.soundIsOn = lC:getConfigValue("global.misc", "soundIsOn")
end

-- #############################################################################
function FS25_BetterMinimap:resetConfig(disable)
    if debug > 0 then
        print("-> " .. myName .. ": resetConfig ")
    end
    disable = false or disable

    -- start fresh
    lC:clearConfig()

    -- functions

    -- globals
    lC:addConfigValue("global.misc", "showKeysInHelpMenu", "bool", true)
    lC:addConfigValue("global.misc", "soundIsOn", "bool", true)

    -- sound volumes
    lC:addConfigValue("sfx.track", "volume", "float", 0.10)
    lC:addConfigValue("sfx.brake", "volume", "float", 0.10)
    lC:addConfigValue("sfx.diff", "volume", "float", 0.50)
    lC:addConfigValue("sfx.hl_approach", "volume", "float", 0.10)
end

-- #############################################################################
function FS25_BetterMinimap:onLoad(savegame)
    if debug > 1 then
        print("-> " .. myName .. ": onLoad" .. mySelf(self))
    end
end

-- aanpassen ?? #############################################################################

function FS25_BetterMinimap:onUpdate(dt)
    if debug > 2 then
        print("-> " .. myName .. ": onUpdate " .. dt .. ", S: " .. tostring(self.isServer) .. ", C: " ..
                  tostring(self.isClient) .. mySelf(self))
    end

    -- activate mod if not activated
    if (not self.settings.init) then
        self.settings.init = true
        --g_currentMission.ingameMap.state = IngameMap.STATE_MINIMAP
        g_currentMission.hud.ingameMap.state = IngameMap.STATE_MINIMAP
        self:show()
    end

    --[[ TARDIS mod compatibility
    if g_modIsLoaded["FS25_TARDIS"] then
        if (g_currentMission.tardisBase.tardisOn ~= nil and self.settings.fullscreen) then
            self:hide();
        else
            g_currentMission.ingameMap.state = IngameMap.STATE_MINIMAP;
            self:show();
        end;
    end; ]]
    --local ingameMap = g_currentMission.ingameMap
    local ingameMap = g_currentMission.hud.ingameMap

    if (g_gui:getIsGuiVisible() and g_gui.currentGuiName == "InGameMenu") then
        self.needUpdateFruitOverlay = true
    end

    if (self.timer < (self.const.frequency[self.settings.frequency] * 1000)) then
        self.timer = self.timer + dt
    else
        self.needUpdateFruitOverlay = true
    end
        if (self.settings.init and g_gui.currentGui == nil) then
            if (self.settings.help_min) then
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
            if (self.settings.saveSettings and fileExists(self.const.settings_file)) then
                self:saveSettings(self.const.settings_file);
            end ;
        end
end

-- #############################################################################
function FS25_BetterMinimap:onRegisterActionEvents(isSelected, isOnActiveVehicle)
    if debug > 1 then
        print("-> " .. myName .. ": onRegisterActionEvents " .. tostring(isSelected) .. ", " ..
                  tostring(isOnActiveVehicle) .. ", S: " .. tostring(self.isServer) .. ", C: " ..
                  tostring(self.isClient) .. mySelf(self))
    end

    -- continue on client side only
    if not self.isClient then -- or not self:getIsActiveForInput(true, true)
        return
    end

    -- only in active vehicle and when we control it
    if isOnActiveVehicle and self:getIsControlled() then
        -- assemble list of actions to attach
        local actionList = FS25_BetterMinimap.actions.global
        --for _, v in ipairs(FS25_BetterMinimap.actions.minimap) do
        --    table.insert(actionList, v)
        --end

        -- attach our actions
        for _, actionName in pairs(actionList) do
            if actionName == "FS25_BetterMinimap_SHOW_CONFIG_GUI" or
               actionName == "FS25_BetterMinimap_TOGGLE_HELP" or
               actionName == "FS25_BetterMinimap_RELOAD" or 
               actionName == "FS25_BetterMinimap_NEXT" or 
               actionName == "FS25_BetterMinimap_PREV" or 
               actionName == "FS25_BetterMinimap_ZOOM_IN" or 
               actionName == "FS25_BetterMinimap_ZOOM_OUT" then
                _, eventName = g_inputBinding:registerActionEvent(actionName, self, FS25_BetterMinimap.onActionCall, false, true, true, true)
                FS25_BetterMinimap:helpMenuPrio(actionName, eventName)
                _, eventName = g_inputBinding:registerActionEvent(actionName, self, FS25_BetterMinimap.onActionCallUp, true, false, false, true)
                FS25_BetterMinimap:helpMenuPrio(actionName, eventName)
            else
                _, eventName = g_inputBinding:registerActionEvent(actionName, self, FS25_BetterMinimap.onActionCall, false, true, false, true)
                FS25_BetterMinimap:helpMenuPrio(actionName, eventName)
            end
        end
    end
end

-- #############################################################################
function FS25_BetterMinimap:helpMenuPrio(actionName, eventName)
    -- help menu priorization
    if g_inputBinding ~= nil and g_inputBinding.events ~= nil and g_inputBinding.events[eventName] ~= nil then
        if actionName == "FS25_BetterMinimap_SHOW_CONFIG_GUI" or 
        actionName == "FS25_BetterMinimap_TOGGLE_HELP" or
        actionName == "FS25_BetterMinimap_RELOAD" or 
        actionName == "FS25_BetterMinimap_NEXT" or 
        actionName == "FS25_BetterMinimap_PREV" or 
        actionName == "FS25_BetterMinimap_ZOOM_IN" or 
        actionName == "FS25_BetterMinimap_ZOOM_OUT" then
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

            --g_currentMission.ingameMap.state = self.settings.fullscreen and IngameMap.STATE_MAP or IngameMap.STATE_MINIMAP
            g_currentMission.hud.ingameMap.state = self.settings.fullscreen and IngameMap.STATE_MAP or IngameMap.STATE_MINIMAP

            if (self.settings.fullscreen) then
                --self.mapWidth, self.mapHeight = ingameMap.maxMapWidth, ingameMap.maxMapHeight
                self.mapWidth, self.mapHeight = getNormalizedScreenValues(unpack(ingameMap.SIZE.SELF))
                
                self.alpha = self.const.transparent[self.settings.transMode]
                --self.visWidth = ingameMap.mapVisWidthMax --??
                self.visWidth = ingameMap.mapOverlay.width --??
            else
                self.settings.mapUpdate = true
            end
        elseif not self.settings.fullscreen and actionName == "FS25_BetterMinimap_ZOOM_IN" then
            IngameMap:zoom(-self.zoomFactor * dt)
            self.visWidth = ingameMap.mapVisWidthMin
        elseif not self.settings.fullscreen and actionName == "FS25_BetterMinimap_ZOOM_OUT" then
            IngameMap:zoom(self.zoomFactor * dt)
            self.visWidth = ingameMap.mapVisWidthMin
        end
end

-- #############################################################################
function mySelf(obj)
    return " (rootNode: " .. obj.rootNode .. ", typeName: " .. obj.typeName .. ", typeDesc: " .. obj.typeDesc .. ")"
end


-- #############################################################################
function FS25_BetterMinimap:draw()
    if (self.settings.visible) then

        --local ingameMap = g_currentMission.ingameMap
        local ingameMap = g_currentMission.hud.ingameMap

        --to do
        IngameMap:zoom(0)
        IngameMap.iconZoom = ingameMap.maxIconZoom --??

        IngameMap:updatePlayerPosition()
        IngameMap:setPosition(self.overlayPosX, self.overlayPosY)
        IngameMap:setSize(self.mapWidth, self.mapHeight)

        if (self.settings.fullscreen) then
            ingameMap.mapVisWidthMin = 1
        else
            ingameMap.mapVisWidthMin = self.visWidth
        end

        ingameMap.centerXPos = ingameMap.normalizedPlayerPosX
        ingameMap.centerZPos = ingameMap.normalizedPlayerPosZ

        local leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached = IngameMap:drawMap(self.alpha)
        local foliageOverlay = g_inGameMenu.foliageStateOverlay

        if (self.settings.state ~= 0 and getIsFoliageStateOverlayReady(foliageOverlay)) then
            setOverlayUVs(foliageOverlay, unpack(ingameMap.mapUVs))
            renderOverlay(foliageOverlay, self.overlayPosX, self.overlayPosY, self.mapWidth, self.mapHeight)
        end

        self:renderMapMode()

        IngameMap:renderHotspots(leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached, false, self.settings.fullscreen)
        --ingameMap:renderPlayerArrows(false, leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached, true)
        IngameMap:drawPlayerArrows(false, leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached, true)
        IngameMap:renderHotspots(leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached, true, self.settings.fullscreen)
        --ingameMap:renderPlayersCoordinates()
        IngameMap:drawPlayersCoordinates()
        IngameMap:drawLatencyToServer()
        --ingameMap:drawInputBinding()
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
    --local ingameMap = g_currentMission.ingameMap
    local ingameMap = g_currentMission.hud.ingameMap
    IngameMap:resetSettings()
end

-- #############################################################################
function FS25_BetterMinimap:show()
    self.settings.visible = true
    --g_currentMission.ingameMap:setVisible(false)
    IngameMap:setIsVisible(false)
    self:activate()
end

-- #############################################################################
function FS25_BetterMinimap:hide()
    self.settings.visible = false
    self:deactivate()
    --g_currentMission.ingameMap:setVisible(true)
    IngameMap:setIsVisible(true)
end

-- #############################################################################
function FS25_BetterMinimap:renderMapMode()
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextBold(false)
    setTextColor(1, 1, 1, 1)
    -- time to refresh
    if (self.settings.state ~= 0) then
        renderText(self.overlayPosX + 0.003, self.overlayPosY + 0.007, 0.013, "[" .. math.ceil((self.const.frequency[self.settings.frequency]) - (self.timer / 1000)) .. "]")
    end
    -- map mode info (more fruits = more pages)
    local modeInfo = g_i18n:getText("BM_MapMode_S" .. self.settings.state)
    if (self.numberOfFruitPages > 1) then
        if (self.settings.state == 0) then
            -- default
        elseif (self.settings.state > 0) and (self.settings.state < self.numberOfFruitPages + 1) then
            modeInfo = g_i18n:getText("BM_MapMode_S1") .. " " .. self.settings.state
        else
            modeInfo = g_i18n:getText("BM_MapMode_S" .. (self.settings.state - (self.numberOfFruitPages - 1)))
        end
    end
    renderText(self.overlayPosX, self.overlayPosY - 0.02, 0.015, g_i18n:getText("BM_MapMode") .. " " .. modeInfo)
    setTextAlignment(RenderText.ALIGN_LEFT) -- reset
end;

-- #############################################################################
function FS25_BetterMinimap:renderSelectedMinimap()
    self.mapWidth = self.const.mapSizes[self.settings.sizeMode][1] * self.pixelWidth
    self.mapHeight = self.const.mapSizes[self.settings.sizeMode][2] * self.pixelHeight
    self.alpha = self.settings.transparent and self.const.transparent[self.settings.transMode] or 1
    self.visWidth = 0.3
    -- mapupdate
    self.settings.mapUpdate = false
end

-- #############################################################################
-- needs work
function FS25_BetterMinimap:generateFruitOverlay()
    --local origState = g_inGameMenu.mapOverviewSelector.state
    --g_inGameMenu.mapOverviewSelector.state = self.settings.state
    --g_inGameMenu:generateFruitOverlay()
    --g_inGameMenu.mapOverviewSelector.state = origState
    local origState = inGameMap.state
    inGameMap.state = self.settings.state
    MapOverlayGenerator:generateFruitTypeOverlay()
    inGameMap.state = origState
    self.timer = 0
end
-- #############################################################################
function FS25_BetterMinimap:saveSettings(fileName)
    local xml = createXMLFile("BetterMinimap", fileName, "BetterMinimap")
    setXMLBool(xml, "BetterMinimap.visible", self.settings.visible)
    setXMLBool(xml, "BetterMinimap.help", self.settings.help_min)
    setXMLInt(xml, "BetterMinimap.frequency", self.settings.frequency)
    setXMLInt(xml, "BetterMinimap.sizeMode", self.settings.sizeMode)
    setXMLBool(xml, "BetterMinimap.transparency", self.settings.transparent)
    setXMLInt(xml, "BetterMinimap.transMode", self.settings.transMode)
    saveXMLFile(xml)
    delete(xml)
end

-- #############################################################################
function FS25_BetterMinimap:loadSettings(fileName)
    local xml = loadXMLFile("BetterMinimap", fileName)
    self.settings.visible = Utils.getNoNil(getXMLBool(xml, "BetterMinimap.visible"), self.settings.visible)
    self.settings.help_min = Utils.getNoNil(getXMLBool(xml, "BetterMinimap.help"), self.settings.help_min)
    self.settings.frequency = Utils.getNoNil(getXMLInt(xml, "BetterMinimap.frequency"), self.settings.frequency)
    self.settings.sizeMode = Utils.getNoNil(getXMLInt(xml, "BetterMinimap.sizeMode"), self.settings.sizeMode)
    self.settings.transparent = Utils.getNoNil(getXMLBool(xml, "BetterMinimap.transparency"), self.settings.transparent)
    self.settings.transMode = Utils.getNoNil(getXMLInt(xml, "BetterMinimap.transMode"), self.settings.transMode)
    delete(xml)
end

FS25_BetterMinimap:init()
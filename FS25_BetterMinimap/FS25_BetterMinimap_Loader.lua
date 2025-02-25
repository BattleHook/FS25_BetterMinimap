--
-- Mod: FS25_BetterMinimap
--
-- Author: original  FS17:jDanek; FS25: SupremeClicker
-- email: gvdhaak (at) gmail (dot) com
-- @Date: 22.02.2025
-- @Version: 1.0.0.0
-- #############################################################################
debug = 2 -- 0=0ff, 1=some, 2=everything, 3=madness

local modDirectory = g_currentModDirectory
local modName = g_currentModName

source(Utils.getFilename("FS25_BetterMinimap.lua", modDirectory))
source(Utils.getFilename("ui/FS25_BetterMinimap_UI.lua", modDirectory))

-- include our libUtils
source(Utils.getFilename("libUtils.lua", g_currentModDirectory))
lU = libUtils()
lU:setDebug(0)

-- include our new libConfig XML management
source(Utils.getFilename("libConfig.lua", g_currentModDirectory))
lC = libConfig("FS25_BetterMinimap", 1, 0)
lC:setDebug(0)

local FS25_BetterMinimap

local function isEnabled()
    return FS25_BetterMinimap ~= nil
end

-- #############################################################################

function FS25_BetterMinimap_load(mission)
    if debug > 1 then
        print("FS25_BetterMinimap_load()")
    end

    -- create our BM class
    assert(g_FS25_BetterMinimap == nil)
    FS25_BetterMinimap = FS25_BetterMinimap:new(mission, modDirectory, modName, g_i18n, g_gui, g_gui.inputManager,
        g_messageCenter)
    getfenv(0)["g_FS25_BetterMinimap"] = FS25_BetterMinimap

    mission.FS25_BetterMinimap = FS25_BetterMinimap

    addModEventListener(FS25_BetterMinimap)
end

-- #############################################################################

function FS25_BetterMinimap_unload()
    if debug > 1 then
        print("FS25_BetterMinimap_unload()")
    end

    if not isEnabled() then
        return
    end

    removeModEventListener(FS25_BetterMinimap)

    FS25_BetterMinimap:delete()
    FS25_BetterMinimap = nil
    getfenv(0)["g_FS25_BetterMinimap"] = nil
end

-- #############################################################################

function FS25_BetterMinimap_loadedMission(mission)
    if debug > 1 then
        print("FS25_BetterMinimap_load()")
    end

    if not isEnabled() then
        return
    end

    if mission.cancelLoading then
        return
    end

    FS25_BetterMinimap:onMissionLoaded(mission)
end

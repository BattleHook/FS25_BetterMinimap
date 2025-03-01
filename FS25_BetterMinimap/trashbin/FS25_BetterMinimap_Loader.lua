--
-- Mod: FS25_BetterMinimap
--
-- Author: original  FS17:jDanek; FS25: SupremeClicker
-- email: gvdhaak (at) gmail (dot) com
-- @Date: 22.02.2025
-- @Version: 1.0.0.0
-- #############################################################################
debug = 2 -- 0=0ff, 1=some, 2=everything, 3=madness

local directory = g_currentModDirectory
local modName = g_currentModName

source(Utils.getFilename("scripts/ModLib/ModHelper.lua", directory))
source(Utils.getFilename("scripts/ModLib/DebugHelper.lua", directory))
source(Utils.getFilename("scripts/ModLib/DevHelper.lua", directory))
source(Utils.getFilename("scripts/ModLib/DialogHelper.lua", directory))
source(Utils.getFilename("scripts/ModLib/LogHelper.lua", directory))
--source(Utils.getFilename("scripts/FS25_BetterMinimap.lua", directory))
--source(Utils.getFilename("ui/FS25_BetterMinimap_UI.lua", directory))


-- #############################################################################

function BM_init()
  if debug > 1 then print("BM_init()") end
  
  -- hook into early load
  Mission00.load = Utils.prependedFunction(Mission00.load, BM_load)
  -- hook into late load
  Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, BM_loadedMission)

  -- hook into late unload
  FSBaseMission.delete = Utils.appendedFunction(FSBaseMission.delete, BM_unload)

  -- hook into validateTypes
  --TypeManager.validateTypes = Utils.prependedFunction(TypeManager.validateTypes, BM_validateTypes)
end

-- #############################################################################

function BM_load(mission)
    if debug > 1 then
        print("BM_load()")
    end

    -- create our BM class
    assert(g_FS25_BetterMinimap == nil)
    BetterMinimap = FS25_BetterMinimap:new(mission, directory, modName, g_i18n, g_gui, g_gui.inputManager, g_messageCenter)
    getfenv(0)["g_FS25_BetterMinimap"] = BetterMinimap

    mission.BetterMinimap = BetterMinimap

    addModEventListener(BetterMinimap)
end

-- #############################################################################

function BM_unload()
    if debug > 1 then
        print("BM_unload()")
    end

    if not isEnabled() then
        return
    end

    removeModEventListener(BetterMinimap)

    BetterMinimap:delete()
    BetterMinimap = nil
    getfenv(0)["g_BetterMinimap"] = nil
end

-- #############################################################################

function BM_loadedMission(mission)
    if debug > 1 then
        print("BM_load()")
    end

    if not isEnabled() then
        return
    end

    if mission.cancelLoading then
        return
    end

    BetterMinimap:onMissionLoaded(mission)
end

-- #############################################################################
--[[
function BM_validateTypes(types)
  if debug > 1 then print("BM_validateTypes()") end
    
  -- attach only to vehicles
  if (types.typeName == 'vehicle') then
    FS25_BetterMinimap.installSpecializations(g_vehicleTypeManager, g_specializationManager, directory, modName)
  end
end
--]]
-- #############################################################################

BM_init()
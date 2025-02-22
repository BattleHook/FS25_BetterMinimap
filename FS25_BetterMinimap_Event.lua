--
-- Mod: FS25_BetterMinimap
--
-- Author: original  FS17:jDanek; FS25: SupremeClicker
-- email: gvdhaak (at) gmail (dot) com
-- @Date: 22.02.2025
-- @Version: 1.0.0.0

local myName = "FS25_BetterMinimap_Event"

-- #############################################################################

FS25_BetterMinimap_Event = {}
local FS25_BetterMinimap_Event_mt = Class(FS25_BetterMinimap_Event, Event)

InitEventClass(FS25_BetterMinimap_Event, "FS25_BetterMinimap_Event")

-- #############################################################################

function FS25_BetterMinimap_Event.emptyNew()
  if debug > 2 then print("-> " .. myName .. ": emptyNew()") end

  local self = Event.new(FS25_BetterMinimap_Event_mt)

  return self
end

-- #############################################################################

function FS25_BetterMinimap_Event.new(vehicle, b1, b2, i1, f1, b3, b4, f2, f3, f4, f5, f6, f7, b5, f8, f9, i2 )
  local args = { b1, b2, i1, f1, b3, b4, f2, f3, f4, f5, f6, f7, b5, f8, f9, i2 }
  if debug > 2 then print("-> " .. myName .. ": new(): " .. lU:args_to_txt(unpack(args))) end

  local self = FS25_BetterMinimap_Event.emptyNew()
  self.vehicle = vehicle
  self.vehicle.vData.want = { unpack(args) }

  return self
end

-- #############################################################################

function FS25_BetterMinimap_Event:run(connection)
  if debug > 1 then print("-> " .. myName .. ": run()") end

  if g_server == nil then
    self.vehicle.vData.is = { unpack(self.vehicle.vData.want) }
  end

  if debug > 1 then print("--> " .. self.vehicle.rootNode .. " - (" .. lU:args_to_txt(unpack(self.vehicle.vData.is)).."|"..lU:args_to_txt(unpack(self.vehicle.vData.want))..")") end

  if not connection:getIsServer() then
    g_server:broadcastEvent(FS25_BetterMinimap_Event.new(self.vehicle, unpack(self.vehicle.vData.want)), nil, connection)
  end
end


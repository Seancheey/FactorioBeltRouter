---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by seancheey.
--- DateTime: 9/30/20 1:11 AM
---

--- @alias player_index number

--- @type ArrayList
local ArrayList = require("__MiscLib__/array_list")
local TransportLineConnector = require("transport_line_connector")

--- @type table<player_index, ArrayList|LuaEntity[]>
local playerSelectedStartingPositions = {}

local function pushNewStartingPosition(player_index, entity)
    if playerSelectedStartingPositions[player_index] == nil then
        playerSelectedStartingPositions[player_index] = ArrayList.new()
    end
    playerSelectedStartingPositions[player_index]:add(entity)
end

local function popNewStartingPosition(player_index)
    if playerSelectedStartingPositions[player_index] then
        return playerSelectedStartingPositions[player_index]:popLeft()
    end
end

local function setStartingTransportLine(event)
    local player = game.players[event.player_index]
    local selectedEntity = player.selected
    if not selectedEntity then
        return
    end
    if selectedEntity.prototype.belt_speed or selectedEntity.prototype.name == "pipe" then
        pushNewStartingPosition(event.player_index, selectedEntity)
        player.print("queued one " .. selectedEntity.name .. " into connection waiting list. There are " .. #playerSelectedStartingPositions[event.player_index] .. " belts in connection waiting list")
    end
end

local function setEndingTransportLine(event)
    local player = game.players[event.player_index]
    local selectedEntity = player.selected
    if not selectedEntity then
        return
    end
    if not selectedEntity.prototype.belt_speed and selectedEntity.prototype.name ~= "pipe" then
        return
    end
    local startingEntity = popNewStartingPosition(event.player_index)
    if not startingEntity then
        player.print("You haven't specified any starting belt yet. Place a belt as starting transport line, and then shift + right click on it to mark it as starting belt.")
        return
    end
    local surface = player.surface
    local function canPlace(position)
        return surface.can_place_entity { name = "transport-belt", position = position }
    end
    local function place(entity)
        entity.force = player.force
        surface.create_entity(entity)
    end
    local transportLineConstructor = TransportLineConnector.new(canPlace, place)
    transportLineConstructor:buildTransportLine(startingEntity, selectedEntity, { allowUnderground = true })
end

script.on_event("shiftRightClickCustomInput", setStartingTransportLine)
script.on_event("shiftLeftClickCustomInput", setEndingTransportLine)

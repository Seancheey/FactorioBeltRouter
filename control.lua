---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by seancheey.
--- DateTime: 9/30/20 1:11 AM
---


--- @alias player_index number

--- @type ArrayList
local ArrayList = require("__MiscLib__/array_list")
--- @type Copier
local Copy = require("__MiscLib__/copy")
--- @type Logger
local logging = require("__MiscLib__/logging")
--- @type TransportLineConnector
local TransportLineConnector = require("transport_line_connector")
local releaseMode = require("release")

--- @type table<string, boolean>
local loggingCategories = {
    reward = false
}

for category, enable in pairs(loggingCategories) do
    logging.addCategory(category, releaseMode and false or enable)
end
if releaseMode then
    logging.disableCategory(logging.D)
    logging.disableCategory(logging.I)
    logging.disableCategory(logging.V)
end

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

local function setEndingTransportLine(event, config)
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
    logging.log("build line with config: " .. serpent.line(config))
    local surface = player.surface
    local function canPlace(position)
        return surface.can_place_entity { name = "transport-belt", position = position }
    end
    local function place(entity)
        entity = Copy.deep_copy(entity)
        entity.force = player.force
        if entity.name ~= "entity-ghost" and entity.name ~= "speech-bubble" then
            entity.inner_name = entity.name
            entity.name = "entity-ghost"
        end
        entity.player = player
        surface.create_entity(entity)
    end
    local function getEntity(position)
        return surface.find_entities({ { position.x, position.y }, { position.x, position.y } })[1]
    end
    local transportLineConstructor = TransportLineConnector.new(canPlace, place, getEntity)
    local errorMessage = transportLineConstructor:buildTransportLine(startingEntity, selectedEntity, config)
    if errorMessage then
        player.print(errorMessage)
    end
end

local function buildTransportLineWithConfig(config)
    return function(event)
        setEndingTransportLine(event, config)
    end
end

script.on_event("select-line-starting-point", setStartingTransportLine)
script.on_event("build-transport-line", buildTransportLineWithConfig { allowUnderground = true })
script.on_event("build-transport-line-no-underground", buildTransportLineWithConfig { allowUnderground = false })

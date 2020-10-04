---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by seancheey.
--- DateTime: 9/27/20 5:19 PM
--- Terminology:
---     targetBelt/sourceBelt: If belt A is point towards belt B, then belt B is the targetBelt of A. reversely, belt A is belt B's sourceBelt
---     |->| |->| |->| for this situation, in terms of the belt in the middle, the 1st belt is its sourceBelt, and 3rd is its targetBelt

local assertNotNull = require("__MiscLib__/assert_not_null")
--- @type Logger
local logging = require("__MiscLib__/logging")
--- @type ArrayList
local ArrayList = require("__MiscLib__/array_list")
--- @type MinHeap
local MinHeap = require("__MiscLib__/minheap")
--- @type Vector2D
local Vector2D = require("__MiscLib__/vector2d")
--- @type PrototypeInfo
local PrototypeInfo = require("prototype_info")
local release_mode = require("release")
--- @type TransportLineType
local TransportLineType = require("transport_line_type")

local DirectionHelper = {}

--- @param entity LuaEntity
--- @return Vector2D
function DirectionHelper.sourcePositionOf(entity)
    return DirectionHelper.sourcePosition(entity.position, entity.direction)
end

--- @param position Vector2D
--- @param direction defines.direction
--- @return Vector2D
function DirectionHelper.sourcePosition(position, direction)
    return Vector2D.fromPosition(position) + Vector2D.fromDirection(direction or defines.direction.north):reverse()
end

--- @param entity LuaEntity
--- @return Vector2D
function DirectionHelper.targetPositionOf(entity)
    return DirectionHelper.targetPosition(entity.position, entity.direction)
end

--- @param position Vector2D
--- @param direction defines.direction
--- @return Vector2D
function DirectionHelper.targetPosition(position, direction)
    return Vector2D.fromPosition(position) + Vector2D.fromDirection(direction or defines.direction.north)
end

--- @param entity LuaEntity
--- @return LuaEntity[]|ArrayList entity with only direction and position
function DirectionHelper.legalSourcesOf(entity)
    local legalSources = ArrayList.new()
    -- TODO handle pipe situation
    if PrototypeInfo.is_underground_transport(entity.name) then
        -- underground belt's input only allows one direction
        legalSources:add { position = DirectionHelper.sourcePositionOf(entity), direction = entity.direction }
    else
        -- normal belts allows 3 directions
        local banDirection = Vector2D.fromDirection(entity.direction):reverse():toDirection()
        for _, direction in ipairs { defines.direction.north, defines.direction.east, defines.direction.south, defines.direction.west } do
            if direction ~= banDirection then
                legalSources:add { position = DirectionHelper.sourcePosition(entity.position, direction), direction = direction }
            end
        end
    end
    return legalSources
end

--- @class TransportChain
--- @field entity LuaEntity
--- @field entityDistance number
--- @field prevChain TransportChain
--- @field cumulativeDistance number
--- @type TransportChain
local TransportChain = {}

--- @param entity LuaEntityPrototype
--- @param prevChain TransportChain
--- @param travelDistance number
--- @return TransportChain
function TransportChain.new(entity, prevChain, travelDistance)
    travelDistance = travelDistance or 1
    return setmetatable({
        entity = entity,
        prevChain = prevChain,
        cumulativeDistance = prevChain and (prevChain.cumulativeDistance + travelDistance) or 0,
        entityDistance = travelDistance
    }, { __index = TransportChain })
end

--- @return LuaEntity[]|ArrayList
function TransportChain:toEntityList()
    local list = ArrayList.new()
    local currentChain = self
    while currentChain ~= nil do
        list:add(currentChain.entity)
        currentChain = currentChain.prevChain
    end
    return list
end

--- @param placeFunc fun(entity: LuaEntityPrototype)
function TransportChain:placeAllEntities(placeFunc)
    local transportChain = self
    while transportChain ~= nil do
        if game.entity_prototypes[transportChain.entity.name].max_underground_distance then
            transportChain.entity.type = "input"
            placeFunc(transportChain.entity)
            -- if the entity is underground line, also place its complement
            placeFunc {
                name = transportChain.entity.name,
                position = Vector2D.fromDirection(transportChain.entity.direction or defines.direction.north):scale(transportChain.entityDistance - 1) + Vector2D.fromPosition(transportChain.entity.position),
                direction = transportChain.entity.direction,
                type = "output"
            }
        else
            placeFunc(transportChain.entity)
        end
        transportChain = transportChain.prevChain
    end
end

--- Represents the dictionary of minimum travel distance from endingEntity to some belt (represented by a position vector + direction)
--- @class MinDistanceDict
--- @type MinDistanceDict
local MinDistanceDict = {}
MinDistanceDict.__directionNum = 8

--- @return MinDistanceDict
function MinDistanceDict.new()
    return setmetatable({}, { __index = MinDistanceDict })
end

--- @param vector Vector2D
function MinDistanceDict:put(vector, direction, val)
    assertNotNull(self, vector, val)
    if self[vector.x] == nil then
        self[vector.x] = {}
    end
    self[vector.x][vector.y * MinDistanceDict.__directionNum + direction] = val
end

--- @param entity LuaEntity
function MinDistanceDict:putUsingTargetEntity(entity, val)
    if PrototypeInfo.is_underground_transport(entity.name) then

    end
    self:put(entity.position, entity.direction, val)
end

--- @return number
function MinDistanceDict:get(vector, direction)
    if self[vector.x] == nil then
        return nil
    end
    return self[vector.x][vector.y * MinDistanceDict.__directionNum + direction]
end

--- @param f fun(key1:vector, key2: defines.direction, val:number)
function MinDistanceDict:forEach(f)
    for x, ys in pairs(self) do
        for k2, val in pairs(ys) do
            local y = math.floor(k2 / MinDistanceDict.__directionNum)
            local direction = k2 % MinDistanceDict.__directionNum
            f(Vector2D.new(x, y), direction, val)
        end
    end
end

--- An "Abstract" transport line connector
--- @class TransportLineConnector
--- @field canPlaceEntityFunc fun(position: Vector2D): boolean
--- @field placeEntityFunc fun(entity: LuaEntityPrototype)
--- @field getEntityFunc fun(position: Vector2D): LuaEntity
--- @type TransportLineConnector
local TransportLineConnector = {}

TransportLineConnector.__index = TransportLineConnector

--- @param canPlaceEntityFunc fun(position: Vector2D): boolean
--- @param placeEntityFunc fun(entity: LuaEntityPrototype)
--- @param getEntityFunc fun(position: Vector2D): LuaEntity
--- @return TransportLineConnector
function TransportLineConnector.new(canPlaceEntityFunc, placeEntityFunc, getEntityFunc)
    assertNotNull(canPlaceEntityFunc, placeEntityFunc, getEntityFunc)
    return setmetatable(
            { canPlaceEntityFunc = canPlaceEntityFunc,
              placeEntityFunc = placeEntityFunc,
              getEntityFunc = getEntityFunc
            }, TransportLineConnector)
end

--- @class LineConnectConfig
--- @field allowUnderground boolean default true
--- @field preferHorizontal boolean default true

--- @param startingEntity LuaEntity
--- @param endingEntity LuaEntity
--- @param additionalConfig LineConnectConfig optional
function TransportLineConnector:buildTransportLine(startingEntity, endingEntity, additionalConfig)
    assertNotNull(self, startingEntity, endingEntity)
    if not startingEntity.valid then
        return "starting line entity is no longer valid"
    end
    if not endingEntity.valid then
        return "ending line entity is no longer valid"
    end
    local onGroundVersion = TransportLineType.onGroundVersionOf(startingEntity.name)
    if not onGroundVersion then
        return "Can't find an above-ground version of this entity"
    end
    startingEntity = {
        name = onGroundVersion.name,
        position = Vector2D.fromPosition(startingEntity.position),
        direction = startingEntity.direction or defines.direction.north
    }
    logging.log(startingEntity)
    endingEntity = {
        name = endingEntity.name,
        position = Vector2D.fromPosition(endingEntity.position),
        direction = endingEntity.direction or defines.direction.north
    }
    local allowUnderground = true
    if additionalConfig and additionalConfig.allowUnderground ~= nil then
        allowUnderground = additionalConfig.allowUnderground
    end
    local preferHorizontal = (additionalConfig and (additionalConfig.preferHorizontal ~= nil)) and additionalConfig.preferHorizontal or true
    local minDistanceDict = MinDistanceDict.new()
    local priorityQueue = MinHeap.new()
    local startingEntityTargetPos = DirectionHelper.targetPositionOf(startingEntity)
    if not self.canPlaceEntityFunc(startingEntityTargetPos) then
        logging.log("starting entity's target position is blocked")
        return
    end
    -- A* algorithm starts from endingEntity so that we don't have to consider/change last belt's direction
    priorityQueue:push(0, TransportChain.new(endingEntity, nil))
    local maxTryNum = 1000
    local tryNum = 0
    while not priorityQueue:isEmpty() and tryNum < maxTryNum do
        --- @type TransportChain
        local transportChain = priorityQueue:pop().val

        local continue = false
        if transportChain.entity.position == startingEntityTargetPos then
            -- make sure direction diff is no more than 90 deg for belts or 0 deg underground belt
            local isUnderground = PrototypeInfo.is_underground_transport(transportChain.entity.name)
            if isUnderground and transportChain.entity.direction == startingEntity.direction
                    or
                    not isUnderground and (transportChain.entity.direction - startingEntity.direction) % 8 <= 2 then
                transportChain:placeAllEntities(self.placeEntityFunc)
                logging.log("Path find algorithm explored " .. tostring(tryNum) .. " blocks to find solution")
                return
            else
                continue = true
            end
        end
        if not continue then
            for entity, travelDistance in pairs(self:surroundingCandidates(transportChain, minDistanceDict, game.entity_prototypes[startingEntity.name], allowUnderground)) do
                assert(entity and travelDistance)
                local newChain = TransportChain.new(entity, transportChain, travelDistance)
                priorityQueue:push(self:estimateDistance(entity, startingEntityTargetPos, startingEntity.direction, preferHorizontal, not preferHorizontal) + newChain.cumulativeDistance, newChain)
            end
        end
        tryNum = tryNum + 1
    end
    if priorityQueue:isEmpty() then
        self:debug_visited_position(minDistanceDict)
        return "Path finding terminated, there is probably no path between the two entity"
    else
        self:debug_visited_position(minDistanceDict)
        return "Failed to connect transport line within " .. tostring(maxTryNum) .. " trials"
    end
    return
end

--- @param basePrototype LuaEntityPrototype transport line's base entity prototype
--- @param transportChain TransportChain
--- @return table<LuaEntity, number> entity to its travel distance
function TransportLineConnector:surroundingCandidates(transportChain, visitedPositions, basePrototype, allowUnderground)
    assertNotNull(self, transportChain, basePrototype, allowUnderground)

    local underground_prototype = TransportLineType.undergroundVersionOf(basePrototype.name)
    --- @type table<LuaEntity, number>
    local candidates = {}
    --- @type table<defines.direction, boolean>
    local legalDirections
    if PrototypeInfo.is_underground_transport(transportChain.entity.name) then
        -- underground belt's input only allows one direction
        legalDirections = { [Vector2D.fromDirection(transportChain.entity.direction):reverse():toDirection()] = true }
    else
        -- normal belt would allow 3 legal directions
        legalDirections = {
            [defines.direction.north] = true,
            [defines.direction.west] = true,
            [defines.direction.south] = true,
            [defines.direction.east] = true
        }
        legalDirections[transportChain.entity.direction or defines.direction.north] = nil
    end
    for direction, _ in pairs(legalDirections) do
        local directionVector = Vector2D.fromDirection(direction)
        -- test if we can place it underground
        if allowUnderground then
            local targetPos = Vector2D.fromPosition(transportChain.entity.position)
            local outputUndergroundPos = directionVector + targetPos
            -- make sure output underground belt can fit into map
            if self.canPlaceEntityFunc(outputUndergroundPos) then
                for underground_distance = underground_prototype.max_underground_distance + 1, 3, -1 do
                    candidates[{
                        name = underground_prototype.name,
                        direction = directionVector:reverse():toDirection(),
                        position = directionVector:scale(underground_distance) + targetPos
                    }] = underground_distance
                end
            end
        end
        -- test if we can place it on ground
        local onGroundPos = directionVector + Vector2D.fromPosition(transportChain.entity.position)
        candidates[{
            name = basePrototype.name,
            direction = directionVector:reverse():toDirection(),
            position = onGroundPos
        }] = 1
    end
    local legalCandidates = {}
    for candidateEntity, travelDistance in pairs(candidates) do
        if self:testCanPlace(candidateEntity, transportChain.cumulativeDistance + travelDistance, visitedPositions, travelDistance) then
            legalCandidates[candidateEntity] = travelDistance
        end
    end
    return legalCandidates
end

--- @param entity LuaEntity
--- @param cumulativeDistance number
--- @param minDistanceDict MinDistanceDict
function TransportLineConnector:testCanPlace(entity, cumulativeDistance, minDistanceDict, undergroundDistance)
    assertNotNull(self, entity, cumulativeDistance, minDistanceDict)
    if not self.canPlaceEntityFunc(entity.position) then
        return false
    end
    if PrototypeInfo.is_underground_transport(entity.name) then
        -- make sure there is no interfering underground belts whose direction is parallel to our underground belt pair
        for testDiff = 1, undergroundDistance - 1, 1 do
            local testPos = entity.position + Vector2D.fromDirection(entity.direction):scale(testDiff)
            local entityInMiddle = self.getEntityFunc(testPos)
            if entityInMiddle and ((entity.direction or defines.direction.north) - entity.direction) % 4 == 0 and entityInMiddle.name == entity.name then
                return false
            end
        end
    end

    -- we only consider those path whose distance could be smaller at the position, like dijkstra algorithm
    local distanceSmallerThanAny = false
    for _, sourceEntity in ipairs(DirectionHelper.legalSourcesOf(entity)) do
        local curMinDistance = minDistanceDict:get(sourceEntity.position, sourceEntity.direction)
        if curMinDistance == nil or curMinDistance > cumulativeDistance then
            minDistanceDict:put(sourceEntity.position, sourceEntity.direction, cumulativeDistance)
            distanceSmallerThanAny = true
        end
    end
    return distanceSmallerThanAny
end

--- A* algorithm's heuristics cost
--- @param testEntity LuaEntity
--- @param targetPos Vector2D
--- @param rewardDirection defines.direction
function TransportLineConnector:estimateDistance(testEntity, targetPos, rewardDirection, rewardHorizontalFirst, rewardVerticalFirst)
    local dx = math.abs(testEntity.position.x - targetPos.x)
    local dy = math.abs(testEntity.position.y - targetPos.y)
    -- break A* cost tie by rewarding going to same x/y-level, but reward is no more than 1
    local positionReward = (rewardHorizontalFirst and (1 / (dy + 1)) or 0) + (rewardVerticalFirst and (1 / (dx + 1)) or 0)
    -- direction becomes increasingly important as belt is closer to starting entity, but reward is no more than 1
    -- We punish reversed direction, and reward same direction
    local directionReward = -1 * ((testEntity.direction - rewardDirection) % 8 / 2 - 1) / (dx + dy + 1)
    logging.log("reward = " .. tostring(positionReward), "reward")
    return (dx + dy - positionReward - directionReward) * 1.5
end

--- @param visitedPositions MinDistanceDict
function TransportLineConnector:debug_visited_position(visitedPositions)
    if not release_mode then
        visitedPositions:forEach(
                function(vector, _, _)
                    if self.canPlaceEntityFunc(vector) then
                        self.placeEntityFunc({ name = "small-lamp", position = vector })
                    end
                end)
    end
end

return TransportLineConnector
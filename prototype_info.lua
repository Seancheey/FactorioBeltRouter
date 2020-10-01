local logging = require("__MiscLib__/logging")

local PrototypeInfo = {}

local corresponding_underground_transport_line_table = {
    ["pipe"] = "pipe-to-ground",
    ["transport-belt"] = "underground-belt",
    ["fast-transport-belt"] = "fast-underground-belt",
    ["express-transport-belt"] = "express-underground-belt"
}

--- @param transport_name string prototype name of either a transport belt or a pipe
--- @return LuaEntityPrototype
function PrototypeInfo.underground_transport_prototype(transport_name)
    if corresponding_underground_transport_line_table[transport_name] ~= nil then
        return game.entity_prototypes[corresponding_underground_transport_line_table[transport_name]]
    else
        if game.entity_prototypes[transport_name].belt_speed then
            logging.log(transport_name .. " is not one of known transport belt with underground version")
            return game.entity_prototypes["express-underground-belt"]
        elseif game.entity_prototypes[transport_name].fluid_capacity then
            logging.log(transport_name .. "is not one of known pipe with underground version")
            return game.entity_prototypes["pipe-to-ground"]
        end
    end

    assert(false, transport_name .. " is neither a transport belt nor a pipe, and hence shall not have a corresponding underground version of it")
end

function PrototypeInfo.is_underground_transport(name)
    if game.entity_prototypes[name].max_underground_distance then
        return true
    end
    return false
end

return PrototypeInfo
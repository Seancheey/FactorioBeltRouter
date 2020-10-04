--- @class PrototypeInfo
--- @type PrototypeInfo
local PrototypeInfo = {}


function PrototypeInfo.is_underground_transport(name)
    if game.entity_prototypes[name].max_underground_distance then
        return true
    end
    return false
end

return PrototypeInfo
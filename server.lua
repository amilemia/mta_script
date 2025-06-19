local vehicleAttachments = {}

addEvent("attachObjectToVehicle", true)
addEventHandler("attachObjectToVehicle", resourceRoot, function(veh, modelID, ox, oy, oz)
    if not isElement(veh) or type(modelID) ~= "number" then
        return
    end

    ox, oy, oz = tonumber(ox) or 0, tonumber(oy) or 0, tonumber(oz) or 0

    local obj = createObject(modelID, 0, 0, 0)
    attachElements(obj, veh, ox, oy, oz)

    vehicleAttachments[veh] = vehicleAttachments[veh] or {}
    table.insert(vehicleAttachments[veh], obj)

    triggerClientEvent(client, "onObjectAttached", resourceRoot, obj)
end)

-- Create multiple attachments from client provided data
addEvent("loadVehicleAttachments", true)
addEventHandler("loadVehicleAttachments", resourceRoot, function(veh, attachments)
    if not isElement(veh) or type(attachments) ~= "table" then
        return
    end

    for _, data in ipairs(attachments) do
        local modelID = tonumber(data.id)
        if modelID and engineGetModelNameFromID(modelID) then
            local x = tonumber(data.x) or 0
            local y = tonumber(data.y) or 0
            local z = tonumber(data.z) or 0
            local rx = tonumber(data.rx) or 0
            local ry = tonumber(data.ry) or 0
            local rz = tonumber(data.rz) or 0
            local sx = tonumber(data.sx) or 1
            local sy = tonumber(data.sy) or sx
            local sz = tonumber(data.sz) or sx

            local obj = createObject(modelID, 0, 0, 0)
            attachElements(obj, veh, x, y, z, rx, ry, rz)
            setObjectScale(obj, sx, sy, sz)

            vehicleAttachments[veh] = vehicleAttachments[veh] or {}
            table.insert(vehicleAttachments[veh], obj)

            triggerClientEvent(client, "onObjectAttached", resourceRoot, obj)
        end
    end
end)

local function cleanupVehicleAttachments(veh)
    if vehicleAttachments[veh] then
        for _, obj in ipairs(vehicleAttachments[veh]) do
            if isElement(obj) then
                destroyElement(obj)
            end
        end
        vehicleAttachments[veh] = nil
    end
end

addEventHandler("onElementDestroy", root, function()
    if getElementType(source) == "vehicle" then
        cleanupVehicleAttachments(source)
    end
end)

addEventHandler("onResourceStop", resourceRoot, function()
    for veh in pairs(vehicleAttachments) do
        cleanupVehicleAttachments(veh)
    end
end)

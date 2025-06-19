local vehicleAttachments = {}

addEvent("attachObjectToVehicle", true)
addEventHandler("attachObjectToVehicle", resourceRoot, function(veh, modelID, ox, oy, oz)
    if not isElement(veh) or type(modelID) ~= "number" then
        return
    end

    ox, oy, oz = tonumber(ox) or 0, tonumber(oy) or 0, tonumber(oz) or 0

    local obj = createObject(modelID, 0, 0, 0)
    setElementDimension(obj, getElementDimension(veh))
    setElementInterior(obj, getElementInterior(veh))
    attachElements(obj, veh, ox, oy, oz)

    vehicleAttachments[veh] = vehicleAttachments[veh] or {}
    table.insert(vehicleAttachments[veh], obj)

    triggerClientEvent(client, "onObjectAttached", resourceRoot, obj)
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

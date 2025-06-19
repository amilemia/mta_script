addEvent("attachObjectToVehicle", true)
addEventHandler("attachObjectToVehicle", resourceRoot, function(veh, modelID, ox, oy, oz)
    if isElement(veh) and type(modelID) == "number" then
        ox, oy, oz = tonumber(ox) or 0, tonumber(oy) or 0, tonumber(oz) or 0
        local obj = createObject(modelID, 0, 0, 0)
        attachElements(obj, veh, ox, oy, oz)
        triggerClientEvent(client, "onObjectAttached", resourceRoot, obj)
    end
end)

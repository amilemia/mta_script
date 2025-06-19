addEvent("attachObjectToVehicle", true)
addEventHandler("attachObjectToVehicle", resourceRoot, function(veh, modelID)
    if isElement(veh) and type(modelID) == "number" then
        local x, y, z = getElementPosition(veh)
        local obj = createObject(modelID, x, y, z + 1)
        attachElements(obj, veh, 0, 0, 1)
        triggerClientEvent(client, "onObjectAttached", resourceRoot, obj)
    end
end)

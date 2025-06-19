local xmlFile = "attachments.xml"
local favoriteObjects = {}
local attachedObjects = {}
local selectedObject = nil
local lastClickTime = 0

local screenW, screenH = guiGetScreenSize()
local window = guiCreateWindow(screenW/2 - 200, screenH/2 - 250, 400, 500, "Attach Object to Vehicle", false)
local objectList = guiCreateGridList(0.05, 0.1, 0.9, 0.6, true, window)
local attachBtn = guiCreateButton(0.1, 0.71, 0.8, 0.08, "Attach to Vehicle", true, window)
local saveBtn = guiCreateButton(0.1, 0.80, 0.35, 0.08, "Save Setup", true, window)
local loadBtn = guiCreateButton(0.55, 0.80, 0.35, 0.08, "Load Setup", true, window)
local closeBtn = guiCreateButton(0.1, 0.89, 0.8, 0.08, "Close", true, window)

guiWindowSetSizable(window, false)
guiSetVisible(window, false)

guiGridListAddColumn(objectList, "Object ID", 0.9)

-- Load all usable object model IDs from 1000 to 20000
for i = 1000, 20000 do
    if engineGetModelNameFromID(i) then
        local row = guiGridListAddRow(objectList)
        guiGridListSetItemText(objectList, row, 1, tostring(i), false, false)
    end
end

bindKey("F7", "down", function()
    if getPedOccupiedVehicle(localPlayer) then
        guiSetVisible(window, not guiGetVisible(window))
        showCursor(guiGetVisible(window))
    else
        outputChatBox("You must be in a vehicle to use this menu.", 255, 0, 0)
    end
end)

-- Attach button
addEventHandler("onClientGUIClick", root, function()
    if source == attachBtn then
        local row = guiGridListGetSelectedItem(objectList)
        if row ~= -1 then
            local objID = tonumber(guiGridListGetItemText(objectList, row, 1))
            local veh = getPedOccupiedVehicle(localPlayer)
            if veh and objID then
                triggerServerEvent("attachObjectToVehicle", resourceRoot, veh, objID)
            end
        end
    elseif source == saveBtn then
        saveAttachments()
    elseif source == loadBtn then
        loadAttachments()
    elseif source == closeBtn then
        guiSetVisible(window, false)
        showCursor(false)
    elseif source == objectList then
        local now = getTickCount()
        if now - lastClickTime < 500 then
            local row = guiGridListGetSelectedItem(objectList)
            local id = tonumber(guiGridListGetItemText(objectList, row, 1))
            if id then
                favoriteObjects[id] = true
                guiGridListSetItemColor(objectList, row, 1, 255, 215, 0)
                outputChatBox("Added object " .. id .. " to favorites.")
            end
        end
        lastClickTime = getTickCount()
    end
end)

-- Receive attached object from server and track it
addEvent("onObjectAttached", true)
addEventHandler("onObjectAttached", resourceRoot, function(obj)
    table.insert(attachedObjects, obj)
    selectedObject = obj
end)

function saveAttachments()
    if fileExists(xmlFile) then fileDelete(xmlFile) end
    local xml = xmlCreateFile(xmlFile, "attachments")
    for _, obj in ipairs(attachedObjects) do
        if isElement(obj) then
            local id = getElementModel(obj)
            local x, y, z, rx, ry, rz = getElementAttachedOffsets(obj)
            local scale = getObjectScale(obj)
            local node = xmlCreateChild(xml, "object")
            xmlNodeSetAttribute(node, "id", tostring(id))
            xmlNodeSetAttribute(node, "x", tostring(x))
            xmlNodeSetAttribute(node, "y", tostring(y))
            xmlNodeSetAttribute(node, "z", tostring(z))
            xmlNodeSetAttribute(node, "rx", tostring(rx))
            xmlNodeSetAttribute(node, "ry", tostring(ry))
            xmlNodeSetAttribute(node, "rz", tostring(rz))
            xmlNodeSetAttribute(node, "scale", tostring(scale))
        end
    end
    xmlSaveFile(xml)
    xmlUnloadFile(xml)
    outputChatBox("Attachment setup saved.")
end

function loadAttachments()
    if not fileExists(xmlFile) then
        outputChatBox("No saved attachment found.")
        return
    end
    local xml = xmlLoadFile(xmlFile)
    local veh = getPedOccupiedVehicle(localPlayer)
    if not veh then
        outputChatBox("You must be in a vehicle.")
        xmlUnloadFile(xml)
        return
    end

    for _, node in ipairs(xmlNodeGetChildren(xml)) do
        local id = tonumber(xmlNodeGetAttribute(node, "id"))
        local x = tonumber(xmlNodeGetAttribute(node, "x"))
        local y = tonumber(xmlNodeGetAttribute(node, "y"))
        local z = tonumber(xmlNodeGetAttribute(node, "z"))
        local rx = tonumber(xmlNodeGetAttribute(node, "rx"))
        local ry = tonumber(xmlNodeGetAttribute(node, "ry"))
        local rz = tonumber(xmlNodeGetAttribute(node, "rz"))
        local scale = tonumber(xmlNodeGetAttribute(node, "scale"))
        local obj = createObject(id, 0, 0, 0)
        attachElements(obj, veh, x, y, z, rx, ry, rz)
        setObjectScale(obj, scale)
        table.insert(attachedObjects, obj)
    end
    xmlUnloadFile(xml)
    outputChatBox("Attachments loaded.")
end

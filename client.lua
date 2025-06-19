local xmlFile = "attachments.xml"
local favoriteObjects = {}
local attachedObjects = {}
local selectedObject = nil
local lastClickTime = 0
local MAX_ATTACHMENTS = 10

local pageSize = 100
local currentPage = 1
local allObjects = {}

local screenW, screenH = guiGetScreenSize()
local window = guiCreateWindow(screenW/2 - 200, screenH/2 - 250, 400, 500, "Attach Object to Vehicle", false)
local objectList = guiCreateGridList(0.05, 0.12, 0.9, 0.6, true, window)
local prevBtn = guiCreateButton(0.05, 0.08, 0.2, 0.04, "<", true, window)
local pageLabel = guiCreateLabel(0.4, 0.08, 0.2, 0.04, "", true, window)
local nextBtn = guiCreateButton(0.75, 0.08, 0.2, 0.04, ">", true, window)
local attachBtn = guiCreateButton(0.1, 0.74, 0.8, 0.08, "Attach to Vehicle", true, window)
local saveBtn = guiCreateButton(0.1, 0.80, 0.35, 0.08, "Save Setup", true, window)
local loadBtn = guiCreateButton(0.55, 0.80, 0.35, 0.08, "Load Setup", true, window)
local closeBtn = guiCreateButton(0.1, 0.89, 0.8, 0.08, "Close", true, window)

guiWindowSetSizable(window, false)
guiSetVisible(window, false)

guiGridListAddColumn(objectList, "Object ID", 0.9)

-- Cache all usable object model IDs and populate the first page
for i = 1000, 20000 do
    if engineGetModelNameFromID(i) then
        table.insert(allObjects, i)
    end
end

local function updateObjectList()
    guiGridListClear(objectList)
    local totalPages = math.max(1, math.ceil(#allObjects / pageSize))
    if currentPage > totalPages then currentPage = totalPages end
    local start = (currentPage - 1) * pageSize + 1
    local finish = math.min(start + pageSize - 1, #allObjects)
    for idx = start, finish do
        local row = guiGridListAddRow(objectList)
        guiGridListSetItemText(objectList, row, 1, tostring(allObjects[idx]), false, false)
    end
    guiSetText(pageLabel, string.format("Page %d/%d", currentPage, totalPages))
end

updateObjectList()

bindKey("F7", "down", function()
    if getPedOccupiedVehicle(localPlayer) then
        guiSetVisible(window, not guiGetVisible(window))
        if guiGetVisible(window) then
            updateObjectList()
        end
        showCursor(guiGetVisible(window))
    else
        outputChatBox("You must be in a vehicle to use this menu.", 255, 0, 0)
    end
end)

-- Attach button
addEventHandler("onClientGUIClick", root, function()
    if source == attachBtn then
        if #attachedObjects >= MAX_ATTACHMENTS then
            outputChatBox("Attachment limit reached.", 255, 0, 0)
            return
        end
        local row = guiGridListGetSelectedItem(objectList)
        if row ~= -1 then
            local objID = tonumber(guiGridListGetItemText(objectList, row, 1))
            if not engineGetModelNameFromID(objID) then
                outputChatBox("Invalid object ID.", 255, 0, 0)
                return
            end
            local veh = getPedOccupiedVehicle(localPlayer)
            if veh and objID then
                triggerServerEvent("attachObjectToVehicle", resourceRoot, veh, objID, 0, 0, 1)
            end
        end
    elseif source == prevBtn then
        if currentPage > 1 then
            currentPage = currentPage - 1
            updateObjectList()
        end
    elseif source == nextBtn then
        if currentPage < math.ceil(#allObjects / pageSize) then
            currentPage = currentPage + 1
            updateObjectList()
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

local function cleanupObjects()
    for _, obj in ipairs(attachedObjects) do
        if isElement(obj) then
            destroyElement(obj)
        end
    end
    attachedObjects = {}
end

addEventHandler("onClientElementDestroy", root, function()
    if source == getPedOccupiedVehicle(localPlayer) then
        cleanupObjects()
    end
end)

addEventHandler("onClientResourceStop", resourceRoot, cleanupObjects)

function saveAttachments()
    if fileExists(xmlFile) then fileDelete(xmlFile) end
    local xml = xmlCreateFile(xmlFile, "attachments")
    if not xml then
        outputChatBox("Failed to create attachment file.", 255, 0, 0)
        return
    end
    for _, obj in ipairs(attachedObjects) do
        if isElement(obj) then
            local id = getElementModel(obj)
            local x, y, z, rx, ry, rz = getElementAttachedOffsets(obj)
            local sx, sy, sz = getObjectScale(obj)
            sy = sy or sx
            sz = sz or sx
            local node = xmlCreateChild(xml, "object")
            xmlNodeSetAttribute(node, "id", tostring(id))
            xmlNodeSetAttribute(node, "x", tostring(x))
            xmlNodeSetAttribute(node, "y", tostring(y))
            xmlNodeSetAttribute(node, "z", tostring(z))
            xmlNodeSetAttribute(node, "rx", tostring(rx))
            xmlNodeSetAttribute(node, "ry", tostring(ry))
            xmlNodeSetAttribute(node, "rz", tostring(rz))
            xmlNodeSetAttribute(node, "sx", tostring(sx))
            xmlNodeSetAttribute(node, "sy", tostring(sy))
            xmlNodeSetAttribute(node, "sz", tostring(sz))
        end
    end
  
    if xmlSaveFile(xml) then
        outputChatBox("Attachment setup saved.")
    else
        outputChatBox("Failed to save attachment file.", 255, 0, 0)
    end
    xmlUnloadFile(xml)
end

function loadAttachments()
    if not fileExists(xmlFile) then
        outputChatBox("No saved attachment found.")
        return
    end
    local xml = xmlLoadFile(xmlFile)
    if not xml then
        outputChatBox("Failed to load attachment file.", 255, 0, 0)
        return
    end
    local veh = getPedOccupiedVehicle(localPlayer)
    if not veh then
        outputChatBox("You must be in a vehicle.")
        xmlUnloadFile(xml)
        return
    end

    local attachments = {}
    for _, node in ipairs(xmlNodeGetChildren(xml)) do
        table.insert(attachments, {
            id = tonumber(xmlNodeGetAttribute(node, "id")),
            x = tonumber(xmlNodeGetAttribute(node, "x")),
            y = tonumber(xmlNodeGetAttribute(node, "y")),
            z = tonumber(xmlNodeGetAttribute(node, "z")),
            rx = tonumber(xmlNodeGetAttribute(node, "rx")),
            ry = tonumber(xmlNodeGetAttribute(node, "ry")),
            rz = tonumber(xmlNodeGetAttribute(node, "rz")),
            sx = tonumber(xmlNodeGetAttribute(node, "sx")) or 1,
            sy = tonumber(xmlNodeGetAttribute(node, "sy")),
            sz = tonumber(xmlNodeGetAttribute(node, "sz")),
        })
    end
    xmlUnloadFile(xml)
    triggerServerEvent("loadVehicleAttachments", resourceRoot, veh, attachments)
    outputChatBox("Attachments loaded.")
end

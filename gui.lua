-- GUI creation for two tabs: Attach Objects / Transform Editor
local screenW, screenH = guiGetScreenSize()
mainWindow = guiCreateTabPanel(screenW/2 - 400, screenH/2 - 300, 800, 600, false)
guiSetVisible(mainWindow, false)

-- Tab 1: Attach / Attached Objects
attachTab = guiCreateTab("Attach Objects", mainWindow)
objectList = guiCreateGridList(0.55, 0.05, 0.4, 0.7, true, attachTab)
guiGridListAddColumn(objectList, "Object ID", 0.9)

attachedList = guiCreateGridList(0.05, 0.73, 0.45, 0.2, true, attachTab)
guiGridListAddColumn(attachedList, "Attached ID", 0.9)

attachBtn = guiCreateButton(0.55, 0.76, 0.15, 0.08, "Attach", true, attachTab)
deleteBtn = guiCreateButton(0.72, 0.76, 0.15, 0.08, "Delete", true, attachTab)
resetBtn = guiCreateButton(0.55, 0.86, 0.15, 0.08, "Reset", true, attachTab)
unprotectBtn = guiCreateButton(0.72, 0.86, 0.15, 0.08, "Unprotect", true, attachTab)
saveBtn = guiCreateButton(0.05, 0.86, 0.2, 0.08, "Save Setup", true, attachTab)
loadBtn = guiCreateButton(0.27, 0.86, 0.2, 0.08, "Load Setup", true, attachTab)

-- Tab 2: Transform Controls
controlTab = guiCreateTab("Transform Editor", mainWindow)
sliders = {}
local sliderLabels = {"X", "Y", "Z", "RotX", "RotY", "RotZ", "Scale", "DefX", "DefY", "DefZ"}
for i = 1, #sliderLabels do
    guiCreateLabel(0.05, 0.03 + (i - 1) * 0.065, 0.1, 0.05, sliderLabels[i], true, controlTab)
    sliders[sliderLabels[i]] = guiCreateScrollBar(0.15, 0.03 + (i - 1) * 0.065, 0.35, 0.04, true, true, controlTab)
end

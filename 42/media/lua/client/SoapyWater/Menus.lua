require "SoapyWater/Items"
require "TimedActions/ISAddSoapAction"

-- Walks next to a container that isn't carried (vanilla skips the walk when already close),
-- then soaps it where it is.
local function onAddSoap(playerObj, fc)
    local owner = fc:getOwner()
    local square = SoapyWater.fcSquare(fc)
    if instanceof(owner, "IsoObject") then
        if not luautils.walkAdjObject(playerObj, owner, true) then return end
    elseif square then
        if not luautils.walkAdj(playerObj, square) then return end
    end
    ISTimedActionQueue.add(ISAddSoapAction:new(playerObj, fc))
end

local function litres(x)
    return string.format("%.1f", x)
end

-- "Add soap" for one container; says how much turns soapy when the soap won't cover it all,
-- greyed out with a tooltip when there is no soap. prefix names the container when several share a menu.
function SoapyWater.addSoapOption(context, playerObj, fc, prefix)
    local plain = SoapyWater.amounts(fc)
    local have = SoapyWater.soapTotal(playerObj:getInventory())
    local converted = SoapyWater.convertPlan(plain, have)
    local text = getText("ContextMenu_SoapyWater_AddSoap")
    if have > 0 and converted < plain - SoapyWater.EPS then
        text = getText("ContextMenu_SoapyWater_AddSoapPartial", litres(converted), litres(plain))
    end
    if prefix then text = prefix .. ": " .. text end
    local option = context:addOption(text, playerObj, onAddSoap, fc)
    if have <= 0 then
        option.notAvailable = true
        local tooltip = ISInventoryPaneContextMenu.addToolTip()
        tooltip.description = getText("Tooltip_SoapyWater_NoSoap")
        option.toolTip = tooltip
    end
    return option
end

-- Inventory and loot panel (floor, crates, shelves): the item stays where it is.
local function inventorySoapOption(player, context, items)
    local item = items[1]
    if item and not instanceof(item, "InventoryItem") then item = item.items[1] end
    local fc = item and item:getFluidContainer()
    if not SoapyWater.isSoapable(fc) or not SoapyWater.acceptsSoapyWater(fc) then return end
    SoapyWater.addSoapOption(context, getSpecificPlayer(player), fc, nil)
end

Events.OnFillInventoryObjectContextMenu.Add(inventorySoapOption)

require "TimedActions/ISCleanWithSoapyWater"

local function predicateSoapy(item)
    return SoapyWater.isCleaner(item)
end

local function predicateNotBroken(item)
    return not item:isBroken()
end

function SoapyWater.canClean(playerObj, square)
    local inv = playerObj:getInventory()
    return square ~= nil and square:haveStains()
        and inv:containsEvalRecurse(predicateSoapy)
        and inv:containsTagEvalRecurse(ItemTag.CLEAN_STAINS, predicateNotBroken)
end

-- Same steps as vanilla ISWorldObjectContextMenu.doCleanBlood, with soapy water.
function SoapyWater.doClean(playerObj, square)
    local player = playerObj:getPlayerNum()
    local inv = playerObj:getInventory()
    if not luautils.walkAdj(playerObj, square) then return end
    local water
    if playerObj:getSecondaryHandItem() and predicateSoapy(playerObj:getSecondaryHandItem()) then
        water = playerObj:getSecondaryHandItem()
    else
        water = inv:getFirstEvalRecurse(predicateSoapy)
        ISWorldObjectContextMenu.transferIfNeeded(playerObj, water)
    end
    local tool
    if playerObj:getPrimaryHandItem() and playerObj:getPrimaryHandItem():hasTag(ItemTag.CLEAN_STAINS) then
        tool = playerObj:getPrimaryHandItem()
    else
        tool = inv:getFirstTagEvalRecurse(ItemTag.CLEAN_STAINS, predicateNotBroken)
        ISWorldObjectContextMenu.transferIfNeeded(playerObj, tool)
    end
    if instanceof(tool, "HandWeapon") and tool:isTwoHandWeapon() then
        ISInventoryPaneContextMenu.equipWeapon(tool, true, true, player)
    else
        ISInventoryPaneContextMenu.equipWeapon(tool, true, false, player)
        ISInventoryPaneContextMenu.equipWeapon(water, false, false, player)
    end
    ISTimedActionQueue.add(ISCleanWithSoapyWater:new(playerObj, square, water))
end

-- SoapyWaterCleanCursor is defined in server/SoapyWater/CleanCursor.lua.
local function onClean(worldobjects, player)
    local playerObj = getSpecificPlayer(player)
    getCell():setDrag(SoapyWaterCleanCursor:new("", "", playerObj), player)
end

local function cleanOption(player, context, worldobjects, test)
    if test then return end
    local object = worldobjects[1]
    local square = object and object:getSquare()
    if SoapyWater.canClean(getSpecificPlayer(player), square) then
        context:addOption(getText("ContextMenu_SoapyWater_Clean"), worldobjects, onClean, player)
    end
end

Events.OnFillWorldObjectContextMenu.Add(cleanOption)

local function addCandidate(list, seen, fc, name)
    if fc and not seen[fc] and SoapyWater.isSoapable(fc) and SoapyWater.acceptsSoapyWater(fc) then
        seen[fc] = true
        list[#list + 1] = {fc = fc, name = name}
    end
end

-- World right-click: rain collectors, barrels and other objects holding water, and items on the floor.
local function worldSoapOption(player, context, worldobjects, test)
    if test then return end
    local square = worldobjects[1] and worldobjects[1]:getSquare()
    if not square then return end
    local list, seen = {}, {}
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        local fc = obj:getFluidContainer()
        addCandidate(list, seen, fc, fc and fc:getTranslatedContainerName())
    end
    local floor = square:getWorldObjects()
    for i = 0, floor:size() - 1 do
        local item = floor:get(i):getItem()
        if item then addCandidate(list, seen, item:getFluidContainer(), item:getDisplayName()) end
    end
    local playerObj = getSpecificPlayer(player)
    for _, c in ipairs(list) do
        local prefix = nil
        if #list > 1 and c.name and c.name ~= "" then prefix = c.name end
        SoapyWater.addSoapOption(context, playerObj, c.fc, prefix)
    end
end

Events.OnFillWorldObjectContextMenu.Add(worldSoapOption)

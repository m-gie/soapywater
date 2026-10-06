require "SoapyWater/Items"
require "TimedActions/ISAddSoapAction"

local function onAddSoap(playerObj, item)
    ISInventoryPaneContextMenu.transferIfNeeded(playerObj, item)
    ISTimedActionQueue.add(ISAddSoapAction:new(playerObj, item))
end

-- "Add soap" on a container holding only water. Greyed out with a tooltip when soap is short.
local function addSoapOption(player, context, items)
    local item = items[1]
    if item and not instanceof(item, "InventoryItem") then item = item.items[1] end
    if not SoapyWater.isWaterOnly(item) or not SoapyWater.acceptsSoapyWater(item) then return end
    local playerObj = getSpecificPlayer(player)
    local needed = SoapyWater.usesNeeded(item:getFluidContainer():getAmount())
    local uses = SoapyWater.soapUses(SoapyWater.soapBars(playerObj:getInventory()))
    local have = 0
    for _, n in ipairs(uses) do have = have + n end
    local option = context:addOption(getText("ContextMenu_SoapyWater_AddSoap"), playerObj, onAddSoap, item)
    if have < needed then
        option.notAvailable = true
        local tooltip = ISInventoryPaneContextMenu.addToolTip()
        tooltip.description = getText("Tooltip_SoapyWater_NeedSoap", needed, have)
        option.toolTip = tooltip
    end
end

Events.OnFillInventoryObjectContextMenu.Add(addSoapOption)

require "TimedActions/ISCleanWithSoapyWater"

local function predicateSoapy(item)
    return SoapyWater.hasSoapyWater(item)
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

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

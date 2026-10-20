require "TimedActions/ISBaseTimedAction"
require "Fluids/ISFluidContainer"
require "SoapyWater/Items"

ISAddSoapAction = ISBaseTimedAction:derive("ISAddSoapAction")

-- The item that owns the fluid container, or nil for a world object.
local function ownerItem(fc)
    local owner = fc and fc:getOwner()
    if instanceof(owner, "InventoryItem") then return owner end
    return nil
end

-- The container is still where the action found it, and the player is still next to it.
function ISAddSoapAction:inPlace()
    local fc = self.fc
    local owner = fc:getOwner()
    if instanceof(owner, "IsoObject") then
        if not owner:isExistInTheWorld() then return false end
    else
        local item = ownerItem(fc)
        if not item then return false end
        if self.where == nil then
            if not self.character:getInventory():containsRecursive(item) then return false end
        elseif self.itemContainer and not self.itemContainer:contains(item) then
            return false
        end
    end
    return SoapyWater.fcSquare(fc) == self.where and SoapyWater.inReach(self.character, self.where)
end

function ISAddSoapAction:isValid()
    local fc = self.fc
    return fc ~= nil and self:inPlace()
        and SoapyWater.isSoapable(fc) and SoapyWater.acceptsSoapyWater(fc)
        and SoapyWater.soapTotal(self.character:getInventory()) > 0
end

function ISAddSoapAction:update()
    local item = ownerItem(self.fc)
    if item then
        item:setJobDelta(self:getJobDelta())
    elseif instanceof(self.fc:getOwner(), "IsoObject") then
        self.character:faceThisObject(self.fc:getOwner())
    end
    self.character:setMetabolicTarget(Metabolics.LightDomestic)
end

function ISAddSoapAction:start()
    local item = ownerItem(self.fc)
    if item then
        item:setJobType(getText("ContextMenu_SoapyWater_AddSoap"))
        item:setJobDelta(0.0)
    end
    self:setActionAnim(CharacterActionAnims.Craft)
end

function ISAddSoapAction:stop()
    local item = ownerItem(self.fc)
    if item then item:setJobDelta(0.0) end
    ISBaseTimedAction.stop(self)
end

function ISAddSoapAction:perform()
    local item = ownerItem(self.fc)
    if item then item:setJobDelta(0.0) end
    ISBaseTimedAction.perform(self)
end

-- Runs on the server in multiplayer. Plans again: water and soap may have changed since the menu.
-- The soap is only used once the soapy water is really in the container.
function ISAddSoapAction:complete()
    local fc = self.fc
    if not SoapyWater.isSoapable(fc) or not SoapyWater.acceptsSoapyWater(fc) then return false end
    local plain = SoapyWater.amounts(fc)
    local bars = SoapyWater.soapBars(self.character:getInventory())
    local uses = SoapyWater.soapUses(bars)
    local total = 0
    for _, n in ipairs(uses) do total = total + n end
    local litres, taken = SoapyWater.convertPlan(plain, total)
    if litres <= SoapyWater.EPS then return false end
    local plan = SoapyWater.planSoap(uses, taken)
    if not plan then return false end
    if not SoapyWater.convert(fc, litres) then
        self.fluid:sync()
        return false
    end
    for i, bar in ipairs(bars) do
        for _ = 1, plan[i] do
            bar:UseAndSync()
        end
    end
    self.fluid:sync()
    return true
end

function ISAddSoapAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 100
end

-- fc is a FluidContainer: of an item anywhere (inventory, floor, crate) or of a world object.
function ISAddSoapAction:new(character, fc)
    local o = ISBaseTimedAction.new(self, character)
    o.fc = fc
    o.fluid = ISFluidContainer:new(fc)
    o.where = SoapyWater.fcSquare(fc)
    local item = ownerItem(fc)
    o.itemContainer = item and item:getContainer() or nil
    o.maxTime = o:getDuration()
    return o
end

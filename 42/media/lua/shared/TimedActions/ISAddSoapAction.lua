require "TimedActions/ISBaseTimedAction"
require "SoapyWater/Items"

ISAddSoapAction = ISBaseTimedAction:derive("ISAddSoapAction")

-- Plans the soap for the container's current water; plan is nil when soap is short.
local function soapPlan(character, container)
    local needed = SoapyWater.usesNeeded(container:getFluidContainer():getAmount())
    local bars = SoapyWater.soapBars(character:getInventory())
    return bars, SoapyWater.planSoap(SoapyWater.soapUses(bars), needed)
end

function ISAddSoapAction:isValid()
    if not self.character:getInventory():contains(self.container) then return false end
    if not SoapyWater.isWaterOnly(self.container) or not SoapyWater.acceptsSoapyWater(self.container) then return false end
    local _, plan = soapPlan(self.character, self.container)
    return plan ~= nil
end

function ISAddSoapAction:update()
    self.container:setJobDelta(self:getJobDelta())
    self.character:setMetabolicTarget(Metabolics.LightDomestic)
end

function ISAddSoapAction:start()
    self.container:setJobType(getText("ContextMenu_SoapyWater_AddSoap"))
    self.container:setJobDelta(0.0)
    self:setActionAnim(CharacterActionAnims.Craft)
end

function ISAddSoapAction:stop()
    self.container:setJobDelta(0.0)
    ISBaseTimedAction.stop(self)
end

function ISAddSoapAction:perform()
    self.container:setJobDelta(0.0)
    ISBaseTimedAction.perform(self)
end

-- Runs on the server in multiplayer. Plans again: the soap may have been used since the menu.
-- The soap is only used once the soapy water is really in the container.
function ISAddSoapAction:complete()
    local container = self.container
    if not SoapyWater.isWaterOnly(container) or not SoapyWater.acceptsSoapyWater(container) then return false end
    local fc, fluid = container:getFluidContainer(), SoapyWater.fluid()
    local amount = fc:getAmount()
    local water, tainted = fc:getSpecificFluidAmount(Fluid.Water), fc:getSpecificFluidAmount(Fluid.TaintedWater)
    local bars, plan = soapPlan(self.character, container)
    if not plan then return false end
    fc:Empty()
    fc:addFluid(fluid, amount)
    if not fc:isPureFluid(fluid) or fc:getAmount() < amount - SoapyWater.EPS then
        fc:Empty()
        if water > 0 then fc:addFluid(Fluid.Water, water) end
        if tainted > 0 then fc:addFluid(Fluid.TaintedWater, tainted) end
        container:syncItemFields()
        return false
    end
    for i, bar in ipairs(bars) do
        for _ = 1, plan[i] do
            bar:UseAndSync()
        end
    end
    container:syncItemFields()
    return true
end

function ISAddSoapAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 100
end

function ISAddSoapAction:new(character, container)
    local o = ISBaseTimedAction.new(self, character)
    o.container = container
    o.maxTime = o:getDuration()
    return o
end

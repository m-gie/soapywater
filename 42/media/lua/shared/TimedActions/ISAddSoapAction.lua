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
function ISAddSoapAction:complete()
    if not SoapyWater.isWaterOnly(self.container) then return false end
    local fc = self.container:getFluidContainer()
    local amount = fc:getAmount()
    local bars, plan = soapPlan(self.character, self.container)
    if not plan then return false end
    for i, bar in ipairs(bars) do
        for _ = 1, plan[i] do
            bar:UseAndSync()
        end
    end
    fc:Empty()
    fc:addFluid(SoapyWater.fluid(), amount)
    self.container:syncItemFields()
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

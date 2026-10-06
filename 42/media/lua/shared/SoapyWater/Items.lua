-- Thin wrappers over game objects; all rules stay in Logic.lua.
require "SoapyWater/Logic"

local EPS = SoapyWater.EPS

function SoapyWater.fluid()
    return Fluid.Get("SoapyWater")
end

-- True when the item holds some water (clean and/or tainted) and nothing else.
function SoapyWater.isWaterOnly(item)
    local fc = item and item:getFluidContainer()
    if not fc then return false end
    local total = fc:getAmount()
    local water = fc:getSpecificFluidAmount(Fluid.Water) + fc:getSpecificFluidAmount(Fluid.TaintedWater)
    return total > EPS and water >= total - EPS
end

-- canAddFluid would refuse here because the water can't blend with soapy water,
-- so check the container's own limits instead: the same ones canAddFluid checks.
function SoapyWater.acceptsSoapyWater(item)
    local fc = item and item:getFluidContainer()
    local fluid = SoapyWater.fluid()
    if not fc or not fluid or fc:isInputLocked() or not fc:canPlayerEmpty() then return false end
    local whitelist, blacklist = fc:getWhitelist(), fc:getBlacklist()
    return (whitelist == nil or whitelist:allows(fluid)) and (blacklist == nil or blacklist:allows(fluid))
end

function SoapyWater.soapyAmount(item)
    local fc = item and item:getFluidContainer()
    if not fc or not fc:isPureFluid(SoapyWater.fluid()) then return 0 end
    return fc:getAmount()
end

function SoapyWater.hasSoapyWater(item)
    return SoapyWater.soapyAmount(item) >= SoapyWater.LITRES_PER_TILE - EPS
end

-- The container a cleaning action was given is still held and still holds enough.
function SoapyWater.usableCleaner(inventory, item)
    return item ~= nil and inventory:containsRecursive(item) and SoapyWater.hasSoapyWater(item)
end

-- Soap bars with uses left anywhere in the inventory, including bags.
function SoapyWater.soapBars(inventory)
    local list = inventory:getAllTypeEvalRecurse("Base.Soap2", function(item)
        return item:getCurrentUses() > 0
    end)
    local bars = {}
    for i = 0, list:size() - 1 do
        bars[#bars + 1] = list:get(i)
    end
    return bars
end

function SoapyWater.soapUses(bars)
    local uses = {}
    for i, bar in ipairs(bars) do
        uses[i] = bar:getCurrentUses()
    end
    return uses
end

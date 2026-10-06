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
-- so check the container's own limits instead.
function SoapyWater.acceptsSoapyWater(item)
    local fc = item and item:getFluidContainer()
    if not fc or fc:isInputLocked() then return false end
    local whitelist = fc:getWhitelist()
    return whitelist == nil or whitelist:allows(SoapyWater.fluid())
end

function SoapyWater.soapyAmount(item)
    local fc = item and item:getFluidContainer()
    if not fc or not fc:isPureFluid(SoapyWater.fluid()) then return 0 end
    return fc:getAmount()
end

function SoapyWater.hasSoapyWater(item)
    return SoapyWater.soapyAmount(item) >= SoapyWater.LITRES_PER_TILE - EPS
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

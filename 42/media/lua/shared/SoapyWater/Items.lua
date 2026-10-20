-- Thin wrappers over game objects; all rules stay in Logic.lua.
require "SoapyWater/Logic"

local EPS = SoapyWater.EPS

function SoapyWater.fluid()
    return Fluid.Get("SoapyWater")
end

-- The fluids that count as plain water: everything in the Water category.
function SoapyWater.plainFluids()
    local list = {}
    for _, f in ipairs({Fluid.Water, Fluid.TaintedWater, Fluid.CarbonatedWater}) do
        if f then list[#list + 1] = f end
    end
    return list
end

-- Litres of plain water, soapy water, anything else, and in total.
function SoapyWater.amounts(fc)
    local plain = 0
    for _, f in ipairs(SoapyWater.plainFluids()) do
        plain = plain + fc:getSpecificFluidAmount(f)
    end
    local soapy = fc:getSpecificFluidAmount(SoapyWater.fluid())
    local total = fc:getAmount()
    return plain, soapy, math.max(0, total - plain - soapy), total
end

-- Holds some plain water and nothing but water and soapy water.
function SoapyWater.isSoapable(fc)
    if not fc then return false end
    local plain, _, other = SoapyWater.amounts(fc)
    return SoapyWater.isSoapableMix(plain, other)
end

-- The container's own limits (input lock, player emptying, whitelist, blacklist),
-- and what it already holds must mix with soapy water.
function SoapyWater.acceptsSoapyWater(fc)
    local fluid = SoapyWater.fluid()
    if not fc or not fluid or fc:isInputLocked() or not fc:canPlayerEmpty() then return false end
    if not fc:canAddFluid(fluid) then return false end
    local whitelist, blacklist = fc:getWhitelist(), fc:getBlacklist()
    return (whitelist == nil or whitelist:allows(fluid)) and (blacklist == nil or blacklist:allows(fluid))
end

-- Enough for a tile and at least half soapy.
function SoapyWater.isCleaner(item)
    local fc = item and item:getFluidContainer()
    if not fc then return false end
    local plain, soapy, other = SoapyWater.amounts(fc)
    return SoapyWater.isCleanerMix(soapy, plain, other)
end

-- The container a cleaning action was given is still held and still holds enough.
function SoapyWater.usableCleaner(inventory, item)
    return item ~= nil and inventory:containsRecursive(item) and SoapyWater.isCleaner(item)
end

-- Turns this many litres of plain water soapy, keeping the ratio of what's left.
-- Puts everything back and returns false if the soapy water doesn't go in.
function SoapyWater.convert(fc, litres)
    local fluid = SoapyWater.fluid()
    if not fc:canAddFluid(fluid) then return false end
    local plainList = SoapyWater.plainFluids()
    local before = {}
    for i, f in ipairs(plainList) do before[i] = fc:getSpecificFluidAmount(f) end
    local soapyBefore = fc:getSpecificFluidAmount(fluid)
    local _, _, otherBefore = SoapyWater.amounts(fc)
    local shares = SoapyWater.removalShares(before, litres)
    for i, f in ipairs(plainList) do
        if shares[i] > 0 then fc:adjustSpecificFluidAmount(f, before[i] - shares[i]) end
    end
    fc:addFluid(fluid, litres)
    local _, soapy, other = SoapyWater.amounts(fc)
    if soapy >= soapyBefore + litres - EPS and other <= otherBefore + EPS then return true end
    if soapy > soapyBefore then fc:adjustSpecificFluidAmount(fluid, soapyBefore) end
    for i, f in ipairs(plainList) do
        if before[i] > 0 then
            if fc:contains(f) then
                fc:adjustSpecificFluidAmount(f, before[i])
            else
                fc:addFluid(f, before[i])
            end
        end
    end
    return false
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

function SoapyWater.soapTotal(inventory)
    local total = 0
    for _, n in ipairs(SoapyWater.soapUses(SoapyWater.soapBars(inventory))) do total = total + n end
    return total
end

-- Where a fluid container sits: nil when someone carries it, else its square
-- (world object, item on the floor, item in a crate, shelf or vehicle, also inside bags there).
function SoapyWater.fcSquare(fc)
    local owner = fc and fc:getOwner()
    if instanceof(owner, "IsoObject") then return owner:getSquare() end
    if not instanceof(owner, "InventoryItem") then return nil end
    local item = owner
    while item do
        if item:getWorldItem() then return item:getWorldItem():getSquare() end
        local container = item:getContainer()
        if not container then return nil end
        -- A bag's own container keeps the player as parent after it is dropped,
        -- so climb out of bags first and trust getParent only at the top.
        local bag = container:getContainingItem()
        if bag then
            item = bag
        else
            local parent = container:getParent()
            if instanceof(parent, "IsoGameCharacter") then return nil end
            if instanceof(parent, "IsoObject") then return parent:getSquare() end
            return container:getSourceGrid()
        end
    end
    return nil
end

-- Carried, or close enough by vanilla's walkAdj rule: within 1.6 tiles of the square's
-- centre on the same floor, with no wall in between.
function SoapyWater.inReach(character, square)
    if square == nil then return true end
    local here = character:getSquare()
    return here ~= nil and here:getZ() == square:getZ()
        and math.abs(square:getX() + 0.5 - character:getX()) <= 1.6
        and math.abs(square:getY() + 0.5 - character:getY()) <= 1.6
        and (here == square or here:canReachTo(square))
end

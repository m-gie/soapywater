require "SoapyWater/Items"

local S = SoapyWater

-- Fakes for the few game objects the helpers touch.
local WATER, TAINTED, CARB, JUICE, SOAPY = {n = "Water"}, {n = "TaintedWater"}, {n = "CarbonatedWater"}, {n = "Juice"}, {n = "SoapyWater"}
Fluid = {Water = WATER, TaintedWater = TAINTED, CarbonatedWater = CARB, Get = function(name) return name == "SoapyWater" and SOAPY or nil end}

local function container(parts, opts)
    opts = opts or {}
    local fc = {}
    function fc:getAmount() local t = 0 for _, v in pairs(parts) do t = t + v end return t end
    function fc:getSpecificFluidAmount(f) return parts[f] or 0 end
    function fc:isPureFluid(f) for k, v in pairs(parts) do if k ~= f and v > 0 then return false end end return (parts[f] or 0) > 0 end
    function fc:contains(f) return (parts[f] or 0) > 0 end
    function fc:adjustSpecificFluidAmount(f, v) if parts[f] then parts[f] = v end end
    function fc:addFluid(f, v) if opts.refuseSoapy and f == SOAPY then return end parts[f] = (parts[f] or 0) + v end
    function fc:canAddFluid(f) return not (opts.noAdd and f == SOAPY) end
    function fc:isInputLocked() return opts.locked == true end
    function fc:getWhitelist() return opts.whitelist end
    function fc:getBlacklist() return opts.blacklist end
    function fc:canPlayerEmpty() return opts.sealed ~= true end
    local item = {}
    function item:getFluidContainer() return fc end
    return item
end
local function fcOf(parts, opts) return container(parts, opts):getFluidContainer() end
local noFluid = {getFluidContainer = function() return nil end}

check(S.fluid() == SOAPY, "fluid() looks up SoapyWater")

local p, s, o, t = S.amounts(fcOf({[WATER] = 1, [TAINTED] = 0.5, [CARB] = 0.25, [SOAPY] = 2, [JUICE] = 0.1}))
check(p == 1.75 and s == 2 and math.abs(o - 0.1) < 1e-9 and math.abs(t - 3.85) < 1e-9, "amounts splits plain, soapy, other")
check(S.isSoapable(fcOf({[WATER] = 1})), "water is soapable")
check(S.isSoapable(fcOf({[TAINTED] = 0.4})), "tainted water is soapable")
check(S.isSoapable(fcOf({[CARB] = 0.3})), "carbonated water is soapable")
check(S.isSoapable(fcOf({[WATER] = 1, [SOAPY] = 1})), "half soapy is soapable")
check(not S.isSoapable(fcOf({[SOAPY] = 1})), "pure soapy is not soapable")
check(not S.isSoapable(fcOf({[WATER] = 0.9, [JUICE] = 0.1})), "water with juice is not soapable")
check(not S.isSoapable(fcOf({})), "empty container is not soapable")
check(not S.isSoapable(nil), "nil fc")

check(S.acceptsSoapyWater(fcOf({[WATER] = 1})), "plain container accepts")
check(not S.acceptsSoapyWater(nil), "nil fc refuses")
check(not S.acceptsSoapyWater(fcOf({[WATER] = 1}, {locked = true})), "input-locked container refuses")
check(not S.acceptsSoapyWater(fcOf({[WATER] = 1}, {whitelist = {allows = function(_, f) return f ~= SOAPY end}})), "whitelist without SoapyWater refuses")
check(S.acceptsSoapyWater(fcOf({[WATER] = 1}, {whitelist = {allows = function() return true end}})), "whitelist allowing it accepts")
check(not S.acceptsSoapyWater(fcOf({[WATER] = 1}, {sealed = true})), "sealed container refuses")
check(not S.acceptsSoapyWater(fcOf({[WATER] = 1}, {blacklist = {allows = function(_, f) return f ~= SOAPY end}})), "blacklist rejecting SoapyWater refuses")
check(S.acceptsSoapyWater(fcOf({[WATER] = 1}, {blacklist = {allows = function() return true end}})), "blacklist allowing it accepts")
local realGet = Fluid.Get
Fluid.Get = function() return nil end
check(not S.acceptsSoapyWater(fcOf({[WATER] = 1}, {whitelist = {allows = function(_, f) assert(f ~= nil) return true end}})), "missing fluid refuses without calling the filter")
Fluid.Get = realGet

check(S.isCleaner(container({[SOAPY] = 0.5})), "0.5 L pure soapy cleans")
check(S.isCleaner(container({[SOAPY] = 0.4995})), "0.4995 L counts as 0.5 L")
check(S.isCleaner(container({[SOAPY] = 0.5, [TAINTED] = 0.5})), "50:50 rain mix cleans")
check(not S.isCleaner(container({[SOAPY] = 0.4, [WATER] = 0.6})), "40% soapy does not clean")
check(not S.isCleaner(container({[SOAPY] = 0.49})), "0.49 L does not clean")
check(not S.isCleaner(container({[SOAPY] = 1, [JUICE] = 0.1})), "soapy with juice does not clean")
check(not S.isCleaner(noFluid), "no fc does not clean")
check(not S.isCleaner(nil), "nil item does not clean")

local fc = fcOf({[WATER] = 2, [TAINTED] = 1, [SOAPY] = 1})
check(S.convert(fc, 1.5), "convert succeeds")
check(math.abs(fc:getSpecificFluidAmount(WATER) - 1) < 1e-9 and math.abs(fc:getSpecificFluidAmount(TAINTED) - 0.5) < 1e-9, "convert keeps the water:tainted ratio")
check(math.abs(fc:getSpecificFluidAmount(SOAPY) - 2.5) < 1e-9, "convert adds the soapy water")
fc = fcOf({[WATER] = 2, [TAINTED] = 1}, {refuseSoapy = true})
check(not S.convert(fc, 1.5), "refused soapy water fails")
check(fc:getSpecificFluidAmount(WATER) == 2 and fc:getSpecificFluidAmount(TAINTED) == 1 and fc:getSpecificFluidAmount(SOAPY) == 0, "failed convert restores the water")

local bars = {{getCurrentUses = function() return 3 end}, {getCurrentUses = function() return 20 end}}
local list = {size = function() return #bars end, get = function(_, i) return bars[i + 1] end}
local inv = {getAllTypeEvalRecurse = function(_, t, pred) check(t == "Base.Soap2", "soapBars asks for Base.Soap2") return list end}
local got = S.soapBars(inv)
check(#got == 2 and got[1] == bars[1] and got[2] == bars[2], "soapBars converts the ArrayList in order")
local uses = S.soapUses(got)
check(uses[1] == 3 and uses[2] == 20, "soapUses reads current uses")

-- usableCleaner: the action's own container must still be held and still hold enough.
local soapy = container({[SOAPY] = 1.0})
local held = {containsRecursive = function(_, it) return it == soapy end}
local notHeld = {containsRecursive = function() return false end}
check(S.usableCleaner(held, soapy), "held container with enough soapy water")
check(not S.usableCleaner(notHeld, soapy), "dropped container is not usable")
check(not S.usableCleaner(held, container({[SOAPY] = 0.3})), "too little soapy water is not usable")
check(not S.usableCleaner(held, nil), "no container is not usable")
local mix = container({[SOAPY] = 0.5, [TAINTED] = 0.5})
local held2 = {containsRecursive = function(_, it) return it == mix end}
check(S.usableCleaner(held2, mix), "held 50:50 mix is usable")

local function sq(x, y, z, blocked)
    return {getX = function() return x end, getY = function() return y end, getZ = function() return z end,
        canReachTo = function(_, other) return not (blocked and blocked[other]) end}
end
local function standing(px, py, z, blocked)
    local here = sq(math.floor(px), math.floor(py), z, blocked)
    return {getSquare = function() return here end, getX = function() return px end, getY = function() return py end}
end
local me = standing(10.5, 10.5, 0)
check(S.inReach(me, nil), "carried container is in reach")
check(S.inReach(me, sq(11, 9, 0)), "diagonal neighbour in reach")
check(not S.inReach(me, sq(12, 10, 0)), "two tiles away is out of reach")
check(not S.inReach(me, sq(10, 10, 1)), "other floor is out of reach")
check(S.inReach(standing(12.05, 10.5, 0), sq(10, 10, 0)), "within vanilla's 1.6 walk distance is in reach")
local wall = sq(11, 10, 0)
check(not S.inReach(standing(10.5, 10.5, 0, {[wall] = true}), wall), "behind a wall is out of reach")
local bars2 = {{getCurrentUses = function() return 3 end}, {getCurrentUses = function() return 4 end}}
local list2 = {size = function() return #bars2 end, get = function(_, i) return bars2[i + 1] end}
check(S.soapTotal({getAllTypeEvalRecurse = function() return list2 end}) == 7, "soapTotal sums all bars")

check(not S.acceptsSoapyWater(fcOf({[WATER] = 1}, {noAdd = true})), "container whose fluids refuse soapy water refuses")
fc = fcOf({[WATER] = 2}, {noAdd = true})
check(not S.convert(fc, 1) and fc:getSpecificFluidAmount(WATER) == 2, "convert leaves the water alone when soapy water can't go in")

-- fcSquare: a bag lying in a crate still has the player as its stale parent.
instanceof = function(o, cls) return o ~= nil and type(o) == "table" and o._is ~= nil and o._is[cls] == true end
local crateSq = sq(5, 5, 0)
local crate = {_is = {IsoObject = true}, getSquare = function() return crateSq end}
local playerObj = {_is = {IsoObject = true, IsoGameCharacter = true}}
local crateInv = {getParent = function() return crate end, getContainingItem = function() return nil end}
local bag = {_is = {InventoryItem = true}, getWorldItem = function() return nil end, getContainer = function() return crateInv end}
local bagInv = {getParent = function() return playerObj end, getContainingItem = function() return bag end}
local bucket = {_is = {InventoryItem = true}, getWorldItem = function() return nil end, getContainer = function() return bagInv end}
check(S.fcSquare({getOwner = function() return bucket end}) == crateSq, "bucket in a bag in a crate sits at the crate")
local mainInv = {getParent = function() return playerObj end, getContainingItem = function() return nil end}
local held = {_is = {InventoryItem = true}, getWorldItem = function() return nil end, getContainer = function() return mainInv end}
check(S.fcSquare({getOwner = function() return held end}) == nil, "carried bucket has no square")

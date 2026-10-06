require "SoapyWater/Items"

local S = SoapyWater

-- Fakes for the few game objects the helpers touch.
local WATER, TAINTED, JUICE, SOAPY = {n = "Water"}, {n = "TaintedWater"}, {n = "Juice"}, {n = "SoapyWater"}
Fluid = {Water = WATER, TaintedWater = TAINTED, Get = function(name) return name == "SoapyWater" and SOAPY or nil end}

local function container(parts, opts)
    opts = opts or {}
    local fc = {}
    function fc:getAmount() local t = 0 for _, v in pairs(parts) do t = t + v end return t end
    function fc:getSpecificFluidAmount(f) return parts[f] or 0 end
    function fc:isPureFluid(f) for k, v in pairs(parts) do if k ~= f and v > 0 then return false end end return (parts[f] or 0) > 0 end
    function fc:isInputLocked() return opts.locked == true end
    function fc:getWhitelist() return opts.whitelist end
    function fc:getBlacklist() return opts.blacklist end
    function fc:canPlayerEmpty() return opts.sealed ~= true end
    local item = {}
    function item:getFluidContainer() return fc end
    return item
end
local noFluid = {getFluidContainer = function() return nil end}

check(S.fluid() == SOAPY, "fluid() looks up SoapyWater")

check(S.isWaterOnly(container({[WATER] = 1.0})), "clean water")
check(S.isWaterOnly(container({[TAINTED] = 0.4})), "tainted water")
check(S.isWaterOnly(container({[WATER] = 0.5, [TAINTED] = 0.5})), "clean and tainted mixed")
check(not S.isWaterOnly(container({[WATER] = 0.9, [JUICE] = 0.1})), "water with juice is not water only")
check(not S.isWaterOnly(container({})), "empty container")
check(not S.isWaterOnly(container({[SOAPY] = 1.0})), "already soapy")
check(not S.isWaterOnly(noFluid), "item without a fluid container")
check(not S.isWaterOnly(nil), "nil item")

check(S.acceptsSoapyWater(container({[WATER] = 1})), "plain container accepts")
check(not S.acceptsSoapyWater(container({[WATER] = 1}, {locked = true})), "input-locked container refuses")
check(not S.acceptsSoapyWater(container({[WATER] = 1}, {whitelist = {allows = function(_, f) return f ~= SOAPY end}})), "whitelist without SoapyWater refuses")
check(S.acceptsSoapyWater(container({[WATER] = 1}, {whitelist = {allows = function() return true end}})), "whitelist allowing it accepts")

check(not S.acceptsSoapyWater(container({[WATER] = 1}, {sealed = true})), "sealed container refuses")
check(not S.acceptsSoapyWater(container({[WATER] = 1}, {blacklist = {allows = function(_, f) return f ~= SOAPY end}})), "blacklist rejecting SoapyWater refuses")
check(S.acceptsSoapyWater(container({[WATER] = 1}, {blacklist = {allows = function() return true end}})), "blacklist allowing it accepts")
local realGet = Fluid.Get
Fluid.Get = function() return nil end
check(not S.acceptsSoapyWater(container({[WATER] = 1}, {whitelist = {allows = function(_, f) assert(f ~= nil) return true end}})), "missing fluid refuses without calling the filter")
Fluid.Get = realGet

check(S.soapyAmount(container({[SOAPY] = 0.75})) == 0.75, "soapy amount")
check(S.soapyAmount(container({[WATER] = 1})) == 0, "water is not soapy")
check(S.soapyAmount(noFluid) == 0, "no container, no soapy water")
check(S.hasSoapyWater(container({[SOAPY] = 0.5})), "exactly 0.5 L is enough")
check(S.hasSoapyWater(container({[SOAPY] = 0.4995})), "0.4995 L counts as 0.5 L")
check(not S.hasSoapyWater(container({[SOAPY] = 0.49})), "0.49 L is not enough")

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

require "SoapyWater/Logic"

local S = SoapyWater

check(S.LITRES_PER_TILE == 0.5, "0.5 L per tile")
check(S.usesNeeded(0) == 0, "empty needs no soap")
check(S.usesNeeded(0.0005) == 0, "below EPS needs no soap")
check(S.usesNeeded(0.2) == 1, "0.2 L needs 1 use")
check(S.usesNeeded(1.0) == 1, "1.0 L needs 1 use")
check(S.usesNeeded(1.0001) == 1, "1.0001 L counts as 1 L")
check(S.usesNeeded(1.0011) == 2, "1.0011 L needs 2 uses")
check(S.usesNeeded(1.5) == 2, "1.5 L needs 2 uses")
check(S.usesNeeded(20) == 20, "20 L needs 20 uses")

local function same(a, b)
    if a == nil or b == nil then return a == b end
    if #a ~= #b then return false end
    for i = 1, #a do if a[i] ~= b[i] then return false end end
    return true
end

check(same(S.planSoap({20}, 2), {2}), "one bar covers it")
check(same(S.planSoap({20, 3}, 2), {0, 2}), "emptiest bar first")
check(same(S.planSoap({20, 3}, 5), {2, 3}), "empties the small bar, rest from the big one")
check(same(S.planSoap({4, 4}, 6), {4, 2}), "ties go in inventory order")
check(S.planSoap({3, 2}, 6) == nil, "not enough soap gives nil")
check(S.planSoap({}, 1) == nil, "no bars gives nil")
check(same(S.planSoap({5}, 0), {0}), "nothing needed takes nothing")


check(S.MIN_SOAPY_SHARE == 0.5, "50% soapy share")
local function plan(p, u) local l, t = S.convertPlan(p, u) return l, t end
local l, t = plan(8, 20);   check(l == 8 and t == 8, "enough soap converts all 8 L for 8 uses")
l, t = plan(1.5, 2);        check(l == 1.5 and t == 2, "1.5 L full for 2 uses")
l, t = plan(8, 3);          check(l == 3 and t == 3, "3 uses convert 3 of 8 L")
l, t = plan(1.5, 1);        check(l == 1 and t == 1, "1 use converts 1 of 1.5 L")
l, t = plan(0.3, 5);        check(l == 0.3 and t == 1, "0.3 L takes 1 use, not 5")
l, t = plan(8, 0);          check(l == 0 and t == 0, "no soap converts nothing")
l, t = plan(0, 5);          check(l == 0 and t == 0, "no plain water converts nothing")

check(S.isSoapableMix(1, 0), "pure water is soapable")
check(S.isSoapableMix(0.5, 0.0005), "trace below EPS ignored")
check(not S.isSoapableMix(1, 0.0011), "foreign fluid blocks soaping")
check(not S.isSoapableMix(0.0005, 0), "no plain water is not soapable")

check(S.isCleanerMix(1, 0, 0), "pure soapy cleans")
check(S.isCleanerMix(0.5, 0.5, 0), "exactly 50% cleans")
check(S.isCleanerMix(0.25, 0.25, 0), "0.5 L total at 50% cleans")
check(not S.isCleanerMix(0.49, 0.51, 0), "49% does not clean")
check(not S.isCleanerMix(0.3, 0.1, 0), "under 0.5 L total does not clean")
check(not S.isCleanerMix(1, 0, 0.0011), "foreign fluid blocks cleaning")

local function near(a, b) return math.abs(a - b) < 1e-9 end
local r = S.removalShares({2, 1}, 1.5)
check(near(r[1], 1) and near(r[2], 0.5), "removal keeps the 2:1 ratio")
r = S.removalShares({2, 1}, 5)
check(near(r[1], 2) and near(r[2], 1), "removal capped at what is there")
r = S.removalShares({0, 0}, 1)
check(r[1] == 0 and r[2] == 0, "nothing to remove from empty parts")

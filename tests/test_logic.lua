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


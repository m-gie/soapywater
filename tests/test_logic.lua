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

-- mirrorLoot: copy CookingMag1/Book_Fiction entries to our items at the same weight.
local MAP = {CookingMag1 = "CookingMagSoap", Book_Fiction = "Book_FightClub"}
local function has(items, name, weight)
    for i = 1, #items - 1, 2 do if items[i] == name and items[i + 1] == weight then return true end end
    return false
end
local shop = {items = {"Pen", 1, "CookingMag1", 2, "Book_Fiction", 4}}
local shared = {items = {"Base.CookingMag1", 0.1}}
local procedural = {list = {BookstoreCooking = shop, AliasA = shared, AliasB = shared}}
local rooms = {kitchen = {counter = {rolls = 1, items = {"Book_Fiction", 0.5}, junk = {items = {"CookingMag1", 0.2}}}}}
local plain = {items = {"Pen", 1}}
local n = S.mirrorLoot({procedural, rooms, plain}, MAP)
check(has(shop.items, "CookingMagSoap", 2), "magazine mirrored at weight 2")
check(has(shop.items, "Book_FightClub", 4), "book mirrored at weight 4")
check(has(shared.items, "CookingMagSoap", 0.1), "Base.-prefixed name mirrored")
check(#shared.items == 4, "shared alias table mirrored once")
check(has(rooms.kitchen.counter.items, "Book_FightClub", 0.5), "nested container mirrored")
check(has(rooms.kitchen.counter.junk.items, "CookingMagSoap", 0.2), "junk list mirrored")
check(#plain.items == 2, "lists without the source items are untouched")
check(n == 5, "returns entries added: " .. tostring(n))
local again = {items = {"CookingMag1", 1, "CookingMagSoap", 3}}
check(S.mirrorLoot({again}, MAP) == 0 and #again.items == 4, "already listed target is not added twice")

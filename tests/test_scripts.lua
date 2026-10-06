-- Static checks on the script and translation files.
local function read(rel)
    local f = assert(io.open(ROOT .. "/" .. rel, "r"))
    local s = f:read("*a")
    f:close()
    return s
end
local recipes = read("42/media/scripts/SoapyWater_recipes.txt")
local items = read("42/media/scripts/SoapyWater_items.txt")
check(recipes:find("craftRecipe MixSoap") ~= nil, "MixSoap recipe exists")
check(recipes:find("MakeSoap") == nil, "old MakeSoap recipe is gone")
check(recipes:find("NeedToBeLearn = true") ~= nil, "MixSoap must be learned")
check(recipes:find("openFire") == nil and recipes:find("AnySurfaceCraft") == nil, "no fire test, no surface")
local _, teaches = items:gsub("LearnedRecipes = MixSoap,", "")
check(teaches == 2, "book and magazine both teach MixSoap")
check(items:find("ReplaceOnCooked = Base.Soap2") ~= nil and items:find("MinutesToCook = 60") ~= nil, "raw soap cooks into soap in 60 min")
check(items:find("CantEat = true") ~= nil, "raw soap can't be eaten")
for _, lang in ipairs({"EN", "PL"}) do
    local names = read("42/media/lua/shared/Translate/" .. lang .. "/ItemName.json")
    for _, key in ipairs({"Base.SoapRaw", "Base.Book_FightClub", "Base.CookingMagSoap"}) do
        check(names:find('"' .. key .. '"', 1, true) ~= nil, lang .. " name for " .. key)
    end
    check(read("42/media/lua/shared/Translate/" .. lang .. "/Recipes.json"):find('"MixSoap"', 1, true) ~= nil, lang .. " recipe name")
end

-- Render Lard: Trim Fat (known by default) -> Raw Fat, cooked into Lard.
local trim = recipes:match("craftRecipe TrimFat%s*(%b{})")
check(trim ~= nil, "TrimFat recipe exists")
if trim then
    check(trim:find("NeedToBeLearn") == nil, "TrimFat is known by default")
    for _, cut in ipairs({"Base.Pork", "Base.PorkChop", "Base.Beef", "Base.Steak", "Base.Venison", "Base.MuttonChop"}) do
        check(trim:find(cut .. "[;%]]") ~= nil, "TrimFat accepts " .. cut)
    end
    check(trim:find("flags%[IsUncookedFoodItem;ItemCount%]") ~= nil, "raw meat only, counted by item")
    check(trim:find("item 2 %[") ~= nil, "2 pieces of meat")
    check(trim:find("tags%[base:sharpknife;base:meatcleaver%] mode:keep") ~= nil, "kept knife")
    check(trim:find("item 1 Base.FatRaw") ~= nil, "gives 1 Raw Fat")
end
local fat = items:match("item FatRaw%s*(%b{})")
check(fat ~= nil, "FatRaw item exists")
if fat then
    check(fat:find("ReplaceOnCooked = Base.Lard") ~= nil and fat:find("MinutesToCook = 60") ~= nil, "raw fat cooks into Lard in 60 min")
    check(fat:find("CantEat = true") ~= nil, "raw fat can't be eaten")
end
for _, lang in ipairs({"EN", "PL"}) do
    check(read("42/media/lua/shared/Translate/" .. lang .. "/ItemName.json"):find('"Base.FatRaw"', 1, true) ~= nil, lang .. " name for Base.FatRaw")
    check(read("42/media/lua/shared/Translate/" .. lang .. "/Recipes.json"):find('"TrimFat"', 1, true) ~= nil, lang .. " name for TrimFat")
    check(read("42/media/lua/shared/Translate/" .. lang .. "/Tooltip.json"):find('"Tooltip_SoapyWater_RawFat"', 1, true) ~= nil, lang .. " raw fat tooltip")
end

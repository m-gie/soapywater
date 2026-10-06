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

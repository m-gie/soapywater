require "SoapyWater/Logic"

-- Same places and weights as the vanilla items they stand beside.
local function mirror()
    local roots = {}
    if ProceduralDistributions then roots[#roots + 1] = ProceduralDistributions end
    if Distributions then roots[#roots + 1] = Distributions end
    if VehicleDistributions then roots[#roots + 1] = VehicleDistributions end
    local n = SoapyWater.mirrorLoot(roots, {CookingMag1 = "CookingMagSoap", Book_Fiction = "Book_FightClub"})
    print("[SoapyWater] loot entries added: " .. tostring(n))
end

Events.OnPreDistributionMerge.Add(mirror)

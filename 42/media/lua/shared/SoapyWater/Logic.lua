-- Pure rules, no game objects, so they can be tested offline.
SoapyWater = SoapyWater or {}

SoapyWater.LITRES_PER_TILE = 0.5
SoapyWater.EPS = 0.001

-- Soap uses needed to turn this much water into soapy water: one per started litre.
function SoapyWater.usesNeeded(litres)
    if litres <= SoapyWater.EPS then return 0 end
    return math.ceil(litres - SoapyWater.EPS)
end

-- How many uses to take from each bar (same order as uses), emptiest bar first.
-- Returns nil when all bars together hold fewer than needed.
function SoapyWater.planSoap(uses, needed)
    local order, take = {}, {}
    for i = 1, #uses do
        order[i] = i
        take[i] = 0
    end
    table.sort(order, function(a, b)
        if uses[a] ~= uses[b] then return uses[a] < uses[b] end
        return a < b
    end)
    local left = needed
    for _, i in ipairs(order) do
        if left <= 0 then break end
        local n = math.min(uses[i], left)
        take[i] = n
        left = left - n
    end
    if left > 0 then return nil end
    return take
end


SoapyWater.MIN_SOAPY_SHARE = 0.5

-- How much plain water to turn soapy and how many uses that takes.
-- Short on soap: each use converts 1 L.
function SoapyWater.convertPlan(plain, uses)
    if plain <= SoapyWater.EPS or uses <= 0 then return 0, 0 end
    local needed = SoapyWater.usesNeeded(plain)
    if uses >= needed then return plain, needed end
    return math.min(uses, plain), uses
end

-- Some plain water and nothing but water and soapy water.
function SoapyWater.isSoapableMix(plain, other)
    return plain > SoapyWater.EPS and other <= SoapyWater.EPS
end

-- Enough for one tile, at least half soapy, nothing but water and soapy water.
function SoapyWater.isCleanerMix(soapy, plain, other)
    local total = soapy + plain
    return other <= SoapyWater.EPS
        and total >= SoapyWater.LITRES_PER_TILE - SoapyWater.EPS
        and soapy >= total * SoapyWater.MIN_SOAPY_SHARE - SoapyWater.EPS
end

-- How much to take from each part so the parts keep their ratio; never more than is there.
function SoapyWater.removalShares(parts, litres)
    local total = 0
    for _, v in ipairs(parts) do total = total + v end
    local shares = {}
    for i, v in ipairs(parts) do
        shares[i] = total > SoapyWater.EPS and v * math.min(litres, total) / total or 0
    end
    return shares
end

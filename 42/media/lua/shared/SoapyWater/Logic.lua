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

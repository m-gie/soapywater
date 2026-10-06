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

-- Loot: for every items list under roots that has a source item of map (bare or
-- "Base." name) with weight w, add map[source] with weight w. Vanilla aliases share
-- tables, so each table is visited once; a target already in a list is not added again.
function SoapyWater.mirrorLoot(roots, map)
    local seen, added = {}, 0
    local function walk(t)
        if type(t) ~= "table" or seen[t] then return end
        seen[t] = true
        local items = t.items
        if type(items) == "table" then
            local present, extra = {}, {}
            for i = 1, #items - 1, 2 do
                if type(items[i]) == "string" then present[(items[i]:gsub("^Base%.", ""))] = true end
            end
            for i = 1, #items - 1, 2 do
                local name = type(items[i]) == "string" and (items[i]:gsub("^Base%.", ""))
                local target = name and map[name]
                if target and not present[target] then
                    extra[#extra + 1] = target
                    extra[#extra + 1] = items[i + 1]
                    present[target] = true
                end
            end
            for _, v in ipairs(extra) do items[#items + 1] = v end
            added = added + #extra / 2
        end
        for _, v in pairs(t) do walk(v) end
    end
    for _, root in ipairs(roots) do walk(root) end
    return added
end

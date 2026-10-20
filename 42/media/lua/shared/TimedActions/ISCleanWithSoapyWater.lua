require "TimedActions/ISCleanBlood"
require "SoapyWater/Items"

-- Vanilla stain cleaning (same animation, sound and duration), paid with soapy water.
ISCleanWithSoapyWater = ISCleanBlood:derive("ISCleanWithSoapyWater")

local function predicateNotBroken(item)
    return not item:isBroken()
end

-- Checks the container this action was given, so a queued clean stops at once
-- when that container runs dry instead of playing out and cleaning nothing.
function ISCleanWithSoapyWater:isValid()
    local inv = self.character:getInventory()
    return SoapyWater.usableCleaner(inv, self.cleaner) and inv:containsTagEval(ItemTag.CLEAN_STAINS, predicateNotBroken)
end

-- Runs on the server in multiplayer.
function ISCleanWithSoapyWater:complete()
    local cleaner = self.cleaner
    if not cleaner or not SoapyWater.isCleaner(cleaner) then return false end
    local fc = cleaner:getFluidContainer()
    local left = fc:getAmount() - SoapyWater.LITRES_PER_TILE
    if left <= SoapyWater.EPS then
        fc:Empty()
    else
        fc:adjustAmount(left)
    end
    cleaner:syncItemFields()
    self.square:removeBlood(false, false)
    self.square:removeGrime()
    return true
end

function ISCleanWithSoapyWater:new(character, square, cleaner)
    return ISCleanBlood.new(self, character, square, cleaner)
end

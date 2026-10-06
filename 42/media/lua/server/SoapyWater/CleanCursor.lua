-- Lives in server/ like vanilla's cursors: ISCleanBloodCursor is only defined once
-- media/lua/server loads, after the client files.
require "BuildingObjects/ISCleanBloodCursor"

-- Vanilla's square picker with our checks (SoapyWater.canClean/doClean are in client Menus.lua).
SoapyWaterCleanCursor = ISCleanBloodCursor:derive("SoapyWaterCleanCursor")

function SoapyWaterCleanCursor:create(x, y, z, north, sprite)
    SoapyWater.doClean(self.character, getWorld():getCell():getGridSquare(x, y, z))
end

function SoapyWaterCleanCursor:isValid(square)
    return SoapyWater.canClean(self.character, square)
end

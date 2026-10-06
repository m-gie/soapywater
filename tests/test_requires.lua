-- Client files load before media/lua/server, so they must not require server modules
-- such as vanilla's cursors in BuildingObjects/ (the require fails and the class is nil).
local client = {"SoapyWater/Menus.lua"}
for _, name in ipairs(client) do
    local f = assert(io.open(ROOT .. "/42/media/lua/client/" .. name, "r"))
    local src = f:read("*a")
    f:close()
    check(not src:find('require%s*%(?%s*"BuildingObjects/'), name .. " does not require server BuildingObjects modules")
end

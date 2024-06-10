
local luafiles = file.Find( "mw2callcards/*", "LUA", "namedesc" )
MW2CC = MW2CC or {}
for k, lua in ipairs( luafiles ) do
    
    if string.StartWith( lua, "sv_" ) and SERVER then
        include( "mw2callcards/" .. lua )
        print( "MW2CC: Loaded Lua file " .. lua )
    elseif string.StartWith( lua, "cl_" ) then
        if SERVER then AddCSLuaFile( "mw2callcards/" .. lua ) end
        if CLIENT then include( "mw2callcards/" .. lua ) print( "MW2CC: Loaded Lua file " .. lua ) end
    elseif string.StartWith( "sh_" ) then
        if SERVER then AddCSLuaFile( "mw2callcards/" .. lua ) end
        include( "mw2callcards/" .. lua ) 
        print( "MW2CC: Loaded Lua file " .. lua )
    end
end
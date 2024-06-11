MW2CC.ConVars = {}

function MW2CC:ConVar( optionname, name, value, clientside, type, helptext, min, max )
    local cvar
    if clientside and CLIENT then
        cvar = CreateConVar( name, value, FCVAR_ARCHIVE, helptext, min, max )
    else
        cvar = CreateConVar( name, value, FCVAR_ARCHIVE, helptext, min, max )
    end

    MW2CC.ConVars[ #MW2CC.ConVars + 1 ] = { optionname = optionname, type = type, name = name, value = value, desc = helptext, cvar = cvar, clientside = clientside, min = min, max = max }
end


MW2CC:ConVar( "Allow Announcement Cards", "mw2cc_allowannouncecards", 1, true, "bool", "If announcement cards are allowed to be displayed. I.e killstreak announcements, ect", 0, 1 )
MW2CC:ConVar( "Allow Kill Cards", "mw2cc_allowkillcards", 1, true, "bool", "If kill cards are allowed to be displayed", 0, 1 )
MW2CC:ConVar( "Killstreak Threshold", "mw2cc_killstreakthreshold", 5, false, "slider", "The amount of kills needed without dying before a killstreak announcement is made", 1, 50 )
    
concommand.Add( "mw2cc_previewannouncement", function( ply )
    MW2CC:DispatchCallCard( ply, "PREVIEW TEST", false, ply )
end )

concommand.Add( "mw2cc_previewkill", function( ply )
    MW2CC:DispatchCallCard( ply, "KILL TEST", true, ply )
end )

if CLIENT then

    local clientcolor = Color( 255, 145, 0 )
    local servercolor = Color( 0, 174, 255 )

    hook.Add( "AddToolMenuCategories", "mw2cc_spawnmenu_options", function()
        spawnmenu.AddToolCategory( "Utilities", "MW2CC Options", "#MW2CC Options" )
    end )

    hook.Add( "PopulateToolMenu", "mw2cc_spawnmenu_options", function()
        spawnmenu.AddToolMenuOption( "Utilities", "MW2CC Options", "mw2cc_options", "Options", "", "", function( pnl )

            pnl:Help( "Modern Warfare 2009 Call Cards Remastered" )

            for k, v in ipairs( MW2CC.ConVars ) do
                local clr = v.clientside and clientcolor or servercolor
                local prefix = v.clientside and "Client-Side | " or "Server-Side | "
                if v.type == "bool" then
                    pnl:CheckBox( v.optionname, v.name )
                    local lbl = pnl:ControlHelp( prefix .. v.desc )
                    lbl:SetColor( clr )
                elseif v.type == "slider" then
                    print(v.optionname, v.name, v.min, v.max)
                    pnl:NumSlider( v.optionname, v.name, v.min, v.max, 0 )
                    local lbl = pnl:ControlHelp( prefix .. v.desc )
                    lbl:SetColor( clr )
                end
            end

            pnl:Button( "Preview Announcement Card", "mw2cc_previewannouncement" )
            pnl:Button( "Preview Kill Card", "mw2cc_previewkill" )
            
        end )
    end )
end
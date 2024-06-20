MW2CC.ConVars = {}

-- Convenience system for handling convars and spawnmenu settings
function MW2CC:ConVar( optionname, name, value, clientside, type, helptext, min, max, decimals )
    local cvar
    if clientside then
        if SERVER then return end
        cvar = CreateConVar( name, value, FCVAR_ARCHIVE, helptext, min, max )
    else
        cvar = CreateConVar( name, value, FCVAR_ARCHIVE+FCVAR_REPLICATED, helptext, min, max )
    end

    MW2CC.ConVars[ #MW2CC.ConVars + 1 ] = { optionname = optionname, decimals = decimals, type = type, name = name, value = value, desc = helptext, cvar = cvar, clientside = clientside, min = min, max = max }
end


MW2CC:ConVar( "Allow Announcement Cards", "mw2cc_allowannouncecards", 1, true, "bool", "If announcement cards are allowed to be displayed. I.e killstreak announcements, ect", 0, 1 )
MW2CC:ConVar( "Allow Kill Cards", "mw2cc_allowkillcards", 1, true, "bool", "If kill cards are allowed to be displayed", 0, 1 )
MW2CC:ConVar( "Allow NPCs", "mw2cc_allownpcs", 1, false, "bool", "If multikills/killstreaks are allowed to show for base game NPCs. I.e Combine soldiers", 0, 1 )
MW2CC:ConVar( "Allow Nextbots", "mw2cc_allownextbots", 1, false, "bool", "If multikills/killstreaks are allowed to show for nextbots", 0, 1 )
MW2CC:ConVar( "Allow Other Ents", "mw2cc_allowotherents", 1, false, "bool", "If multikills/killstreaks are allowed to show for entities such as props", 0, 1 )
MW2CC:ConVar( "Swap Emblem and Avatar", "mw2cc_flipemblem", 0, true, "bool", "If emblem and avatar should switch positions. Resembles MW2 more", 0, 1 )
MW2CC:ConVar( "Enable Smoothing", "mw2cc_smoothing", 0, true, "bool", "If images such as banners and emblems should be smoothed", 0, 1 )

MW2CC:ConVar( "Killstreak Threshold", "mw2cc_killstreakthreshold", 5, false, "slider", "The amount of kills needed without dying before a killstreak announcement is made", 1, 50, 0 )

MW2CC:ConVar( "Card Scale", "mw2cc_scale", 1, true, "slider", "The scale to multiply the size of the announce cards by", 0.5, 3, 3 )
MW2CC:ConVar( "Announce Card Y", "mw2cc_announcey", 0.125, true, "slider", "The vertical position of the announce cards as a percentage of your screen size", 0, 1, 3 )
MW2CC:ConVar( "Announce Card X", "mw2cc_announcex", 0.975, true, "slider", "The horizontal position of the announce cards as a percentage of your screen size", 0, 1, 3 )
MW2CC:ConVar( "Kill Card Y", "mw2cc_killy", 0.925, true, "slider", "The vertical position of the killcards as a percentage of your screen size", 0, 1, 3 )
MW2CC:ConVar( "Kill Card X", "mw2cc_killx", 0.5, true, "slider", "The horizontal position of the killcards as a percentage of your screen size", 0, 1, 3 )

concommand.Add( "mw2cc_previewannouncement", function( ply )
    MW2CC:DispatchCallCard( ply, "PREVIEW TEST", false, ply )
end )

concommand.Add( "mw2cc_reloadassets", function( ply )
    if !ply:IsSuperAdmin() then return end
    MW2CC.assets = MW2CC:GetAssets()
    PrintMessage( HUD_PRINTTALK, "MW2CC: Assets reloaded")
end )

concommand.Add( "mw2cc_previewkill", function( ply )
    MW2CC:DispatchCallCard( ply, "KILL TEST", true, ply )
end )

if CLIENT then
    concommand.Add( "mw2cc_clearqueue", function()
        MW2CC.QueuedCards = {}
        MW2CC.QueuedKillCards = {}
    end )
end

if CLIENT then

    local clientcolor = Color( 192, 109, 0)
    local servercolor = Color( 0, 131, 192)

    hook.Add( "AddToolMenuCategories", "mw2cc_spawnmenu_options", function()
        spawnmenu.AddToolCategory( "Utilities", "MW2CC Options", "#MW2CC Options" )
    end )

    hook.Add( "PopulateToolMenu", "mw2cc_spawnmenu_options", function()
        spawnmenu.AddToolMenuOption( "Utilities", "MW2CC Options", "mw2cc_options", "Options", "", "", function( pnl )

            pnl:SetName( "Modern Warfare 2 2009 Call Cards Remastered" )

            local clvar, svvar = vgui.Create("DForm"), vgui.Create("DForm")
            clvar:SetName("Client")
            svvar:SetName("Server")
            pnl:AddItem(clvar)
            pnl:AddItem(svvar)
            -- I only needed sliders and bools
            for k, v in ipairs( MW2CC.ConVars ) do
                local cat = v.clientside and clvar or svvar
                local clr = v.clientside and clientcolor or servercolor
                local def = v.cvar:GetDefault()
                -- local prefix = v.clientside and "Client-Side | " or "Server-Side | "
                if v.type == "bool" then
                    cat:CheckBox( v.optionname, v.name )
                    def = v.cvar:GetDefault() == "1" and "True" or "False"
                elseif v.type == "slider" then
                    cat:NumSlider( v.optionname, v.name, v.min, v.max, v.decimals )
                end
                local lbl = cat:Help( v.desc .. "\n\nDefault: " .. def )
                lbl:SetColor( clr )
            end

            svvar:Button( "Preview Announcement Card", "mw2cc_previewannouncement" )
            svvar:Button( "Preview Kill Card", "mw2cc_previewkill" )
            clvar:Button( "Change Banner", "mw2cc_openbannerpanel" )
            clvar:Button( "Change Emblem", "mw2cc_openemblempanel" )
            clvar:Button( "Clear Card Queue", "mw2cc_clearqueue" )
            svvar:Button( "Reload Assets", "mw2cc_reloadassets" )
            svvar:Help( "For performance reasons, you must reload assets in order for new custom banners/emblems to be randomly applied onto entities.\n" ) -- \n is for nice spacing at the bottom
            
            
        end )
    end )
end
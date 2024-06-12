function MW2CC:GetRandomBanner()
    local files = file.Find( "materials/mw2cc/titles/*", "GAME" )
    return "mw2cc/titles/" .. files[ math.random( #files ) ]
end

function MW2CC:GetRandomEmblem()
    local files = file.Find( "materials/mw2cc/emblems/*", "GAME" )
    return "mw2cc/emblems/" .. files[ math.random( #files ) ]
end

if !file.Exists( "mw2cc_data/data.json", "DATA" ) then
    file.Write( "mw2cc_data/data.json", util.TableToJSON( {banner = MW2CC:GetRandomBanner(), emblem = MW2CC:GetRandomEmblem()} ) )
end

function MW2CC:OpenCosmeticPanel( ply, type, name )
    local main = vgui.Create( "DFrame", GetHUDPanel() )
    local w, h = type == "emblem" and 600 or 700, 400
    main:SetSize( w, h )
    main:Center()
    main:SetTitle( "MW2CC " .. type .. " editor" )
    main:MakePopup()

    local filestr = file.Read( "mw2cc_data/data.json", "DATA" )
    local tbl = util.JSONToTable( filestr )

    local current_cosmetic = tbl[ type ]
    local cosmetic_path = type == "banner" and "materials/mw2cc/titles" or "materials/mw2cc/emblems"

    local listview = vgui.Create( "DListView", main )
    listview:SetSize( w / 2, 1  )
    listview:Dock( LEFT )
    listview:AddColumn( "Banner Name", 1 )
    listview:AddColumn( "Time Added", 2 )

    local files = file.Find( cosmetic_path .. "/*", "GAME", "namedesc" )
    for k, v in ipairs( files ) do
        local line = listview:AddLine( v, os.date( "%x %X", file.Time( cosmetic_path .. "/" .. v, "GAME" ) ) )
        line:SetSortValue( 1, cosmetic_path .. "/" .. v )
    end

    local rightpnl = vgui.Create( "DPanel", main )
    rightpnl:SetSize( w / 2, h / 2 )
    rightpnl:Dock( LEFT )

    local smallpnl = vgui.Create( "DPanel", rightpnl )
    smallpnl:SetSize( 64, 64 )
    smallpnl:Dock( TOP )

    local image = vgui.Create( "DImage", rightpnl )
    image:SetSize( w / 2, type == "banner" and 100 or h / 2 )
    image:Dock( TOP )

    local curtext = vgui.Create( "DLabel", smallpnl )
    curtext:SetText( "Current " .. type .. ": " .. current_cosmetic )
    curtext:SetSize( h / 2, 1 )
    curtext:Dock( LEFT )

    local curimage = vgui.Create( "DImage", smallpnl )
    curimage:SetSize( type == "emblem" and 64 or 140, type == "emblem" and 64 or 140 )
    curimage:Dock( LEFT )
    curimage:SetMaterial( MW2CC:GetMaterial( current_cosmetic ) )
    
    local setnew = vgui.Create( "DButton", rightpnl )
    setnew:SetText( "Save new " .. type )
    setnew:SetSize( 10, 25 )
    setnew:Dock( TOP )

    function setnew:DoClick()
        local filestr = file.Read( "mw2cc_data/data.json", "DATA" )
        local tbl = util.JSONToTable( filestr )
        tbl[ type ] = current_cosmetic
        curtext:SetText( "Current " .. type .. ": " .. current_cosmetic )
        file.Write( "mw2cc_data/data.json", util.TableToJSON( tbl ) )

        surface.PlaySound( "buttons/button14.wav" )

        net.Start( "mw2cc_net_clientsendcosmetics" )
        net.WriteString( type == "banner" and current_cosmetic or "" )
        net.WriteString( type == "emblem" and current_cosmetic or "" )
        net.SendToServer()
        
        curimage:SetMaterial( MW2CC:GetMaterial( current_cosmetic ) )
    end

    function listview:DoDoubleClick( id, line )
        image:SetMaterial( MW2CC:GetMaterial( string.Replace( line:GetSortValue( 1 ), "materials/", "" ) ) )
        current_cosmetic = string.Replace( line:GetSortValue( 1 ), "materials/", "" )
        surface.PlaySound( "buttons/blip1.wav" )
    end
    

end

concommand.Add( "mw2cc_openbannerpanel", function( ply )
    MW2CC:OpenCosmeticPanel( ply, "banner", name )
end )

concommand.Add( "mw2cc_openemblempanel", function( ply )
    MW2CC:OpenCosmeticPanel( ply, "emblem", name )
end )

hook.Add( "InitPostEntity", "mw2cc_sendcosmetics", function()
    local filestr = file.Read( "mw2cc_data/data.json", "DATA" )
    local tbl = util.JSONToTable( filestr )

    net.Start( "mw2cc_net_clientsendcosmetics" )
    net.WriteString( tbl.banner )
    net.WriteString( tbl.emblem )
    net.SendToServer()
end )
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

function MW2CC:OpenCosmeticPanel( ply, type )
    local main = vgui.Create( "DFrame", GetHUDPanel() )
    local w, h = 700, 400
    main:SetSize( w, h )
    main:Center()
    main:SetTitle( "MW2CC " .. type .. " editor" )
    main:MakePopup()

    local filestr = file.Read( "mw2cc_data/data.json", "DATA" )
    local tbl = util.JSONToTable( filestr )

    local current_cosmetic = tbl[ type ]
    local cosmetic_path = type == "banner" and "materials/mw2cc/titles" or "materials/mw2cc/emblems"

    local tabs = vgui.Create( "DPropertySheet", main )
    tabs:SetSize( w / 2, 1  )
    tabs:Dock( LEFT )

    local default_listview = vgui.Create( "DListView", main )
    default_listview:Dock( FILL )
    default_listview:AddColumn( "Banner Name", 1 )
    default_listview:AddColumn( "Time Added", 2 )

    local custompnl = vgui.Create( "DPanel", main )

    local custom_listview = vgui.Create( "DListView", custompnl )
    custom_listview:Dock( FILL )
    custom_listview:AddColumn( "Banner Name", 1 )
    custom_listview:AddColumn( "Time Added", 2 )

    local customlbl = vgui.Create( "DLabel", custompnl )
    customlbl:SetText( "Place custom " .. type .. " .pngs, .jpgs, and .vtfs\nin the following directoy:\n\nDRIVE:/Program Files (x86)/steam/steamapps/common/GarrysMod/\nsourceengine/materials/mw2cc/custom/" .. type .. "s/imageshere" )
    customlbl:SetSize( 1, 70 )
    customlbl:Dock( TOP )



    tabs:AddSheet( "Default " .. type .. "s", default_listview, "materials/icon16/folder.png" )
    tabs:AddSheet( "Custom " .. type .. "s", custompnl, "materials/icon16/folder_add.png" )

    local files = file.Find( cosmetic_path .. "/*", "GAME", "namedesc" )
    for k, v in ipairs( files ) do
        local line = default_listview:AddLine( v, os.date( "%x %X", file.Time( cosmetic_path .. "/" .. v, "GAME" ) ) )
        line:SetSortValue( 1, cosmetic_path .. "/" .. v )
    end

    local files = file.Find( "materials/mw2cc/custom/" .. type .. "s/*", "GAME", "namedesc" )
    for k, v in ipairs( files ) do
        local line = custom_listview:AddLine( v, os.date( "%x %X", file.Time( "materials/mw2cc/custom/" .. type .. "s/" .. v, "GAME" ) ) )
        line:SetSortValue( 1, "materials/mw2cc/custom/" .. type .. "s/" .. v )
    end

    local rightpnl = vgui.Create( "DPanel", main )
    rightpnl:SetSize( w / 2, h / 2 )
    rightpnl:Dock( LEFT )

    local curtext = vgui.Create( "DLabel", rightpnl )
    curtext:SetText( "Current " .. type .. ": " .. current_cosmetic )
    curtext:SetSize( h / 2, 30 )
    curtext:Dock( TOP )


    local smallpnl = vgui.Create( "DPanel", rightpnl )
    smallpnl:SetSize( 64, 64 )
    smallpnl:Dock( TOP )

    local image = vgui.Create( "DImage", rightpnl )
    image:SetSize( w / 2, type == "banner" and 100 or h / 2 )
    image:DockMargin( 0, 30, 0, 0 )
    image:Dock( TOP )

    local curimage = vgui.Create( "DImage", smallpnl )
    curimage:SetSize( 1, 1 )
    curimage:DockMargin( type == "emblem" and smallpnl:GetWide() * 2 or 0, 0, type == "emblem" and smallpnl:GetWide() * 2 or 0, 0 )
    curimage:Dock( FILL )
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

    local function OnRowSelected( self, id, line )
        image:SetMaterial( MW2CC:GetMaterial( string.Replace( line:GetSortValue( 1 ), "materials/", "" ) ) )
        current_cosmetic = string.Replace( line:GetSortValue( 1 ), "materials/", "" )
        surface.PlaySound( "buttons/blip1.wav" )
    end

    default_listview.OnRowSelected = OnRowSelected
    custom_listview.OnRowSelected = OnRowSelected
    

end

concommand.Add( "mw2cc_openbannerpanel", function( ply )
    MW2CC:OpenCosmeticPanel( ply, "banner" )
end )

concommand.Add( "mw2cc_openemblempanel", function( ply )
    MW2CC:OpenCosmeticPanel( ply, "emblem" )
end )

hook.Add( "InitPostEntity", "mw2cc_sendcosmetics", function()
    if !file.Exists( "mw2cc_data/data.json", "DATA" ) then
        file.Write( "mw2cc_data/data.json", util.TableToJSON( {banner = MW2CC:GetRandomBanner(), emblem = MW2CC:GetRandomEmblem()} ) )
    end
    
    local filestr = file.Read( "mw2cc_data/data.json", "DATA" )
    local tbl = util.JSONToTable( filestr )

    net.Start( "mw2cc_net_clientsendcosmetics" )
    net.WriteString( tbl.banner )
    net.WriteString( tbl.emblem )
    net.SendToServer()
end )
local function OpenCosmeticSelectionPanel( ply, type, pnltoedit )
    local main = vgui.Create( "DFrame", GetHUDPanel() )
    local w, h = 700, 400
    main:SetSize( w, h )
    main:Center()
    main:SetTitle( "MW2CC " .. type .. " selector" )
    main:MakePopup()

    local current_cosmetic = type == "emblem" and "mw2cc/emblems/AC-130_Angel_Flares_Emblem_MW2.png" or "mw2cc/banners/1st_Lt._title_MW2.png"
    local cosmetic_path = type == "banner" and "materials/mw2cc/banners" or "materials/mw2cc/emblems"

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

    local smallpnl = vgui.Create( "DPanel", rightpnl )
    smallpnl:SetSize( 64, 64 )
    smallpnl:Dock( TOP )

    local image = vgui.Create( "DImage", rightpnl )
    image:SetSize( w / 2, type == "banner" and 100 or h / 2 )
    image:DockMargin( 0, 30, 0, 0 )
    image:Dock( TOP )

    local setnew = vgui.Create( "DButton", rightpnl )
    setnew:SetText( "Select " .. type )
    setnew:SetSize( 10, 25 )
    setnew:Dock( TOP )
    

    function setnew:DoClick()
        pnltoedit:SetText( current_cosmetic )
        surface.PlaySound( "buttons/button14.wav" )
        main:Close()
    end

    local function OnRowSelected( self, id, line )
        image:SetMaterial( MW2CC:GetMaterial( string.Replace( line:GetSortValue( 1 ), "materials/", "" ) ) )
        current_cosmetic = string.Replace( line:GetSortValue( 1 ), "materials/", "" )
        surface.PlaySound( "buttons/blip1.wav" )
    end

    default_listview.OnRowSelected = OnRowSelected
    custom_listview.OnRowSelected = OnRowSelected
    

end


LambdaCreateProfileSetting( "DTextEntry", "mw2cc_banner", "MW2 Call Cards", function( pnl, parent )
    pnl:SetZPos( 99 )
    local lbl = LAMBDAPANELS:CreateLabel( "[ Banner Path ]\nThe file path to a MW2CC banner relative to the materials folder for this lambda to always have\nExample: mw2cc/banners/DzClear.png\n\nRefer to MW2CC's Change Banner/Emblem panels for file paths.", parent, TOP )
    lbl:SetSize( 100, 100 )
    lbl:SetParent( parent )
    lbl:Dock( TOP )
    lbl:SetWrap( true )
    lbl:SetZPos( 98 )

    local button = vgui.Create( "DButton", parent )
    button:Dock( TOP )
    button:SetText( "Select Banner" )
    button:SetZPos( 100 )
    
    function button:DoClick()
        OpenCosmeticSelectionPanel( LocalPlayer(), "banner", pnl )
    end
end )

LambdaCreateProfileSetting( "DTextEntry", "mw2cc_emblem", "MW2 Call Cards", function( pnl, parent )
    pnl:SetZPos( 96 )
    local lbl = LAMBDAPANELS:CreateLabel( "[ Emblem Path ]\nThe file path to a MW2CC emblem relative to the materials folder for this lambda to always have\nExample: mw2cc/emblems/Ghost_Bust_emblem_MW2.png", parent, TOP )
    lbl:SetSize( 100, 100 )
    lbl:SetParent( parent )
    lbl:Dock( TOP )
    lbl:SetWrap( true )
    lbl:SetZPos( 95 )

    local button = vgui.Create( "DButton", parent )
    button:Dock( TOP )
    button:SetText( "Select Emblem" )
    button:SetZPos( 97 )

    function button:DoClick()
        OpenCosmeticSelectionPanel( LocalPlayer(), "emblem", pnl )
    end
end )
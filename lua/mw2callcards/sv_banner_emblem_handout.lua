-- Simply a system to hand out random banners and emblems to entities

function MW2CC:GetAssets( usecache )
    if self.assets and usecache then return self.assets end
    local assets = { banners = {}, emblems = {} }
    self.assets = assets

    -- Banners --
    local banners = file.Find( "materials/mw2cc/banners/*", "GAME" )
    for i = 1, #banners do
        assets.banners[ #assets.banners + 1 ] = "mw2cc/banners/" .. banners[ i ]
    end
    local custom_files = file.Find( "materials/mw2cc/custom/banners/*", "GAME" )
    for i = 1, #custom_files do
        assets.banners[ #assets.banners + 1 ] = "mw2cc/custom/banners/" .. custom_files[ i ]
    end

    

    -- Emblems --
    local emblems = file.Find( "materials/mw2cc/emblems/*", "GAME" )
    for i = 1, #emblems do
        assets.emblems[ #assets.emblems + 1 ] = "mw2cc/emblems/" .. emblems[ i ]
    end
    custom_files = file.Find( "materials/mw2cc/custom/emblems/*", "GAME" )
    for i = 1, #custom_files do
        assets.emblems[ #assets.emblems + 1 ] = "mw2cc/custom/emblems/" .. custom_files[ i ]
    end

    return assets
end

function MW2CC:GetRandomBanner()
    local files = self:GetAssets( true ).banners
    return files[ math.random( #files ) ]
end

function MW2CC:GetRandomEmblem()
    local files = self:GetAssets( true ).emblems
    return files[ math.random( #files ) ]
end

hook.Add( "OnEntityCreated", "mw2cc_cosmeticassignment", function( ent )
    timer.Simple( 0, function()
        if !IsValid( ent ) then return end
        ent.mw2cc_banner = MW2CC:GetRandomBanner()
        ent.mw2cc_emblem = MW2CC:GetRandomEmblem()
    end )
end )


local function ServerHasFile( path )
    print( "Server has " .. path .. "?", file.Exists( "materials/" .. path, "GAME" ) )
    return file.Exists( "materials/" .. path, "GAME" )
end

file.CreateDir( "mw2cc_customimagedata" )

-- Retrieve a player's custom banner/emblem for networking to others
local function RequestCustomImage( ply, path )
    net.Start( "mw2cc_net_customimage" )
    net.WriteString( path )
    net.Send( ply )

    print( "Requesting ", path, " from ", ply )

    local image = ""

    net.Receive( "mw2cc_net_customimage", function( len, ply )
        local size = net.ReadUInt( 32 )
        local chunk = net.ReadData( size )
        local isdone = net.ReadBool()

        print( "Received Chunk", string.NiceSize( #chunk ) )

        image = image .. chunk

        if isdone then
            print( "Completed retrieval" )
            file.Write( "mw2cc_customimagedata/test.png", image )
        end
    end )
end

net.Receive( "mw2cc_net_clientsendcosmetics", function( len, ply )
    local banner = net.ReadString()
    local emblem = net.ReadString()

    if banner != "" then
        ply.mw2cc_banner = banner

        if !ServerHasFile( banner ) then
            RequestCustomImage( ply, banner )
        end
    end

    if emblem != "" then
        ply.mw2cc_emblem = emblem

        if !ServerHasFile( emblem ) then
            --RequestCustomImage( ply, emblem )
        end
    end
end )
-- Simply a system to hand out random banners and emblems to entities

function MW2CC:GetRandomBanner()
    local files = file.Find( "materials/mw2cc/titles/*", "GAME" )
    local custom_files = file.Find( "materials/mw2cc/custom/titles/*", "GAME" )
    table.Add( files, custom_files )
    return "mw2cc/titles/" .. files[ math.random( #files ) ]
end

function MW2CC:GetRandomEmblem()
    local files = file.Find( "materials/mw2cc/emblems/*", "GAME" )
    local custom_files = file.Find( "materials/mw2cc/custom/emblems/*", "GAME" )
    table.Add( files, custom_files )
    return "mw2cc/emblems/" .. files[ math.random( #files ) ]
end

hook.Add( "OnEntityCreated", "mw2cc_cosmeticassignment", function( ent )
    timer.Simple( 0, function()
        if !IsValid( ent ) then return end
        ent.mw2cc_banner = MW2CC:GetRandomBanner()
        ent.mw2cc_emblem = MW2CC:GetRandomEmblem()
    end )
end )

net.Receive( "mw2cc_net_clientsendcosmetics", function( len, ply )
    local banner = net.ReadString()
    local emblem = net.ReadString()

    if banner != "" then
        ply.mw2cc_banner = banner
    end

    if emblem != "" then
        ply.mw2cc_emblem = emblem
    end
end )
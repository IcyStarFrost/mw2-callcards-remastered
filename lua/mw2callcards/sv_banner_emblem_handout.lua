function MW2CC:GetRandomBanner()
    local files = file.Find( "materials/mw2cc/titles/*", "GAME" )
    return "mw2cc/titles/" .. files[ math.random( #files ) ]
end

function MW2CC:GetRandomEmblem()
    local files = file.Find( "materials/mw2cc/emblems/*", "GAME" )
    return "mw2cc/emblems/" .. files[ math.random( #files ) ]
end

hook.Add( "OnEntityCreated", "mw2cc_cosmeticassignment", function( ent )
    timer.Simple( 0, function()
        if !IsValid( ent ) then return end
        ent.mw2cc_banner = MW2CC:GetRandomBanner()
        ent.mw2cc_emblem = MW2CC:GetRandomEmblem()
    end )
end )
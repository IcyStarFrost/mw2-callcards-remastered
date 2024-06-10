file.CreateDir( "mw2cc_data" )

MW2CC.QueuedCards = MW2CC.QueuedCards or {}
MW2CC.VTFindex = MW2CC.VTFindex or 0

-- Dispatches a call card
function MW2CC:DispatchCallCard( ent, comment, banner_name )
    MW2CC.QueuedCards[ #MW2CC.QueuedCards + 1 ] = { 
        ent = ent, 
        comment = comment, 
        banner_name = banner_name, 
        killcard = killcard,

        comment_x = ScrW() * 2,
        cur_pos = ScrW() * 2,
        end_time = 5,
        target_pos = ScrW() - 450,
        bottom_alpha = 255,
        played_snd = false,
    }
end

local green = Color( 122, 255, 122)
local green_glow = Color( 0, 197, 0, 166)

function MW2CC:GetMaterial( path )
    local mat 
    if string.EndsWith( path, ".vtf" ) then
        mat = CreateMaterial( "mw2cc_vtfmaterial" .. self.VTFindex, "UnlitGeneric", {
            [ "$basetexture" ] = path,
            [ "$translucent" ] = 1,
            [ "Proxies" ] = {
                [ "AnimatedTexture" ] = {
                    [ "animatedTextureVar" ] = "$basetexture",
                    [ "animatedTextureFrameNumVar" ] = "$frame",
                    [ "animatedTextureFrameRate" ] = 15
                }
            }
        })
        self.VTFindex = self.VTFindex + 1
    else
        mat = Material( path )
    end

    return mat
end

local mat = MW2CC:GetMaterial( "mw2cc/titles/DeathFromAbove.png" )
local emblem = MW2CC:GetMaterial( "mw2cc/emblems/spray.vtf" )

-- Retrieves a player's profile picture through the steam API. This will allow higher quality pfps for players if it succeeds
local function GetPlayerAvatarMaterial(ply, callback)
    if !IsValid( ply ) then return end
    local steamID64 = ply:SteamID64()

    http.Fetch( "https://steamcommunity.com/profiles/" .. steamID64 .. "?xml=1", function( body, len, headers, code )
        -- Shame.
        if code ~= 200 then
            return
        end

        local avatarUrl = string.match(body, "<avatarFull><!%[CDATA%[(.-)%]%]></avatarFull>")

        -- Get the image data
        http.Fetch( avatarUrl, function( body )
            file.Write( "mw2cc_data/" .. steamID64 .. ".jpg", body ) -- Write to a file so we can retrieve it in the Material() function
            local mat = Material( "../data/mw2cc_data/" .. steamID64 .. ".jpg" )
            callback( mat )

            -- Don't need it anymore
            timer.Simple( 0.5, function()
                file.Delete( "mw2cc_data/" .. steamID64 .. ".jpg" )
            end )
        end )
    end )
end



function MW2CC:DrawCallCard( x, y, ent, comment, comment_rela_x, bottomalpha )
    
    ent.mw2cc_lastdraw = CurTime()
    
    local w = 370
    local h = 100

    -- Main body
    surface.SetDrawColor( 129, 129, 129, 70 )
    --surface.SetMaterial( scanlines )
    surface.DrawRect( x, y, w, h )
    surface.SetDrawColor( 0, 0, 0)
    surface.DrawOutlinedRect( x, y, w, h, 2 )

    local scanlines = 20
    for i = 1, scanlines do 
        surface.SetDrawColor( 0, 0, 0, 150 )
        surface.DrawRect( x, y + ( h * ( i / scanlines ) ), w, 1 )
    end

    -- Lower body
    surface.SetDrawColor( 139, 139, 139, 40 * ( bottomalpha / 255 ) )
    surface.DrawRect( x, y + h, w, 30 )
    surface.SetDrawColor( 0, 0, 0, 255* ( bottomalpha / 255 ))
    surface.DrawOutlinedRect( x, y + h, w, 30, 1 )

    for i = 1, scanlines do 
        surface.SetDrawColor( 0, 0, 0, 150 * ( bottomalpha / 255 ) )
        surface.DrawRect( x, ( y + h ) + ( 30 * ( i / scanlines ) ), w, 1 )
    end

    -- Picture
    if ent:IsPlayer() and !IsValid( ent.mw2cc_pfp ) and !ent.mw2cc_hashdpfp then
        ent.mw2cc_pfp = vgui.Create( "AvatarImage", GetHUDPanel() )
        ent.mw2cc_pfp:SetPos( x + w - 90, y + h - 90  )
        ent.mw2cc_pfp:SetSize( 80, 80 )
        ent.mw2cc_pfp:SetPlayer( ent )
        
        function ent.mw2cc_pfp:Think()
            if ent.mw2cc_lastdraw + 0.1 < CurTime() then  
                self:Remove()
                return
            end
        end

        -- If this succeeds, congrats! higher quality PFP
        GetPlayerAvatarMaterial( ent, function( mat )
            if !mat then return end
            ent.mw2cc_hdpfp = mat
            ent.mw2cc_hashdpfp = true
            ent.mw2cc_pfp:Remove()
        end )
    elseif ent:IsPlayer() and ent.mw2cc_hashdpfp then -- Use the higher quality profile picture
        surface.SetDrawColor( 255, 255, 255 )
        surface.SetMaterial( ent.mw2cc_hdpfp )
        surface.DrawTexturedRect( x + w - 90, y + h - 90, 80, 80 )
    end

    if IsValid( ent.mw2cc_pfp ) then
        ent.mw2cc_pfp:SetPos( x + w - 90, y + h - 90 )
    end

    -- Emblem
    surface.SetDrawColor( 255, 255, 255, 255 * ( bottomalpha / 255 ))
    surface.SetMaterial( emblem )
    surface.DrawTexturedRect( x + w - 30, y + h + 3, 25, 25 )

    -- Banner
    surface.SetDrawColor( 255, 255, 255)
    surface.SetMaterial( mat )
    surface.DrawTexturedRect( x + 15, y + 10, 250, 45 )

    -- Comment
    
    draw.DrawText( comment, "mw2callcard_commentblurfont", ( x + 10 ) + comment_rela_x, y + h, green_glow, TEXT_ALIGN_LEFT )
    draw.DrawText( comment, "mw2callcard_commentfont", ( x + 10 ) + comment_rela_x, y + h, color_white, TEXT_ALIGN_LEFT )

    -- Main name
    if !IsValid( ent.mw2cc_name ) then
        ent.mw2cc_name = vgui.Create( "DLabel", GetHUDPanel() )
        ent.mw2cc_name:SetPos( x + 10, y + h - 40  )
        ent.mw2cc_name:SetSize( 265, 30 )
        ent.mw2cc_name:SetText( ent:Name():upper() )
        ent.mw2cc_name:SetFont( "mw2callcard_namefont" )
        ent.mw2cc_name:SetColor( green )

        function ent.mw2cc_name:Think()
            if ent.mw2cc_lastdraw + 0.1 < CurTime() then  
                self:Remove()
                return
            end
        end
    else
        ent.mw2cc_name:SetPos( x + 10, y + h - 40 )
    end
end


if IsValid( Entity(1).mw2cc_name ) then
    Entity(1).mw2cc_name:Remove()
end

if IsValid( Entity(1).mw2cc_pfp ) then
    Entity(1).mw2cc_pfp:Remove()
end

--[[ ent = ent, 
comment = comment, 
banner_name = banner_name, 
killcard = killcard,

comment_x = ScrW() * 2,
cur_pos = ScrW() * 2,
end_time = 5,
target_pos = 1600,
bottom_alpha = 255,
played_snd = false,
]]

hook.Add( "HUDPaint", "mw2-callcards-HudPaint", function()
    for k, card in ipairs( MW2CC.QueuedCards ) do
        if !card.played_snd then
            surface.PlaySound( "mw2cc/mp_cardslide_v6.wav" )
            card.played_snd = true
        end

        card.end_time_sys = card.end_time_sys or SysTime() + card.end_time

        local timeleft = card.end_time_sys - SysTime()

        if timeleft <= 0 then
            table.remove( MW2CC.QueuedCards, k )
            return
        end

        if timeleft > 5 * 0.5 then
            card.cur_pos = Lerp( FrameTime() * 30, card.cur_pos, card.target_pos )
        elseif timeleft < 5 * 0.2 then
            card.cur_pos = Lerp( FrameTime() * 5, card.cur_pos, ScrW() * 2 )
        end

        if timeleft < 5 * 0.70 then
            card.comment_x = Lerp( FrameTime() * 30, card.comment_x, 0 )
            card.bottom_alpha = ( card.comment_x / ( ScrW() * 2 ) ) * 255
        end

        MW2CC:DrawCallCard( card.cur_pos, 70, card.ent, card.comment, card.comment_x, card.bottom_alpha )

        break
    end
end )
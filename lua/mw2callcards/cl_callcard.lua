file.CreateDir( "mw2cc_data" )

MW2CC.QueuedCards = MW2CC.QueuedCards or {}
MW2CC.QueuedKillCards = MW2CC.QueuedKillCards or {}
MW2CC.VTFindex = MW2CC.VTFindex or 0

-- Dispatches a call card
function MW2CC:DispatchCallCard( ent, comment, banner_path, emblem_path, killcard )
    local tbl = { 
        ent = ent, 
        comment = comment, 
        killcard = killcard,
        target_x = ScrW() - 450,
        target_y = ScrH() - 150,
        bottom_alpha = 255,
        
        played_snd = false,
        invert = false,
    }

    if killcard then
        tbl.x = ScrW() / 2 - 370 / 2
        tbl.y = ScrH() * 2
        tbl.comment_x = 170
        tbl.comment_y = - 150
        tbl.end_time = 2
    else
        tbl.x = ScrW() * 2
        tbl.y = 70
        tbl.comment_x = ScrW() * 2
        tbl.comment_y = 0
        tbl.end_time = 5
    end

    tbl.banner_mat = MW2CC:GetMaterial( banner_path or "mw2cc/titles/DeathFromAbove.png" )
    tbl.emblem_mat = MW2CC:GetMaterial( emblem_path or "mw2cc/emblems/spray.vtf" )

    if tbl.ent.IsLambdaPlayer or tbl.ent:IsPlayer() then
        tbl.name = tbl.ent:Name():upper()
    else
        tbl.name = language.GetPhrase( "#" .. tbl.ent:GetClass() )
    end

    if ent.IsLambdaPlayer then
        tbl.pfp = ent:GetPFPMat()
    else
        local mdl = ent:GetModel()
        tbl.pfp = Material( "spawnicons/" .. string.sub( mdl, 1, #mdl - 4 ) .. ".png" )
    end

    if killcard then
        MW2CC.QueuedKillCards[ #MW2CC.QueuedKillCards + 1 ] = tbl
    else
        MW2CC.QueuedCards[ #MW2CC.QueuedCards + 1 ] = tbl
    end
end

net.Receive( "mw2cc_net_dispatchcard", function( len, ply )
    local ent = net.ReadEntity()
    if !IsValid( ent ) then return end
    local banner = net.ReadString()
    local emblem = net.ReadString()
    local comment = net.ReadString()
    local killcard = net.ReadBool()

    local banner_path = banner != "nil" and banner or nil
    local emblem_path = emblem != "nil" and emblem or nil
    MW2CC:DispatchCallCard( ent, comment, banner_path, emblem_path, killcard )
end )

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

-- Retrieves a player's profile picture through the steam API. This will allow higher quality pfps for players if it succeeds
local function GetPlayerAvatarMaterial(ply, callback)
    if !IsValid( ply ) then return end
    local steamID64 = ply:SteamID64()

    http.Fetch( "https://steamcommunity.com/profiles/" .. steamID64 .. "?xml=1", function( body, len, headers, code )
        -- Shame.
        if code != 200 then
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

local pnls = {}
function MW2CC:RemovePanels()
    for k, v in ipairs( pnls ) do
        if IsValid( v ) then
            v:Remove()
        end
    end
end


function MW2CC:DrawCallCard( card )
    
    card.lastdraw = CurTime()
    
    local w = 370
    local h = 100
    local x = card.x
    local y = card.y

    
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
    surface.SetDrawColor( 139, 139, 139, 40 * ( card.bottom_alpha / 255 ) )
    surface.DrawRect( x, y + h, w, 30 )
    surface.SetDrawColor( 0, 0, 0, 255* ( card.bottom_alpha / 255 ))
    surface.DrawOutlinedRect( x, y + h, w, 30, 1 )

    for i = 1, scanlines do 
        surface.SetDrawColor( 0, 0, 0, 150 * ( card.bottom_alpha / 255 ) )
        surface.DrawRect( x, ( y + h ) + ( 30 * ( i / scanlines ) ), w, 1 )
    end

    -- Picture
    if card.ent:IsPlayer() and !IsValid( card.mw2cc_pfp ) and !card.hashdpfp then
        card.mw2cc_pfp = vgui.Create( "AvatarImage", GetHUDPanel() )
        card.mw2cc_pfp:SetPos( x + w - 90, y + h - 90  )
        card.mw2cc_pfp:SetSize( 80, 80 )
        card.mw2cc_pfp:SetPlayer( card.ent )

        pnls[ #pnls + 1 ] = card.mw2cc_pfp
        
        function card.mw2cc_pfp:Think()
            if card.lastdraw + 0.1 < CurTime() then  
                self:Remove()
                return
            end
        end

        -- If this succeeds, congrats! higher quality PFP
        GetPlayerAvatarMaterial( card.ent, function( mat )
            if !mat then return end
            card.hdpfp = mat
            card.hashdpfp = true
            card.mw2cc_pfp:Remove()
        end )
    elseif card.ent:IsPlayer() and card.hashdpfp then -- Use the higher quality profile picture
        surface.SetDrawColor( 255, 255, 255 )
        surface.SetMaterial( card.hdpfp )
        surface.DrawTexturedRect( x + w - 90, y + h - 90, 80, 80 )
    else
        surface.SetDrawColor( 255, 255, 255 )
        surface.SetMaterial( card.pfp )
        surface.DrawTexturedRect( x + w - 90, y + h - 90, 80, 80 )
    end

    if IsValid( card.mw2cc_pfp ) then
        card.mw2cc_pfp:SetPos( x + w - 90, y + h - 90 )
    end

    -- Emblem
    surface.SetDrawColor( 255, 255, 255, 255 * ( card.bottom_alpha / 255 ))
    surface.SetMaterial( card.emblem_mat )
    surface.DrawTexturedRect( x + w - 30, y + h + 3, 25, 25 )

    -- Banner
    surface.SetDrawColor( 255, 255, 255)
    surface.SetMaterial( card.banner_mat )
    surface.DrawTexturedRect( x + 15, y + 10, 250, 45 )

    -- Comment
    
    draw.DrawText( card.comment, "mw2callcard_commentblurfont", ( !card.invert and ( x + 10 ) or ( x + w - 100 ) ) + card.comment_x, ( y + h ) + card.comment_y, green_glow, !card.killcard and TEXT_ALIGN_LEFT or TEXT_ALIGN_CENTER )
    draw.DrawText( card.comment, "mw2callcard_commentfont", ( !card.invert and ( x + 10 ) or ( x + w - 100 ) ) + card.comment_x, ( y + h ) + card.comment_y, color_white, !card.killcard and TEXT_ALIGN_LEFT or TEXT_ALIGN_CENTER )

    -- Main name
    if !IsValid( card.mw2cc_name ) then
        card.mw2cc_name = vgui.Create( "DLabel", GetHUDPanel() )
        card.mw2cc_name:SetPos( x + 10, y + h - 40  )
        card.mw2cc_name:SetSize( 265, 30 )
        card.mw2cc_name:SetText( card.name )
        card.mw2cc_name:SetFont( "mw2callcard_namefont" )
        card.mw2cc_name:SetColor( green )

        pnls[ #pnls + 1 ] = card.mw2cc_name

        function card.mw2cc_name:Think()
            if card.lastdraw + 0.1 < CurTime() then  
                self:Remove()
                return
            end
        end
    else
        card.mw2cc_name:SetPos( x + 10, y + h - 40 )
    end
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

        if timeleft > card.end_time * 0.5 then
            card.x = Lerp( FrameTime() * 30, card.x, card.target_x )
        elseif timeleft < card.end_time * 0.2 then
            card.x = Lerp( FrameTime() * 5, card.x, ScrW() * 2 )
        end

        if timeleft < card.end_time * 0.70 then
            card.comment_x = Lerp( FrameTime() * 30, card.comment_x, 0 )
            card.bottom_alpha = ( card.comment_x / ( ScrW() * 2 ) ) * 255
        end

        MW2CC:DrawCallCard( card )

        break
    end

    for k, card in ipairs( MW2CC.QueuedKillCards ) do
        card.end_time_sys = card.end_time_sys or SysTime() + card.end_time

        local timeleft = card.end_time_sys - SysTime()

        if timeleft <= 0 then
            table.remove( MW2CC.QueuedKillCards, k )
            return
        end

        if timeleft > card.end_time * 0.5 then
            card.y = Lerp( FrameTime() * 30, card.y, card.target_y )
        elseif timeleft < card.end_time * 0.2 then
            card.y = Lerp( FrameTime() * 5, card.y, ScrH() * 2 )
        end

        MW2CC:DrawCallCard( card )

        break
    end
end )
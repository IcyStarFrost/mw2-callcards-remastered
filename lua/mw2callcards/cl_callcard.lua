file.CreateDir( "mw2cc_data" )

-- Previously with the old MW2 call cards, there was absolutely no queue system which meant if a card attempted to show whilest one is active,
-- The new card would be discarded and the credit to the holder ent would be lost

MW2CC.QueuedCards = MW2CC.QueuedCards or {}
MW2CC.QueuedKillCards = MW2CC.QueuedKillCards or {}
MW2CC.VTFindex = MW2CC.VTFindex or 0

local green = Color( 122, 255, 122)
local green_glow = Color( 0, 197, 0, 166)

-- Dispatches a call card

-- ent              | Entity |          The entity that will hold this callcard. Assigns names and picture automatically
-- comment          | String |          The thing that the holder did. For example, "DOUBLE KILL!"
-- banner_path      | String |          The file path relative to the materials folder to a .jpg, .png, or .vtf. Animated VTFs are supported
-- emblem_path      | String |          Same as banner_path. Animated VTFs are supported
-- killcard         | Bool or nil |     Whether this card should render as a kill card or not
-- snd              | String or "" for no sound |   The sound effect to play instead of the default
function MW2CC:DispatchCallCard( ent, comment, banner_path, emblem_path, killcard, snd )
    local tbl = { 
        ent = ent, 
        comment = comment, 
        killcard = killcard,
        target_x = ScrW() * GetConVar( "mw2cc_announcex" ):GetFloat(),
        target_y = ScrH() * GetConVar( "mw2cc_killy" ):GetFloat(),
        bottom_alpha = 255,
        snd = snd,
        
        played_snd = false,
    }
    
    -- Set up the card positions based on if its a kill card or a call card
    if killcard then
        local invert = GetConVar( "mw2cc_killy" ):GetFloat() < 0.5
        tbl.x = ScrW() * GetConVar( "mw2cc_killx" ):GetFloat()
        tbl.y = !invert and ScrH() * 2 or ScrH() * -2

        tbl.invert = invert
        tbl.comment_x = 170
        tbl.comment_y = !invert and -150 or 50
        tbl.end_time = 3
    else
        local invert = GetConVar( "mw2cc_announcex" ):GetFloat() < 0.5

        tbl.invert = invert
        tbl.x = !invert and ScrW() * 2 or ScrW() * -2
        tbl.y = ScrH() * GetConVar( "mw2cc_announcey" ):GetFloat()
        tbl.comment_x = !invert and ScrW() * 2 or ScrW() * -2
        tbl.comment_y = 0
        tbl.end_time = 5
    end

    -- Prepare materials
    tbl.banner_mat = MW2CC:GetMaterial( banner_path or "mw2cc/titles/DeathFromAbove.png" )
    tbl.emblem_mat = MW2CC:GetMaterial( emblem_path or "mw2cc/emblems/spray.vtf" )

    -- Prepare name
    if tbl.ent.IsLambdaPlayer or tbl.ent:IsPlayer() then
        tbl.name = tbl.ent:Name():upper()
    elseif tbl.ent.IsZetaPlayer then
        tbl.name = tbl.ent:GetNW2String('zeta_name',"Zeta Player")
    else
        tbl.name = language.GetPhrase( "#" .. tbl.ent:GetClass() )
    end

    -- Prepare pictures
    if ent.IsLambdaPlayer then
        tbl.pfp = ent:GetPFPMat()
    elseif ent.IsZetaPlayer then
        tbl.pfp = MW2CC:GetMaterial( zeta:GetNW2String("zeta_profilepicture","none") )
    else
        local mdl = ent:GetModel()
        tbl.pfp = Material( "spawnicons/" .. string.sub( mdl, 1, #mdl - 4 ) .. ".png" )

        if tbl.pfp:IsError() then
            tbl.pfp = Material( "entities/" .. ent:GetClass() .. ".png" )
        end
    end

    -- Assign the card to the correct queue
    if killcard then
        MW2CC.QueuedKillCards[ #MW2CC.QueuedKillCards + 1 ] = tbl
    else
        MW2CC.QueuedCards[ #MW2CC.QueuedCards + 1 ] = tbl
    end
end

-- Returns a Material from the given path. Supports .VTF files that are animated
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
        mat = Material( path, "smooth" )
    end

    return mat
end

-- Retrieves a player's profile picture through the steam API. This will allow higher quality pfps for players if it succeeds
local function GetPlayerAvatarMaterial(ply, callback)
    if !IsValid( ply ) then return end
    local steamID64 = ply:SteamID64()

    http.Fetch( "https://steamcommunity.com/profiles/" .. steamID64 .. "?xml=1", function( body, len, headers, code )
        -- Shame. No 4k HD RTX enabled profile pictures
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


function MW2CC:DrawCallCard( card )

    card.lastdraw = CurTime() -- Used to remove VGUI elements if this card isn't drawn anymore
    
    local w = 370
    local h = 100
    local x = card.x
    local y = card.y

    
    -- Main body
    surface.SetDrawColor( 129, 129, 129, 70 )
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
    ----------

    -- Emblem
    surface.SetDrawColor( 255, 255, 255, 255 * ( card.bottom_alpha / 255 ))
    surface.SetMaterial( card.emblem_mat )
    surface.DrawTexturedRect( x + w - 30, y + h + 3, 25, 25 )

    -- Banner
    surface.SetDrawColor( 255, 255, 255)
    surface.SetMaterial( card.banner_mat )
    surface.DrawTexturedRect( x + 15, y + 10, 250, 45 )

    -- Comment
    
    draw.DrawText( card.comment, "mw2callcard_commentblurfont", ( x + 10 ) + card.comment_x, ( y + h ) + card.comment_y, green_glow, !card.killcard and TEXT_ALIGN_LEFT or TEXT_ALIGN_CENTER )
    draw.DrawText( card.comment, "mw2callcard_commentfont", ( x + 10 ) + card.comment_x, ( y + h ) + card.comment_y, color_white, !card.killcard and TEXT_ALIGN_LEFT or TEXT_ALIGN_CENTER )

    -- Main name
    if !IsValid( card.mw2cc_name ) then
        card.mw2cc_name = vgui.Create( "DLabel", GetHUDPanel() )
        card.mw2cc_name:SetPos( x + 10, y + h - 40  )
        card.mw2cc_name:SetSize( 265, 30 )
        card.mw2cc_name:SetText( card.name )
        card.mw2cc_name:SetFont( "mw2callcard_namefont" )
        card.mw2cc_name:SetColor( green )

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


hook.Add( "HUDPaint", "mw2-callcards-HudPaint", function()

    -- Call card queue --
    -- The announcement cards
    for k, card in ipairs( MW2CC.QueuedCards ) do
        -- Classic sound
        if !card.played_snd and card.snd != "" then
            surface.PlaySound( card.snd )
            card.played_snd = true
        end

        card.end_time_sys = card.end_time_sys or SysTime() + card.end_time

        local timeleft = card.end_time_sys - SysTime()

        if timeleft <= 0 then
            table.remove( MW2CC.QueuedCards, k )
            return
        end

        if timeleft > card.end_time * 0.5 then -- Animate in
            card.x = Lerp( FrameTime() * 30, card.x, card.target_x )
        elseif timeleft < card.end_time * 0.2 then -- Animate out
            card.x = Lerp( FrameTime() * 5, card.x, !card.invert and ScrW() * 2 or ScrW() * -2 )
        end

        -- Animate the comment in after a delay
        if timeleft < card.end_time * 0.70 then
            card.comment_x = Lerp( FrameTime() * 30, card.comment_x, 0 )
            card.bottom_alpha = ( card.comment_x / ( ScrW() * 2 ) ) * 255
        end

        MW2CC:DrawCallCard( card )

        break
    end

    -- Kill card queue --
    for k, card in ipairs( MW2CC.QueuedKillCards ) do
        card.end_time_sys = card.end_time_sys or SysTime() + card.end_time

        local timeleft = card.end_time_sys - SysTime()

        if timeleft <= 0 then
            table.remove( MW2CC.QueuedKillCards, k )
            return
        end

        if timeleft > card.end_time * 0.5 then -- Animate in
            card.y = Lerp( FrameTime() * 30, card.y, card.target_y )
        elseif timeleft < card.end_time * 0.2 then -- Animate out
            card.y = Lerp( FrameTime() * 5, card.y, !card.invert and ScrH() * 2 or ScrH() * -2 )
        end

        MW2CC:DrawCallCard( card )

        break
    end
end )

net.Receive( "mw2cc_net_dispatchcard", function( len, ply )
    local ent = net.ReadEntity()
    if !IsValid( ent ) then return end
    local banner = net.ReadString()
    local emblem = net.ReadString()
    local comment = net.ReadString()
    local snd = net.ReadString()
    local killcard = net.ReadBool()

    if !killcard and !GetConVar( "mw2cc_allowannouncecards" ):GetBool() then return end
    if killcard and !GetConVar( "mw2cc_allowkillcards" ):GetBool() then return end

    local path = snd == "" and "mw2cc/mp_cardslide_v6.wav" or snd == "none" and "" or snd

    local banner_path = banner != "nil" and banner or nil
    local emblem_path = emblem != "nil" and emblem or nil
    MW2CC:DispatchCallCard( ent, comment, banner_path, emblem_path, killcard, path )
end )
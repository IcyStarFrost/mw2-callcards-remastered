
-- Sends a call card to a specified player or every player
-- sndpath can be nil for the default sound or a sound path for a custom sound. input "none" if no sound should play
function MW2CC:DispatchCallCard( ent, comment, killcard, ply, sndpath )
    net.Start( "mw2cc_net_dispatchcard" )
    net.WriteEntity( ent )
    net.WriteString( ent.mw2cc_banner or "nil" )
    net.WriteString( ent.mw2cc_emblem or "nil" )
    net.WriteString( comment )
    net.WriteString( !sndpath and "" )
    net.WriteBool( killcard or false ) 
    if ply then net.Send( ply ) else net.Broadcast() end
end


function MW2CC:EntKilled( victim, attacker )
    victim.mw2cc_killstreak = 0

    if victim == attacker then return end
    
    attacker.mw2cc_killstreak = attacker.mw2cc_killstreak and attacker.mw2cc_killstreak + 1 or 1

    if attacker:IsPlayer() then
        MW2CC:DispatchCallCard( victim, "Killed", true, attacker )
    end

    if victim:IsPlayer() then
        MW2CC:DispatchCallCard( attacker, "Killed By", true, victim )
    end

    attacker.mw2cc_rapidkills = attacker.mw2cc_rapidkills and 
    CurTime() < attacker.mw2cc_rapidkills.timeout and 
    attacker.mw2cc_rapidkills or { timeout = CurTime() + 0.5, kills = 0, ignoreents = {} }

    if !attacker.mw2cc_rapidkills.ignoreents[ victim ] then
        attacker.mw2cc_rapidkills.timeout = CurTime() + 0.5
        attacker.mw2cc_rapidkills.kills = attacker.mw2cc_rapidkills.kills + 1
        attacker.mw2cc_rapidkills.ignoreents[ victim ] = true
    end

    timer.Create( "mw2cc_rapidkills_" .. attacker:GetCreationID(), 0.5, 1, function()
        if !IsValid( attacker ) then return end 

        if attacker.mw2cc_rapidkills.kills == 2 then
            MW2CC:DispatchCallCard( attacker, "Double Kill!" )
        elseif attacker.mw2cc_rapidkills.kills == 3 then
            MW2CC:DispatchCallCard( attacker, "Triple Kill!" )
        elseif attacker.mw2cc_rapidkills.kills > 3 then
            MW2CC:DispatchCallCard( attacker, "Multi Kill!" )
        end
    end )

    if victim:GetClass() == "npc_strider" then
        MW2CC:DispatchCallCard( attacker, "DESTROYED STRIDER!" )
    end

    if attacker.mw2cc_killstreak % GetConVar( "mw2cc_killstreakthreshold" ):GetInt() == 0 then
        self:DispatchCallCard( attacker, string.CardinalToOrdinal( attacker.mw2cc_killstreak ):upper() .. " KILLSTREAK!" )
        hook.Run( "MW2CC_OnKillstreak", attacker, attacker.mw2cc_killstreak )
    end
end

hook.Add( "PlayerDeath", "mw2cc_playerdeath", function( victim, inf, attacker ) 
    MW2CC:EntKilled( victim, attacker )
end )

hook.Add( "PostEntityTakeDamage", "mw2cc_postentitytakedamage", function( ent, dmg )
    if !ent:IsNPC() and !ent:IsNextBot() or ent:IsPlayer() or ent:Health() > 0 or ent.mw2cc_ignore then return end

    ent.mw2cc_ignore = true
    MW2CC:EntKilled( ent, dmg:GetAttacker() )
end )

hook.Add( "LambdaOnKilled", "mw2cc_lambdaonkilled", function( lambda, dmg )
    MW2CC:EntKilled( lambda, dmg:GetAttacker() )
end )

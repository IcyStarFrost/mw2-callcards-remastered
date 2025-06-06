-- Function by https://github.com/alexgrist/NetStream
local function DataSplit( data )
    local index = 1
    local result = {}
    local buffer = {}

    for i = 0, #data do
        buffer[ #buffer + 1 ] = string.sub( data, i, i )
                
        if #buffer == 32768 then
            result[ #result + 1 ] = table.concat( buffer )
                index = index + 1
            buffer = {}
        end
    end
            
    result[ #result + 1 ] = table.concat( buffer )
    
    return result
end

net.Receive( "mw2cc_net_customimage", function()
    local path = net.ReadString()
    local file_ = file.Open( "materials/" .. path, "rb", "GAME" )
    local image = file_:Read()
    file_:Close()

    if image then
        local cor = coroutine.wrap( function()

            -- Prepare the data
            local compress = util.Compress( image )
            local chunks = DataSplit( compress )

            -- Send the chunked data to the server
            for i, block in ipairs( chunks ) do
                net.Start( "mw2cc_net_customimage" )
                net.WriteUInt( #block, 32 )
                net.WriteData( block )
                net.WriteBool( i == #chunks )
                net.SendToServer()

                coroutine.wait( 0.2 )
            end

            hook.Remove( "Think", "mw2cc_imagecoroutine" .. path )
        end )
        hook.Add( "Think", "mw2cc_imagecoroutine" .. path, cor )
    end
end )
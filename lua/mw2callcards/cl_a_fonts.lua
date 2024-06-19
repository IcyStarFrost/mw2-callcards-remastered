MW2CC.LoadedFonts = MW2CC.LoadedFonts or false

local function MW2CCLoadFonts(force)
    if !MW2CC.LoadedFonts or force then
        local scale = ScreenScaleH(0.45) * GetConVar("mw2cc_scale"):GetFloat()
        surface.CreateFont( "mw2callcard_namefont", {
            font = "BankGothic",
            extended = false,
            size = 22 * scale,
            weight = 500,
            blursize = 0,
            scanlines = 2,
            antialias = true,
            underline = false,
            italic = false,
            strikeout = false,
            symbol = false,
            rotary = false,
            shadow = false,
            additive = false,
            outline = true,
        } )

        surface.CreateFont( "mw2callcard_commentfont", {
            font = "BankGothic",
            extended = false,
            size = 30 * scale,
            weight = 500,
            blursize = 0,
            scanlines = 0,
            antialias = true,
            underline = false,
            italic = false,
            strikeout = false,
            symbol = false,
            rotary = false,
            shadow = false,
            additive = false,
            outline = true,
        } )

        surface.CreateFont( "mw2callcard_commentblurfont", {
            font = "BankGothic",
            extended = false,
            size = 30 * scale,
            weight = 500,
            blursize = 5,
            scanlines = 0,
            antialias = true,
            underline = false,
            italic = false,
            strikeout = false,
            symbol = false,
            rotary = false,
            shadow = false,
            additive = false,
            outline = true,
        } )
        MW2CC.LoadedFonts = true
    end
end

MW2CCLoadFonts()

cvars.AddChangeCallback("mw2cc_scale", MW2CCLoadFonts)
hook.Add("OnScreenSizeChanged", "mw2-callcards-font", function() MW2CCLoadFonts(true) end)
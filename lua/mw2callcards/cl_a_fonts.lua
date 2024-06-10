MW2CC.LoadedFonts = MW2CC.LoadedFonts or false

--if !MW2CC.LoadedFonts then
    surface.CreateFont( "mw2callcard_namefont", {
        font = "BankGothic", 
        extended = false,
        size = 22,
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
        size = 30,
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
        size = 30,
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
--end
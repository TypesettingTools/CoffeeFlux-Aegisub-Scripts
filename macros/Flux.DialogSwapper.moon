export script_name        = "Dialog Swapper"
export script_description = "Perform text swapping operations on a script"
export script_author      = "CoffeeFlux"
export script_version     = "1.2.2"
export script_namespace   = "Flux.DialogSwapper"

DependencyControl = require("l0.DependencyControl") {
    url: "https://github.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts/blob/master/macros/Flux.DialogSwapper.moon"
    feed: "https://raw.githubusercontent.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts/master/DependencyControl.json"
    {}
}

ConfigHandler = DependencyControl\getConfigHandler {
    Settings: {
        Delimeter: "*"
        VerifyStyle: true
        LineStarters: "-,_"
        LineNames: "Main,Alt,Overlap"
    }
}
Settings = ConfigHandler.c.Settings

Dialog = {
    {
        class: "label"
        label: "Delimeter:"
        x: 0
        y: 0
    }
    {
        class: "edit"
        name: "Delimeter"
        text: "*"
        x: 2
        y: 0
    }
    {
        class: "label"
        label: "Verify Style:"
        x: 0
        y: 1
    }
    {
        class: "checkbox"
        name: "VerifyStyle"
        value: true
        x: 2
        y: 1
    }
    {
        class: "label"
        label: "Line Name Starters:"
        x: 0
        y: 2
    }
    {
        class: "edit"
        name: "LineStarters"
        text: "-,_"
        x: 2
        y: 2
    }
    {
        class: "label"
        label: "Line Names:"
        x: 0
        y: 3
    }
    {
        class: "edit"
        name: "LineNames"
        text: "Main,Alt,Overlap"
        x: 2
        y: 3
    }
}

Delimeter = "%*"
-- These are roundabout and initially confusing, but it's necessary to avoid unswapping
SwapPatterns = {
    -- Convert "{*}foo{*bar}" to "{*}bar{*foo}", including {*}foo{*} to {*}{*foo}
    {
        "{" .. Delimeter .. "}([^{]-){" .. Delimeter .."([^}]*)}",
        "{" .. Delimeter .. "}%2{" .. Delimeter .. "%1}"
    }
    -- Convert "{**bar}" to "{*}bar{*}"
    {
        "{" .. Delimeter .. Delimeter .. "([^}]+)}",
        "{" .. Delimeter .. "}%1{" .. Delimeter .. "}"
    }
    -- Convert "{*}{*bar}" to "{**bar}"
    {
        "{" .. Delimeter .. "}{".. Delimeter,
        "{" .. Delimeter .. Delimeter
    }
}
ValidLineStarters = "%-%_"
ValidLineNames = {Main, Alt, Overlap}
-- Toggle line comment status if effect field matches three times the delimiter
CommentPattern = "^" .. Delimeter .. Delimeter .. Delimeter .. "$"
VerifyStyle = true

EscapeChars = (Chars) ->
    return string.gsub Chars, ".", "%%%1"

Explode = (Text, Pattern) -> -- I'm copying PHP function naming, god help me
    Pos, Final = 0, {}
    Lazy = -> -- haha this is awful i'll clean it up some day
        return string.find Text, Pattern, Pos, true 
    for Start, Stop in Lazy
        Final[#Final + 1] = string.sub Text, Pos, Start - 1 
        Pos = Stop + 1
    Final[#Final + 1] = string.sub Text, Pos 
    return Final

ValidateLine = (Style) ->
    if VerifyStyle
        for Name in *ValidLineNames
            if Style\match "[" .. ValidLineStarters .. "]" .. Name
                return true
    else
        return true
    return false

UpdateDialog = ->
    Dialog[2].text  = Settings.Delimeter
    Dialog[4].value = Settings.VerifyStyle
    Dialog[6].text  = Settings.LineStarters
    Dialog[8].text  = Settings.LineNames

UpdateVars = ->
    Delimeter = "%" .. Settings.Delimeter
    ValidLineStarters = EscapeChars string.gsub(Settings.LineStarters, ",", "")
    ValidLineNames = Explode Settings.LineNames, ","
    VerifyStyle = Settings.VerifyStyle

Replace = (Subs) ->
    for LineNumber = 1, #Subs
        Line = Subs[LineNumber]

        if Line.class == "dialogue"
            Style = Line.style
            Effect = Line.effect
            
            if Effect\match CommentPattern
                Line.comment = not Line.comment

            if ValidateLine Style
                for Pair in *SwapPatterns
                    Line.text = Line.text\gsub Pair[1], Pair[2]
            Subs[LineNumber] = Line

Swap = (Subs, Selected, Active) ->
    Replace Subs
    aegisub.set_undo_point "Swap Dialog"

Config = ->
    Button, Results = aegisub.dialog.display Dialog
    unless Button == "Cancel"
        Settings.Delimeter    = Results.Delimeter
        Settings.VerifyStyle  = Results.VerifyStyle
        Settings.LineStarters = Results.LineStarters
        Settings.LineNames    = Results.LineNames
        ConfigHandler\write!
        UpdateDialog!
        UpdateVars!

UpdateDialog!
UpdateVars!

DependencyControl\registerMacros {
    { "Swap Dialog", "Performs the swap operations upon the script", Swap }
    { "Configure", "Launches the configuration dialog", Config }
}

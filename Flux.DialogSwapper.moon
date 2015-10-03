export script_name        = "Dialog Swapper"
export script_description = "Perform text swapping operations on a script"
export script_author      = "CoffeeFlux" --Originally by Daiz, butchered by Fyurie
export script_version     = "1.1.3"
export script_namespace   = "Flux.DialogSwapper"

DependencyControl = require("l0.DependencyControl") {
    url: "https://github.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts/blob/master/Flux.DialogSwapper.moon"
    feed: "https://raw.githubusercontent.com/TypesettingCartel/line0-Aegisub-Scripts/master/DependencyControl.json"
    {}
}

Delimeter = "%*" -- always escape this, must be a special char
-- These are roundabout and initially confusing, but it's necessary to avoid unswapping
SwapPatterns = {
    -- Convert "{*}foo{*bar}" to "{*}bar{*foo}", including {*}foo{*} to {*}{*foo}
    {
        "{" .. Delimeter .. "}([^{]-){" .. Delimeter .."([^}]*)}",
        "{" .. Delimeter .. "}%2{" .. Delimeter .. "%1}"
    },
    -- Convert "{**bar}" to "{*}bar{*}"
    {
        "{" .. Delimeter .. Delimeter .. "([^}]+)}",
        "{" .. Delimeter .. "}%1{" .. Delimeter .. "}"
    },
    -- Convert "{*}{*bar}" to "{**bar}"
    {
        "{" .. Delimeter .. "}{".. Delimeter,
        "{" .. Delimeter .. Delimeter
    }
}
ValidLineStarters = "-_"
ValidLineNames = {"Main", "Alt", "Overlap"}
-- Toggle line comment status if effect field matches three times the delimiter
CommentPattern = "^" .. Delimeter .. Delimeter .. Delimeter .. "$"

ValidateLine = (Style) ->
    for Name in *ValidLineNames
        if Style\match "[" .. ValidLineStarters .. "]" .. Name then return true
    return false

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

DependencyControl\registerMacro Swap

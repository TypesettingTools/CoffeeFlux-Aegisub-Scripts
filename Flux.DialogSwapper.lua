script_name        = "Dialog Swapper"
script_description = "Perform dialog swap operations on a script"
script_author      = "CoffeeFlux" --Originally by Daiz, butchered by Fyurie
script_version     = "1.0.0"
script_namespace   = "Flux.DialogSwapper"

local DependencyControl = require("l0.DependencyControl"){
    feed = "https://raw.githubusercontent.com/TypesettingCartel/line0-Aegisub-Scripts/master/DependencyControl.json",
    {}
}

function replace(c, subs)

    local re1 = "{%" .. c .. "}([^{]*){%" .. c .."([^%}" .. c.. "]?[^}]*)}"
    local fn1 = "{%" .. c .. "}%2{%" .. c .. "%1}"
    local re2 = "{%" .. c .. "%" .. c .. "([^}]+)}"
    local fn2 = "{%" .. c .. "}%1{%" .. c .. "}"
    local re3 = "{%" .. c .. "}{%".. c
    local fn3 = "{%" .. c .. "%".. c
    local re4 = "^%" .. c .. "%".. c .. "%" .. c .. "$" 

    for i = 1, #subs do

        local l = subs[i]

        if l.class == "dialogue" then

            local s = l.style
            local e = l.effect

            -- toggle line comment status if effect field matches '***'
            if e:match(re4) then 
                l.comment = not l.comment 
            end

            -- replacements shouldn't happen for non-dialogue lines
            -- in order to avoid any unfortunate accidents
            if s:match("[-_]Main") or
               s:match("[-_]Alt") or
               s:match("[-_]Overlap") then

                l.text = l.text

                -- Convert "{*}foo{*bar}" to "{*}bar{*foo}"
                :gsub(re1, fn1)

                -- Convert "foo{**-bar}" to "foo{*}-bar{*}"
                :gsub(re2, fn2)

                -- Convert "foo{*}{*-bar}" to "foo{**-bar}"
                :gsub(re3, fn3)

            end
        end

        subs[i] = l

    end
end

function swap(subs, selected, active)
    replace("*", subs)
    aegisub.set_undo_point("Swap Dialog")
end

DependencyControl:registerMacro(swap)

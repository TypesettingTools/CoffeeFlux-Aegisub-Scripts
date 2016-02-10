export script_name        = 'Title Case'
export script_description = 'Applies English Title Case to selected lines'
export script_author      = 'tophf'
export script_version     = '1.3.0'
export script_namespace   = 'Flux.TitleCase'

DependencyControl = require("l0.DependencyControl") {
    url: "https://github.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts/blob/master/macros/Flux.TitleCase.moon"
    feed: "https://raw.githubusercontent.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts/master/DependencyControl.json"
    {
        "aegisub.re",
        {"a-mo.LineCollection", version: "1.1.4", url: "https://github.com/TypesettingTools/Aegisub-Motion",
         feed: "https://raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"},
        {"l0.ASSFoundation", version: "0.3.3", url: "https://github.com/TypesettingTools/ASSFoundation",
         feed: "https://raw.githubusercontent.com/TypesettingTools/ASSFoundation/master/DependencyControl.json"}
    }
}

re, LineCollection, ASS = DependencyControl\requireModules!

lowerCase = {'a', 'an', 'the', 'at', 'by', 'for', 'in', 'of', 'on', 'to', 'up', 'and', 'as', 'but', 'or', 'nor', 'via', 'vs'}

tableContains = (tab, query) ->
    for item in *tab
        if item == query
            return true
    return false

titleCase = (subs, sel) ->
    for i in *sel
        with line = subs[i]
            linestart = true
            prevblockpunct = ''

            s = .text\gsub('\\N','\n')\gsub('\\n','\r')\gsub('\\h','\a')

            s = ('{}'..s)\gsub '(%b{})([^{]+)', (tag, text) ->
                blockstart = true
                tag..text\gsub "([!?.\"”»') ]-)([^`~!@#$%^&*()_=+[%]{};:\"\\|,./<>%s-]+)", (punct, word) ->
                    newsentence = ((blockstart and prevblockpunct or '')..punct)\match('[.!?]')
                    first = rxFirst\match(word)[1].str
                    first = if linestart or newsentence or not tableContains(lowerCase, word\lower)
                        unicode.to_upper_case first
                    else
                        unicode.to_lower_case first

                    linestart = false
                    blockstart = false
                    prevblockpunct = punct

                    punct .. first .. unicode.to_lower_case word\sub #first + 1

            s = s\sub(3)\gsub('\n','\\N')\gsub('\r','\\n')\gsub('\a','\\h')
            if s != .text
                .text = s
                subs[i] = line

DependencyControl\registerMacro titleCase
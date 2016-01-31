export script_name        = 'Selegator'
export script_description = 'Select/navigate in the subtitle grid'
export script_author      = 'tophf'
export script_version     = '1.1.4'
export script_namespace   = 'Flux.Selegator'

DependencyControl = require("l0.DependencyControl") {
    url: "https://github.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts/blob/master/macros/Flux.Selegator.moon"
    feed: "https://raw.githubusercontent.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts/master/DependencyControl.json"
    {}
}

SelectAll = (subs, sel, act) ->
    lookforstyle = subs[act].style
    if #sel>1
        [i for i in *sel when subs[i].style==lookforstyle]
    else
        [k for k,s in ipairs subs when s.style==lookforstyle]

Previous = (subs, sel, act) ->
    lookforstyle = subs[act].style
    for i = act-1,1,-1
        return if subs[i].class!='dialogue'
        if subs[i].style==lookforstyle
            return {i}

Next = (subs, sel, act) ->
    lookforstyle = subs[act].style
    for i = act+1,#subs
        if subs[i].style==lookforstyle
            return {i}

FirstInBlock = (subs, sel, act) ->
    lookforstyle = subs[act].style
    for i = act-1,1,-1
        if subs[i].class!='dialogue' or subs[i].style!=lookforstyle
            return {i+1}

LastInBlock = (subs, sel, act) ->
    lookforstyle = subs[act].style
    for i = act+1,#subs
        if subs[i].style!=lookforstyle
            return {i-1}
    {#subs}

SelectBlock = (subs, sel, act) ->
    lookforstyle = subs[act].style
    first, last = act, #subs
    for i = act-1,1,-1
        if subs[i].class!='dialogue' or subs[i].style!=lookforstyle
            first = i + 1
            break
    for i = act+1,#subs
        if subs[i].class!='dialogue' or subs[i].style!=lookforstyle
            last = i - 1
            break
    [i for i=first,last]

UntilStart = (subs, sel, act) -> 
	[i for i = 1,act when subs[i].class=='dialogue']

UntilEnd = (subs, sel, act) -> 
	[i for i = act,#subs when subs[i].class=='dialogue']

DependencyControl\registerMacros {
	{ 'Current Style/Select All', '', SelectAll }
	{ 'Current Style/Previous', '', Previous }
	{ 'Current Style/Next', '', Next }
	{ 'Current Style/First In Block', '', FirstInBlock }
	{ 'Current Style/Last In Block', '', LastInBlock }
	{ 'Current Style/Select Block', '', SelectBlock }

	{ 'Select Until Start', '', UntilStart }
	{ 'Select Until End', '', UntilEnd }
}
export script_name        = 'Selegator'
export script_description = 'Select/navigate in the subtitle grid'
export script_author      = 'tophf'
export script_version     = '1.1.5'
export script_namespace   = 'Flux.Selegator'

DependencyControl = require('l0.DependencyControl') {
    url: 'https://github.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts/blob/master/macros/Flux.Selegator.moon'
    feed: 'https://raw.githubusercontent.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts/master/DependencyControl.json'
    {}
}

selectAll = (subs, sel, act) ->
    lookforstyle = subs[act].style
    if #sel>1
        [i for i in *sel when subs[i].style==lookforstyle]
    else
        [k for k,s in ipairs subs when s.style==lookforstyle]

findPrevious = (subs, sel, act) ->
    lookforstyle = subs[act].style
    for i = act-1,1,-1
        return if subs[i].class!='dialogue'
        if subs[i].style==lookforstyle
            return {i}

findNext = (subs, sel, act) ->
    lookforstyle = subs[act].style
    for i = act+1,#subs
        if subs[i].style==lookforstyle
            return {i}

firstInBlock = (subs, sel, act) ->
    lookforstyle = subs[act].style
    for i = act-1,1,-1
        if subs[i].class!='dialogue' or subs[i].style!=lookforstyle
            return {i+1}

lastInBlock = (subs, sel, act) ->
    lookforstyle = subs[act].style
    for i = act+1,#subs
        if subs[i].style!=lookforstyle
            return {i-1}
    {#subs}

selectBlock = (subs, sel, act) ->
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

untilStart = (subs, sel, act) -> 
	[i for i = 1,act when subs[i].class=='dialogue']

untilEnd = (subs, sel, act) -> 
	[i for i = act,#subs when subs[i].class=='dialogue']

DependencyControl\registerMacros {
	{ 'Current Style/Select All', '', selectAll }
	{ 'Current Style/Previous', '', findPrevious }
	{ 'Current Style/Next', '', findNext }
	{ 'Current Style/First In Block', '', firstInBlock }
	{ 'Current Style/Last In Block', '', lastInBlock }
	{ 'Current Style/Select Block', '', selectBlock }

	{ 'Select Until Start', '', untilStart }
	{ 'Select Until End', '', untilEnd }
}
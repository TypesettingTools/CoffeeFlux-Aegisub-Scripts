export script_name        = 'JumpScroll'
export script_description = 'Save and load subtitle grid scrollbar positions on Windows'
export script_author      = 'CoffeeFlux'
export script_version     = '2.0.0'
export script_namespace   = 'Flux.JumpScroll'

DependencyControl = require("l0.DependencyControl") {
    url: "https://github.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts/blob/master/macros/Flux.TitleCase.moon"
    feed: "https://raw.githubusercontent.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts/master/DependencyControl.json"
    {
        {"Flux.ScrollHandler", version: "1.0.0", url: "http://github.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts"},
    }
}

ScrollHandler = rec\requireModules!!

macroLength = 3
Macros = {}

for i = 1, macroLength
	Macros[#Macros + 1] = {'Save/' .. i, '', -> ScrollHandler\savePos i}

for i = 1, macroLength
	Macros[#Macros + 1] = {'Load/' .. i, '', -> ScrollHandler\loadPos i}


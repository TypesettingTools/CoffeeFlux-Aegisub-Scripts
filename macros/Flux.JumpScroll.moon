export script_name        = 'JumpScroll'
export script_description = 'Save and load subtitle grid scrollbar positions on Windows'
export script_author      = 'CoffeeFlux'
export script_version     = '2.1.0'
export script_namespace   = 'Flux.JumpScroll'

DependencyControl = require("l0.DependencyControl") {
    url: "https://github.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts/blob/master/macros/Flux.TitleCase.moon"
    feed: "https://raw.githubusercontent.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts/master/DependencyControl.json"
    {
        {"Flux.ScrollHandler", version: "1.0.0", url: "http://github.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts"},
    }
}

ScrollHandler = DependencyControl\requireModules!!

ConfigHandler = DependencyControl\getConfigHandler {
    Settings: {
        macroLength: 3
    }
}
settings = ConfigHandler.c.Settings

dialog = {
	{
		class: 'label'
		label: 'Macro Length'
		x: 0
		y: 0
	}
	{
		class: 'edit'
		name: 'macroLength'
		x: 2
		y: 0
	}
}

config = ->
	button, results = aegisub.dialog.display dialog
	unless button == 'Cancel'
		Settings.macroLength = results.macroLength
		ConfigHandler\write!

macroLength = settings.macroLength
macros = {
	{ "Configure", "Launches the configuration dialog", config }
}

for i = 1, macroLength
	macros[#macros + 1] = {'Save/' .. i, '', -> ScrollHandler\savePos i}

for i = 1, macroLength
	macros[#macros + 1] = {'Load/' .. i, '', -> ScrollHandler\loadPos i}

DependencyControl\registerMacros macros
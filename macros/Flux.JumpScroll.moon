export script_name        = 'JumpScroll'
export script_description = 'Save and load subtitle grid scrollbar positions'
export script_author      = 'CoffeeFlux'
export script_version     = '2.3.0'
export script_namespace   = 'Flux.JumpScroll'

DependencyControl = require('l0.DependencyControl') {
    url: 'https://github.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts/blob/master/macros/Flux.TitleCase.moon'
    feed: 'https://raw.githubusercontent.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts/master/DependencyControl.json'
    {
        {'Flux.ScrollHandler', version: '1.0.0', url: 'http://github.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts'}
    }
}

ScrollHandler = DependencyControl\requireModules!!

ConfigHandler = DependencyControl\getConfigHandler {
    settings: {
        macroLength: 3
    }
}
-- adjust for change in coding conventions
if ConfigHandler.c.Settings
    ConfigHandler.c.settings = {}
    ConfigHandler.c.settings.macroLength = ConfigHandler.c.Settings.macroLength
    ConfigHandler.c.Settings = nil
    ConfigHandler\write!
settings = ConfigHandler.c.settings

dialog = {
	{
		class: 'label'
		label: 'Macro Length:'
		x: 0
		y: 0
	}
	{
		class: 'intedit'
		name: 'macroLength'
		value: settings.macroLength
		min: 1
		max: 10 -- arbitrary value, but one has to exist to work
		x: 2
		y: 0
	}
}

config = ->
	button, results = aegisub.dialog.display dialog
	unless button == false
		settings.macroLength = results.macroLength
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
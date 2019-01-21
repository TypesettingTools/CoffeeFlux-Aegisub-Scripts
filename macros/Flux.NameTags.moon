export script_name        = 'Name Tags'
export script_description = 'Generate timed name tags based on the Actor field of existing dialogue lines'
export script_author      = 'CoffeeFlux'
export script_version     = '1.0.0'
export script_namespace   = 'Flux.NameTags'

DependencyControl = require('l0.DependencyControl') {
    url: 'https://github.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts/blob/master/macros/Flux.LineSeparator.moon'
    feed: 'https://raw.githubusercontent.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts/master/DependencyControl.json'
    {
        {'a-mo.LineCollection', version: '1.2.0', url: 'https://github.com/TypesettingTools/Aegisub-Motion',
         feed: 'https://raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json'}
        {'l0.ASSFoundation', version: '0.3.3', url: 'https://github.com/TypesettingTools/ASSFoundation',
         feed: 'https://raw.githubusercontent.com/TypesettingTools/ASSFoundation/master/DependencyControl.json'}
    }
}

LineCollection, Line, ASS, Functional = DependencyControl\requireModules!

ConfigHandler = DependencyControl\getConfigHandler {
    settings: {
        styleName: 'Default'
        prefix: '{\\pos(100,100)\\fad(200,200)}'
    }
}
settings = ConfigHandler.c.settings

dialog = {
    {
        class: 'label'
        label: 'Prefix:'
        x: 0
        y: 0
    }
    { -- TODO: make wider
        class: 'edit'
        name: 'prefix'
        text: settings.prefix
        x: 2
        y: 0
    }
    {
        class: 'label'
        label: 'Style Name:'
        x: 0
        y: 1
    }
    {
        class: 'edit'
        name: 'styleName'
        x: 2
        y: 1
    }
}

updateDialog = ->
    dialog[2].text = settings.prefix
    dialog[4].text = settings.styleName

createNameTags = (subs, sel, active) ->
    lines = LineCollection subs, sel

    lines\runCallback (lines, line, progress, i) ->
        if progress == 1
            lines\addLine ASS\createLine {
                comment: true
                text: 'Name Tags'
            }

        if #line.actor > 0 and not line.comment
            lines\addLine ASS\createLine {
                start_time: line.start_time
                end_time: line.end_time
                text: settings.prefix .. line.actor
            }

    lines\insertLines!

config = ->
    button, results = aegisub.dialog.display dialog
    if button
        settings.prefix = results.prefix
        ConfigHandler\write!
        updateDialog!

updateDialog!

DependencyControl\registerMacros {
    { "Create Name Tags", "Does shit", createNameTags }
    { "Configure", "Launches the configuration dialog", config }
}

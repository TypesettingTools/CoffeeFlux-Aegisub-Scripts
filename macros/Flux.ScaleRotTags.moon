-- IF YOU USE THIS SCRIPT BLINDLY AND COMPLAIN TO ME I WILL BLOCK YOU ON EVERYTHING
-- THE OUTPUTTED VALUES WILL STILL BE WRONG AND ARE MATHEMATICALLY IMPOSSIBLE TO FIX
-- THIS IS JUST AN APPROXIMATION FOR THE LAZY AND REQUIRES MANUAL ADJUSTMENT
-- DO NOT USE ORG WITH HIGH VALUES OF FRX/FRY IF AT ALL POSSIBLE WHEN TYPESETTING TO AVOID THIS

export script_name        = 'Scale Rotation Tags (Incorrectly)'
export script_description = 'Adjust frx/fry in lines post-upsample to be less terrible, though still wrong'
export script_author      = 'CoffeeFlux'
export script_version     = '1.1.0'
export script_namespace   = 'Flux.ScaleRotTags'

DependencyControl = require('l0.DependencyControl') {
    {
        {'a-mo.LineCollection', version: '1.1.4', url: 'https://github.com/TypesettingTools/Aegisub-Motion',
         feed: 'https://raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json'}
        {'l0.ASSFoundation', version: '0.3.3', url: 'https://github.com/TypesettingTools/ASSFoundation',
         feed: 'https://raw.githubusercontent.com/TypesettingTools/ASSFoundation/master/DependencyControl.json'}
    }
}

LineCollection, ASSFoundation = DependencyControl\requireModules!

ConfigHandler = DependencyControl\getConfigHandler {
    settings: {
        scaleFactor: 2/3
    }
}
settings = ConfigHandler.c.settings

dialog = {
    {
        class: 'label'
        label: 'Scale Factor:'
        x: 0
        y: 0
    }
    {
        class: 'floatedit'
        name: 'scaleFactor'
        value: settings.scaleFactor
        x: 2
        y: 0
    }
}

config = ->
    button, results = aegisub.dialog.display dialog
    unless button == false
        settings.scaleFactor = results.scaleFactor
        ConfigHandler\write!

scaleRotTags = (sub, sel) ->
    lines = LineCollection sub, sel
    lines\runCallback (lines, line, i) ->
        data = ASSFoundation\parse line
        lazyfix = (tags) ->
            tags\modTags {'angle_x', 'angle_y'}, (tag) ->
                ((tag + 180) % 360 - 180) * settings.scaleFactor
            return true
        data\callback lazyfix, ASSFoundation.Section.Tag
        data\commit!
    lines\replaceLines!

DependencyControl\registerMacros {
    {"Scale Rotation Tags", nil, scaleRotTags},
    {"Config", nil, config}
}

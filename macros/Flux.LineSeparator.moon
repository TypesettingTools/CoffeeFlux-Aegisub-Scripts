export script_name        = 'Line Separator'
export script_description = 'Break apart consecutive lines'
export script_author      = 'CoffeeFlux'
export script_version     = '1.1.0'
export script_namespace   = 'Flux.LineSeparator'

DependencyControl = require('l0.DependencyControl') {
    url: 'https://github.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts/blob/master/macros/Flux.LineSeparator.moon'
    feed: 'https://raw.githubusercontent.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts/master/DependencyControl.json'
    {
        {'a-mo.LineCollection', version: '1.2.0', url: 'https://github.com/TypesettingTools/Aegisub-Motion',
         feed: 'https://raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json'}
    }
}

LineCollection = DependencyControl\requireModules!

ConfigHandler = DependencyControl\getConfigHandler {
    settings: {
        frames: 3
    }
}
settings = ConfigHandler.c.settings

dialog = {
    {
        class: "label"
        label: "Frames:"
        x: 0
        y: 0
    }
    {
        class: "intedit"
        name: "frames"
        value: settings.frames
        min: 1
        max: 99 -- arbitrarily large number
        x: 2
        y: 0
    }
}

updateDialog = ->
    dialog[2].value = settings.frames

separate = (subs, sel, active) ->
    -- Frame info is only available with video or timecodes loaded
    unless aegisub.frame_from_ms 0
        aegisub.log "Line Separator works in frames, so it needs video or timecodes to be loaded.\n"
        aegisub.cancel!

    lines = LineCollection subs, sel
    lines\runCallback (lines, line, i) ->
        unless i == #lines.lines
            endFrame = line.endFrame
            nextLineStartFrame = lines[i + 1].startFrame
            diff = settings.frames - (nextLineStartFrame - endFrame)
            -- Don't shorten a line to zero or negative duration
            if diff <= settings.frames and diff > 0 and endFrame - diff > line.startFrame
               line.end_time = aegisub.ms_from_frame endFrame - diff

    lines\replaceLines!

config = ->
    button, results = aegisub.dialog.display dialog
    if button
        settings.frames = results.frames
        ConfigHandler\write!
        updateDialog!

DependencyControl\registerMacros {
    { "Separate Lines", "Separates lines that're closer than the specified value", separate }
    { "Configure", "Launches the configuration dialog", config }
}

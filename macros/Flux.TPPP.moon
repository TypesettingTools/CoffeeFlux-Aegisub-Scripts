export script_name        = 'Timing Post-Processor Plus'
export script_description = 'Adds leads, links lines and snaps to keyframes, like TPP with extras'
export script_author      = 'CoffeeFlux'
export script_version     = '1.0.0'
export script_namespace   = 'Flux.TPPP'

DependencyControl = require('l0.DependencyControl') {
    url: 'https://github.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts/blob/master/macros/Flux.TPPP.moon'
    feed: 'https://raw.githubusercontent.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts/master/DependencyControl.json'
    {
        {'Flux.TPPPBase', version: '1.0.0', url: 'https://github.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts',
         feed: 'https://raw.githubusercontent.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts/master/DependencyControl.json'}
    }
}

TPPPBase = DependencyControl\requireModules!

-- Defaults follow ShiftCut
ConfigHandler = DependencyControl\getConfigHandler {
    settings: {
        applyTo: 'Selected lines'
        styles: ''
        applyToComments: false
        markChanged: false

        leads: false
        leadIn: 0
        leadOut: 0
        leadsInFrames: false
        leadsPreventOverlap: true
        leadsStayOnKeyframes: false

        link: false
        maxGap: 400
        gapBias: 0.8
        maxOverlap: 500
        overlapBias: 0.5

        snap: false
        startsBefore: 6
        endsBefore: 10
        startsAfter: 8
        endsAfter: 12
        maxCPS: 24
        alwaysSnapWithinFrames: 3
        snapPreventOverlap: true
    }
}
settings = ConfigHandler.c.settings

biasHint = '0 moves the start of the second line, 1 moves the end of the first, 0.5 meets in the middle'

buildDialog = ->
    s = settings
    label = (text, x, y, width = 1) -> {class: 'label', label: text, :x, :y, :width}
    checkbox = (name, text, x, y, width = 2) -> {class: 'checkbox', :name, label: text, value: s[name], :x, :y, :width}
    int = (name, x, y, min = 0, hint) -> {class: 'intedit', :name, value: s[name], :min, max: 99999, :hint, :x, :y}
    bias = (name, x, y) -> {class: 'floatedit', :name, value: s[name], min: 0, max: 1, step: 0.1, hint: biasHint, :x, :y}
    {
        label 'Apply to:', 0, 0
        {class: 'dropdown', name: 'applyTo', items: {'Selected lines', 'All lines'}, value: s.applyTo, x: 1, y: 0}
        label 'Styles:', 2, 0
        {class: 'edit', name: 'styles', text: s.styles, hint: 'Comma-separated style names, leave empty for all styles', x: 3, y: 0, width: 2}
        checkbox 'applyToComments', 'Include commented lines', 0, 1
        checkbox 'markChanged', 'Mark changed lines in Effect', 2, 1, 3

        checkbox 'leads', 'Lead in/out', 0, 3
        label 'Lead-in:', 0, 4
        int 'leadIn', 1, 4, -99999, 'Negative values cut the lead-in'
        label 'Lead-out:', 2, 4
        int 'leadOut', 3, 4, -99999, 'Negative values cut the lead-out'
        checkbox 'leadsInFrames', 'In frames, not ms', 4, 4, 1
        checkbox 'leadsPreventOverlap', 'Prevent overlaps', 0, 5
        checkbox 'leadsStayOnKeyframes', "Don't move times on keyframes", 2, 5, 3

        checkbox 'link', 'Link lines', 0, 7
        label 'Max gap (ms):', 0, 8
        int 'maxGap', 1, 8
        label 'Bias:', 2, 8
        bias 'gapBias', 3, 8
        label 'Max overlap (ms):', 0, 9
        int 'maxOverlap', 1, 9
        label 'Bias:', 2, 9
        bias 'overlapBias', 3, 9

        checkbox 'snap', 'Snap to keyframes (thresholds in frames)', 0, 11, 4
        label 'Starts before:', 0, 12
        int 'startsBefore', 1, 12
        label 'Starts after:', 2, 12
        int 'startsAfter', 3, 12
        label 'Ends before:', 0, 13
        int 'endsBefore', 1, 13
        label 'Ends after:', 2, 13
        int 'endsAfter', 3, 13
        label 'Max CPS:', 0, 14
        {class: 'floatedit', name: 'maxCPS', value: s.maxCPS, min: 0, hint: "Don't make snaps that shorten a line past this CPS, 0 disables", x: 1, y: 14}
        label 'Always snap within:', 2, 14
        int 'alwaysSnapWithinFrames', 3, 14, 0, 'Snaps that shorten a line by this many frames or fewer ignore Max CPS'
        label 'frames', 4, 14
        checkbox 'snapPreventOverlap', 'Prevent overlaps', 0, 15
    }

process = (subs, sel) ->
    button, res = aegisub.dialog.display buildDialog!, {'Apply', 'Cancel'}, {ok: 'Apply', cancel: 'Cancel'}
    aegisub.cancel! unless button
    settings[k] = v for k, v in pairs res
    ConfigHandler\write!

    needsFrames = res.snap or res.leads and (res.leadsInFrames or res.leadsStayOnKeyframes)
    if needsFrames and not aegisub.frame_from_ms 0
        aegisub.log 'Keyframe snapping and frame-based leads need video or timecodes to be loaded.\n'
        aegisub.cancel!

    styles = [style\match '^%s*(.-)%s*$' for style in res.styles\gmatch '[^,]+']
    styles = [style for style in *styles when style != '']

    tppp = TPPPBase subs, sel, styles, res.applyTo == 'Selected lines', res.applyToComments, res.markChanged
    -- Same order as TPP
    if res.leads
        tppp\addLeadIn res.leadIn, res.leadOut, res.leadsPreventOverlap, res.leadsStayOnKeyframes, res.leadsInFrames
    if res.link
        tppp\linkLines res.maxGap, res.gapBias, res.maxOverlap, res.overlapBias
    if res.snap
        tppp\snapToKeyframes res.startsBefore, res.endsBefore, res.startsAfter, res.endsAfter,
            res.maxCPS, res.alwaysSnapWithinFrames, res.snapPreventOverlap
    tppp\commit!

DependencyControl\registerMacro process

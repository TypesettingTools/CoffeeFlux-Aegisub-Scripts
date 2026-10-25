export script_name        = 'Title Case'
export script_description = 'Applies English Title Case to selected lines'
export script_author      = 'tophf'
export script_version     = '1.4.0'
export script_namespace   = 'Flux.TitleCase'

DependencyControl = require('l0.DependencyControl') {
    url: 'https://github.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts/blob/master/macros/Flux.TitleCase.moon'
    feed: 'https://raw.githubusercontent.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts/master/DependencyControl.json'
    {
        'unicode'
    }
}

unicode = DependencyControl\requireModules!

lowerCase = {word, true for word in *{'a', 'an', 'the', 'at', 'by', 'for', 'in', 'of', 'on', 'to', 'up', 'and', 'as', 'but', 'or', 'nor', 'via', 'vs'}}

-- Anything that isn't ASCII punctuation or whitespace, so multibyte characters are always kept whole
wordPattern = "[^`~!@#$%^&*()_=+[%]{};:\"\\|,./<>%s-]+"

-- Multibyte (and apostrophe) punctuation the word pattern can't exclude, which may be attached to either end of a word
leadingPunct = {"'", '‘', '“', '«', '‹', '„', '¿', '¡', '…'}
trailingPunct = {"'", '’', '”', '»', '›', '…'}

-- Splits a token into leading punctuation, the word itself, and trailing punctuation
splitToken = (token) ->
    lead, trail = '', ''
    found = true
    while found and #token > 0
        found = false
        for p in *leadingPunct
            if token\sub(1, #p) == p
                lead ..= p
                token = token\sub #p + 1
                found = true
                break
    found = true
    while found and #token > 0
        found = false
        for p in *trailingPunct
            if #token >= #p and token\sub(-#p) == p
                trail = p .. trail
                token = token\sub 1, -#p - 1
                found = true
                break
    return lead, token, trail

-- Calls fn(word, pending) for each word outside of tags and drawings, where pending is all text since the previous word.
-- fn returns the replacement for the word, or nil to leave it unchanged.
mapWords = (s, fn) ->
    pending, drawing = '', false
    s = ('{}' .. s)\gsub '(%b{})([^{]+)', (tag, text) ->
        for scale in tag\gmatch '\\p(%d+)'
            drawing = tonumber(scale) > 0
        if drawing
            return

        pos = 1
        result = text\gsub '()(' .. wordPattern .. ')()', (first, token, last) ->
            pending ..= text\sub pos, first - 1
            pos = last
            lead, word, trail = splitToken token
            if word == ''
                pending ..= token
                return
            pending ..= lead
            replacement = fn word, pending
            pending = trail
            lead .. (replacement or word) .. trail
        pending ..= text\sub pos
        tag .. result
    return s\sub 3

titleCase = (subs, sel) ->
    for i in *sel
        with line = subs[i]
            -- Make line breaks and hard spaces count as whitespace
            s = .text\gsub('\\N', '\n')\gsub('\\n', '\r')\gsub('\\h', '\f')

            -- Only flatten the case of the rest of each word if the whole line is in caps, to preserve acronyms etc. otherwise
            wordCount, allCaps = 0, true
            mapWords s, (word) ->
                wordCount += 1
                allCaps = false unless unicode.to_upper_case(word) == word
                return

            wordIndex = 0
            s = mapWords s, (word, pending) ->
                wordIndex += 1
                lower = unicode.to_lower_case word
                -- The first and last words, and the first word of each sentence or after a colon, are always capitalized
                if lowerCase[lower] and wordIndex > 1 and wordIndex < wordCount and not pending\match '[.!?:]'
                    return lower
                width = unicode.charwidth word, 1
                first, rest = word\sub(1, width), word\sub(width + 1)
                if allCaps
                    rest = unicode.to_lower_case rest
                -- Leave words like iPhone and eBay alone
                elseif first == unicode.to_lower_case(first) and rest != unicode.to_lower_case(rest)
                    return
                unicode.to_upper_case(first) .. rest

            s = s\gsub('\n', '\\N')\gsub('\r', '\\n')\gsub('\f', '\\h')
            if s != .text
                .text = s
                subs[i] = line

DependencyControl\registerMacro titleCase

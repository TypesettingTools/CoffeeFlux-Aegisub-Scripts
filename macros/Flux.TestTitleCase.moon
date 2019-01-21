export script_name        = 'Title Case'
export script_description = 'Applies English Title Case to selected lines'
export script_author      = 'CoffeeFlux'
export script_version     = '2.0.0'
export script_namespace   = 'Flux.TitleCase'

DependencyControl = require('l0.DependencyControl') {
    url: 'https://github.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts/blob/master/macros/Flux.TitleCase.moon'
    feed: 'https://raw.githubusercontent.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts/master/DependencyControl.json'
    {
        {'a-mo.LineCollection', version: '1.1.4', url: 'https://github.com/TypesettingTools/Aegisub-Motion',
         feed: 'https://raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json'}
        {'l0.ASSFoundation', version: '0.3.3', url: 'https://github.com/TypesettingTools/ASSFoundation',
         feed: 'https://raw.githubusercontent.com/TypesettingTools/ASSFoundation/master/DependencyControl.json'}
        'unicode', 'aegisub.re'
    }
}

LineCollection, ASS, unicode, re = DependencyControl\requireModules!

lowerCaseWords = {'a', 'an', 'the', 'at', 'by', 'for', 'in', 'of', 'on', 'to', 'up', 'and', 'as', 'but', 'or', 'nor', 'via', 'vs'}

-- I'm sorry tp7 ;_;
-- Issues with these: all the slashes may not be properly escaped, this won't get the very first word in the line,
-- won't properly handle em-dashes and probably hyphens etc
firstWord = re.compile '(?:^|(?:[?.;!。~]))(?:\s|\\[Nnh]|{\w+})+[¿¡]?(\p{L})'
everyWord = re.compile '(?:\\[Nnh]|\s|})(\p{L})'

titleCase = (sub, sel) ->
    lines = LineCollection (lines, line, i) ->
        data = ASSFoundation\parse line
        upper = (section) ->
            -- Set every word to uppercase
            section.value = everyWord\sub section.value, (str) ->
                return unicode.to_upper_case str
            -- Fix special words that need to be lowercase
            for word in *lowerCaseWords
                section.value = re.match '(\s|\\N|\\n|{\w+})' .. word .. '(\s|\\N|\\n|{\w+}', word\lower!
            -- Set the first word of every sentence to uppercase
            section.value = firstWord\sub section.value, (str) ->
                return unicode.to_upper_case str
            -- Set the first letter of the sentence to upppercase
            section.value = unicode.to_upper_case(string.sub(section.value, 1, 1)) .. string.sub(section.value, 2)
        data\callback upper, ASSFoundation.Section.Text
        data\commit!
    lines\replaceLines!

DependencyControl\registerMacro titleCase

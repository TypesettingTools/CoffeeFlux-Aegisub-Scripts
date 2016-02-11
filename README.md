CoffeeFlux's Aegisub Scripts
=======================

 1. [Dialog Swapper](#dialog-swapper)
 2. [Title Case](#title-case)
 3. [Selegator](#selegator)
 4. [JumpScroll](#jumpscroll)

----------------------------------


Dialog Swapper
==========================

Dialog Swapper is an automation script for Aegisub that lets you quickly swap between multiple lines of text.

Installation
------------

1. Ensure that depctrl is functional (the easiest way is to use [line0's Aegisub builds](files.line0.eu/builds/Aegisub/))
2. Go to the toolbox, Install Script, locate Dialog Swapper and install it

Usage
------------

Dialog Swapper offers three primary swap operations as well as a number of configuration options.

**Toggle**

The toggle operation comments or uncomments text. This is most commonly used in subs for honorifics.

*Example*

`foo{**-san}` becomes `foo{*}-san{*}`, 
`foo{*}-san{*}` becomes `foo{**-san}`

**Swap**

The swap operation switches between two phrases. This is most commonly used in subs for localization decisions like name order.

*Example*

`{*}Foo Bar{*Bar Foo}` becomes `{*}Bar Foo{*Foo Bar}`,
`{*}Bar Foo{*Foo Bar}` becomes `{*}Foo Bar{*Bar Foo}`

**Comment Toggle**

The comment toggle operation is a special toggle that is used for commenting entire lines. It runs only on lines with the Effect field set to exactly `***`.

Warnings
------------

**Valid Lines**

To avoid swapping lines unintentionally and breaking things (like typesetting), lines will only be swapped when they include a prefix of either "-" or "_" followed by one of the following words: Main, Alt, Overlap.

*Examples*

Valid: Coffee_Main, Flux-Alt, _Overlap

Invalid: Main, _FluxAlt, Overlap-

**Invalid Text**

Be very careful about swapping text that includes the delimeter as its starting character. 
This, as a general rule, breaks things horribly, and is easy enough to avoid and enough of a pain to fix that I'm just leaving in this warning.

Configuration
------------

The above documentation applies to the default settings. Lots of stuff is configurable. I have no input validation, so don't be retarded or things will break. Unicode may also break things.

**Delimeter**

The delimeter is the character used in the brackets for the swap operation. Can only be one character, and it can't be alphanumeric.

Default: *

**Verify Style**

This toggles whether or not the swap operation will only apply to lines with styles that meet the chosen guidelines. Turning it off means your script will run on all lines, regardless of style.

Default: true

**Line Starters**

The line starters are the characters used as a prefix to identify valid line styles. This should be a list of non-alphanumeric characters separated by commas.
Setting this to an empty string will break things. Patches Welcome.

Default: -,_

**Line Names**

The line names are the rest of the name that is checked for when identifying valid lines. This should be a list of alphanumeric words separated by commas. 
Whitespace is not stripped and will be counted as part of the name.

Default: Main,Alt,Overlap


Title Case
==========================

Applies English Title Case (maintains lower case on prepositions and other auxiliary words) to the selected lines.

Installation
------------

1. Ensure that depctrl is functional (the easiest way is to use [line0's Aegisub builds](files.line0.eu/builds/Aegisub/))
2. Go to the toolbox, Install Script, locate Title Case and install it

Usage
------------

Select the relevant lines and run the script. Not too difficult.


Selegator
==========================

Select/navigate in the subtitle grid.

Installation
------------

1. Ensure that depctrl is functional (the easiest way is to use [line0's Aegisub builds](files.line0.eu/builds/Aegisub/))
2. Go to the toolbox, Install Script, locate Title Case and install it

Usage
------------

These are intended to be bound as hotkeys to speed up someone's workflow.

Options are as follows:

* Current Style related:
 * **Current Style/Select All** - select all lines with the same style as the current line
 * **Current Style/Previous** - go to previous line with the same style as the current line
 * **Current Style/Next** - go to next line with the same style as the current line
 * **Current Style/First in Block** - go to the first line in current block of lines with the same style
 * **Current Style/Last in Block** - go to the last line in current block of lines with the same style
 * **Current Style/Select Block** - select all lines in current block of lines with the same style
* **Select Until Start** - unlike built-in Shift-Home, it preserves the active line
* **Select Until End** - unlike built-in Shift-End, it preserves the active line


JumpScroll
==========================

Saves/loads subtitle grid scrollbar position.

Installation
------------

1. Ensure that depctrl is functional (the easiest way is to use [line0's Aegisub builds](files.line0.eu/builds/Aegisub/))
2. Make sure you're running at least Windows 7, either 32-bit or 64-bit
3. Go to the toolbox, Install Script, locate JumpScroll and install it

Usage
------------

These are intended to be bound as hotkeys to speed up someone's workflow. The saves are currently session-only. By default three save slots are created.

Configuration
------------

Soon(tm)
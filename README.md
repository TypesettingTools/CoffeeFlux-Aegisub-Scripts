CoffeeFlux's Aegisub Scripts
=======================

 1. [Dialog Swapper](#Dialog Swapper)

----------------------------------


Dialog Swapper
==========================

Dialog Swapper is an automation script for Aegisub that lets you quickly swap between multiple lines of text.

Requirements
------------
- Aegisub 3.2.0+
- [Dependency Control](https://github.com/TypesettingTools/DependencyControl) 0.5.3+

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

The swap operation switches between two phrases. This is most commonly used in subs for localization.

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

Soon™
DependencyControl = require('l0.DependencyControl') {
	name: 'Timing Post-Processor Plus Base'
	description: 'Aegisub TPP functionality reimplemented lua-side, with added functionality'
	author: 'CoffeeFlux'
	version: '1.0.0'
	moduleName: 'Flux.TPPPBase'
    url: 'https://github.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts/blob/master/modules/Flux.TPPPBase.moon'
    feed: 'https://raw.githubusercontent.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts/master/DependencyControl.json'
    {
        {'a-mo.LineCollection', version: '1.2.0', url: 'https://github.com/TypesettingTools/Aegisub-Motion',
         feed: 'https://raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json'}
        {'l0.ASSFoundation', version: '0.3.3', url: 'https://github.com/TypesettingTools/ASSFoundation',
         feed: 'https://raw.githubusercontent.com/TypesettingTools/ASSFoundation/master/DependencyControl.json'}
    }
}

LineCollection, ASSFoundation = DependencyControl\requireModules!

checkFor = (list, value) ->
	for _, v in ipairs list
		if value == v
			return true
	return false

getLineInfo = (line) ->
	return lines[i - 1], 
	       lines[i + 1], 
	       aegisub.frame_from_ms line.start_time, 
	       aegisub.frame_from_ms line.end_time
	

--- A module reimplementing Aegisub TPP-like functionality lua-side
class TPPPBase
	msgs: {
		--TODO
	}

	--- Creates a class allowing for easy application of TPP functionality
	-- The subs object is only passed at initialization, and thus cannot change until the instance is dereferenced
	-- @tparam Subtitles subs the subtitles object from registration
	-- @tparam Selection sel the selection object from registration
	-- @tparam[opt={}] {Style, ...} styles table of styles to select, an empty table means all
	-- @tparam[opt=true] boolean applyToSelection only process selected lines
	-- @tparam[opt=false] boolean applyToComments only process uncommented lines
	-- @tparam[opt=false] boolean markChanged mark modified lines in the effect field for later inspection
	new: (subs, sel, styles = {}, applyToSelection = true, applyToComments = false, @markChanged = false) =>
		-- consider making this pattern-based
		checkStyle = (line) ->
			if #styles = 0
				return true
			return checkFor styles, line.style

		checkComment = (line) ->
			if applyToComments
				return false
			return line.comment

		if applyToSelection
			@lines = LineCollection subs, sel, -> checkStyle and not checkComment
		else
			@lines = LineCollection\fromAllLines subs, -> checkStyle and not checkComment

		@keyframes = aegisub.keyframes!

	--- Adds lead-in and lead-out to the specified lines
	-- @tparam number leadIn amount of lead-in, in milliseconds
	-- @tparam number leadOut amount of lead-out, in milliseconds
	-- @tparam[opt=false] boolean preventOverlap trim lead-in/out amounts in order to prevent overlap
	-- @tparam[opt=false] boolean stayOnKeyframes don't modify lines already snapped to keyframes
	addLeadIn: (leadIn, leadOut, preventOverlap = false, stayOnKeyframes = false) =>
		@lines\runCallback (lines, line, i) ->
			prevLine, nextLine, startFrame, endFrame = getLineInfo line

			-- Process lead-in
			unless stayOnKeyframes and checkFor @keyframes, startFrame
				newTime = line.start_time - leadIn
				if preventOverlap and prevLine and prevLine.end_time > newTime
					newTime = prevLine.end_time
				if @markChanged and line.start_time != newTime
					line.effect = line.effect .. '[lead-in]'
				line.start_time = newTime

			-- Process lead-out
			unless stayOnKeyframes and checkFor @keyframes, endFrame
				newTime = line.end_time + leadOut
				if preventOverlap and nextLine and nextLine.start_time < newTime
					newTime = prevLine.end_time
				if @markChanged and line.end_time != newTime
					line.effect = line.effect .. '[lead-out]'
				line.end_time = newTime

		@lines\replaceLines!

	linkLines: (maxGap, gapBias, fixOverlap, overlapBias) =>
		@lines\runCallback (lines, line, i) ->
			prevLine = lines[i - 1]
			nextLine = lines[i + 1]
			--shit
		@lines\replaceLines!

	snapToKeyframes: (startsBefore, endsBefore, startsAfter, endsAfter, maxCPS, ignoreMaxThreshold, preventOverlap) =>
		@lines\runCallback (lines, line, i) ->
			prevLine, nextLine, startFrame, endFrame = getLineInfo line

			findCPS = (start, finish, chars) ->
				return (finish - start) * 1000 / chars

			-- This is fairly gross, both because I have to reference upvalues and because of the constant conditionals
			-- Unfortunately, it's 3AM and I want to sleep, I'll deal with it some other time
			findNewTime = (endTime) ->
				-- Handles the case of two keyframes within the limits but in oppposite directions
				-- Currently chooses the closest one to snap to
				local oldMinDiff
				local minDiff
				local origTime
				if endTime
					origTime = line.end_time
				else
					origTime = line.start_time

				for _, v in pairs @keyframes
					frameTime = aegisub.ms_from_frame v
					diff = frameTime - origTime

					-- Snap time
					   -- If it's within one of the thresholds
					if ( diff > startsBefore and diff < 0 or
						 diff < startsAfter and diff > 0 ) and
					   -- If absolute diff is lower or min is unset
					   ( not minDiff or
					   	 math.abs diff < math.abs minDiff )

						oldMinDiff = minDiff
						minDiff = diff
						if endTime
							line.end_time = frameTime
						else
							line.start_time = frameTime

						-- Check for overlap
						if line.end_time > nextLine.start_time or line.start_time < prevLine.end_time
							if endTime and origTime <= nextLine.start_time
								line.end_time = origTime
							else if origTime >= prevLine.end_time
								line.start_time = origTime
							minDiff = oldMinDiff

						-- Check CPS
						checkCPS = (section) ->
							length = #section.value
							if findCPS line.start_time, line.end_time, length > maxCPS
								-- Set back based on the direction moved
								if endTime and findCPS line.start_time, origTime, length < maxCPS
									line.end_time = origTime
								else if findCPS origTime, line.end_time, length < maxCPS
									line.start_time = origTime
								minDiff = oldMinDiff

						data\callback checkCPS, ASSFoundation.Section.Text
						data\commit!

			findNewTime false
			findNewTime true

		@lines\replaceLines!

return DependencyControl\register TPPPBase
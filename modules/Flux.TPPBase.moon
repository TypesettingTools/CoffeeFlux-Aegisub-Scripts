--- A module reimplementing Aegisub TPP-like functionality lua-side.
-- Running this on a batch of lines will sort them by start_time. You've been warned.
-- @classmod TPPBase

DependencyControl = require('l0.DependencyControl') {
	name: 'Timing Post-Processor Base'
	description: 'Aegisub TPP functionality reimplemented lua-side, with added functionality'
	author: 'CoffeeFlux'
	version: '1.0.0'
	moduleName: 'Flux.TPPBase'
    url: 'https://github.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts/blob/master/modules/Flux.TPPBase.moon'
    feed: 'https://raw.githubusercontent.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts/master/DependencyControl.json'
    {
        {'a-mo.LineCollection', version: '1.2.0', url: 'https://github.com/TypesettingTools/Aegisub-Motion',
         feed: 'https://raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json'}
        {'l0.ASSFoundation', version: '0.3.3', url: 'https://github.com/TypesettingTools/ASSFoundation',
         feed: 'https://raw.githubusercontent.com/TypesettingTools/ASSFoundation/master/DependencyControl.json'}
    }
}

LineCollection, ASS = DependencyControl\requireModules!

frameFromMs, msFromFrame = aegisub.frame_from_ms, aegisub.ms_from_frame

checkFor = (list, value) ->
	for _, v in *list
		if value == v
			return true
	return false

class TPPBase
	msgs: {
		new: {
			emptyStyles: "Requires a non-empty styles table"
		}
		addLeadInOut: {
			nullArguments: "Requires a nonzero value for either the leadIn or leadOut"
		}
		linkLines: {
			nullThresholds: "Requires a nonzero value for one of the two thresholds"
			invalidBias: "%s bias requires a value [0..1], was given %f"
		}
		separateLines: {
			invalidThreshold: "Requires a positive value for the threshold, was given %d"
			invalidBias: "Separation bias requires a value [0..1], was given %f"
		}
		snapToKeyframes: {
			noKeyframeData: "Requires keyframe data to be loaded, and at least one entry"
		}
	}

	--- Creates a class allowing for easy application of TPP functionality.
	-- The subs object is only passed at initialization, and thus cannot change until the instance is dereferenced.
	-- @param subs The subtitles object from registration.
	-- @param sel The selection object from registration.
	-- @param styles List of style names to identify lines to process.
	-- @param applyToSelection Flag to only process selected lines. Default: true
	-- @param applyToComments Flag to only process uncommented lines. Default: false
	-- @param markChanged Flag to mark modified lines in the effect field for later inspection. Default: false
	new: (subs, sel, styles, applyToSelection = true, applyToComments = false, @markChanged = false) =>
		assert #styles != 0, msgs.new.emptyStyles

		checkComment = (line) ->
			if applyToComments
				return false
			return line.comment

		validateLine = (line) ->
			validStyle = checkFor styles, line.style
			validComment = checkComment line
			return validStyle and not validComment

		if applyToSelection
			@lines = LineCollection subs, sel, validateLine
		else
			@lines = LineCollection\fromAllLines subs, validateLine

		--TODO: sort @lines

		@keyframes = aegisub.keyframes!

	--- Adds lead-in and lead-out to the specified lines.
	-- @param leadIn Amount of lead-in, specified in milliseconds.
	-- @param leadOut Amount of lead-out, specified in milliseconds.
	-- @param preventOverlap Flag to trim lead-in/out amounts in order to prevent overlap. Default: true
	-- @param stayOnKeyframes Flag to not modify lines already snapped to keyframes. Default: true
	addLeadInOut: (leadIn, leadOut, preventOverlap = true, stayOnKeyframes = true) =>
		return nil, msgs.addLeadInOut.nullArguments if leadIn == 0 and leadOut == 0

		processLine = (lines, line, progress, i) ->
			startFrame, endFrame = aegisub.frame_from_ms(line.start_time), aegisub.frame_from_ms(line.end_time)

			-- Process lead-in
			unless stayOnKeyframes and checkFor(@keyframes, startFrame) or leadIn == 0
				newTime = line.start_time - leadIn
				if preventOverlap and i != 1
					-- Adding lead-in/out erroneously is bad, so we can't just compare with the adjacent line
					-- For lead-in, we can just compare with previous lines since they're sorted by start_time
					for j = i - 1, 1, -1
						prevLine = lines[j]
						if leadIn > 0 and prevLine.end_time > newTime and prevLine.end_time < line.start_time
							newTime = prevLine.end_time
							break
						if leadIn < 0 and prevLine.end_time < newTime and prevLine.end_time > line.start_time
							newTime = prevLine.end_time
							break
				if @markChanged and line.start_time != newTime
					line.effect = line.effect .. '[lead-in]'
				line.start_time = newTime

			-- Process lead-out
			unless stayOnKeyframes and checkFor(@keyframes, endFrame) or leadOut == 0
				newTime = line.end_time + leadOut
				if preventOverlap and i != #lines
					-- Here, we have to compare to every single line for reasons explained above
					for j = #lines, 1, -1
						if j != i
							nextLine = lines[j]
							if leadOut > 0 and nextLine.start_time < newTime and nextLine.start_time > line.end_time
								newTime = nextLine.start_time
								break
							if leadOut < 0 and nextLine.start_time > newTime and nextLine.start_time < line.end_time
								newTime = nextLine.start_time
								break
				if @markChanged and line.end_time != newTime
					line.effect = line.effect .. '[lead-out]'
				line.end_time = newTime

		@lines\runCallback processLine, true
		@lines\replaceLines!
		return true

	--- Connects adjacent lines within a certain threshold.
	-- @param threshold Maximum gap between lines that will be linked, specified in milliseconds.
	-- @param bias Value [0..1] deciding where in the gap the link will occur, 0 being the end of the previous line and 
		-- 1 being the start of the next.
	-- @param overlapThreshold Maximum overlap between linkes that will be linked, specified in milliseconds. 
		-- Default: threshold
	-- @param overlapBias Value [0..1] deciding where in the overlap the link will occur, 0 being the end of the 
		-- previous line and 1 being the start of the next. Default: 1 - bias
	linkLines: (threshold, bias, overlapThreshold = threshold, overlapBias = 1 - bias) =>
		return nil, msgs.linkLines.nullThresholds if threshold == 0 and overlapThreshold == 0
		return nil, msgs.linkLines.invalidBias\format('Linking', bias) if bias > 1 or bias < 0
		return nil, msgs.linkLines.invalidBias\format('Overlap', overlapBias) if overlapBias > 1 or overlapBias < 0

		@lines\runCallback (lines, line, progress, i) ->
			if i == 1 then return
			prevLine = lines[i - 1]
			delta = line.start_time - prevLine.end_time

			-- Process separated lines
			if delta > 0 and delta <= threshold
				linkPoint = prevLine.end_time + math.floor delta * bias
				prevLine.end_time = linkPoint
				line.start_time = linkPoint

			-- Process overlapping lines
			if delta < 0 and -delta <= overlapThreshold
				linkPoint = prevLine.end_time + math.floor delta * overlapBias
				prevLine.end_time = linkPoint
				line.start_time = linkPoint

		@lines\replaceLines!

	--- Ensures all lines are timed a set distance apart. May have strange results with lots of lines timed closely?
	-- This does NOT process overlaps; those need to be dealt with previously.
	-- @param threshold Minimum gap between lines, specified in positive milliseconds.
	-- @param bias Value [0..1] deciding how much each line will be shortened to cause the gap, 0 meaning only the 
		-- previous line will be shortened and 1 meaning the opposite.
	separateLines: (threshold, bias) =>
		return nil, msgs.linkLines.invalidThreshold\format(threshold) if threshold <= 0
		return nil, msgs.linkLines.invalidBias\format(bias) if bias > 1 or bias < 0

		@lines\runCallback (lines, line, progress, i) ->
			if i == 1 then return
			for j = i - 1, 1, -1
				prevLine = lines[j]
				delta = line.start_time - prevLine.end_time
				if delta < threshold and delta >= 0
					prevLine.end_time -= math.floor (threshold - delta) * (1 - bias)
					line.start_time += math.floor (threshold - delta) * bias

		@lines\replaceLines!

	--- Connects lines to nearby keyframes.
	-- @param startsBefore Maximum time before a keyframe in which a line can start to be snapped to it, specified in 
		-- milliseconds.
	-- @param startsAfter Maximum time after a keyframe in which a line can start to be snapped to it, specified in 
		-- milliseconds.
	-- @param endsBefore Maximum time before a keyframe in which a line can end to be snapped to it, specified in 
		-- milliseconds.
	-- @param endsAfter Maximum time after a keyframe in which a line can end to be snapped to it, specified in 
		-- milliseconds.
	-- @param maxCps CPS Value which if the snapped line would exceed, snapping will not occur. A value of zero or less 
		-- will disable this. Default: 0
	-- @param ignoreCpsThreshold Override value for the CPS check, specified in milliseconds. Lines this far away from a
		-- keyframe or less will always be snapped. Default: 125 (1/(24000/1001)*3*1000)
	snapToKeyframes: (startsBefore, startsAfter, endsBefore, endsAfter, maxCps = 0, ignoreCpsThreshold = 125) =>
		return nil, msgs.snapToKeyframes.noKeyframeData unless #@keyframes > 0

		findCps = (start, finish, chars) ->
			return chars * 1000 / (finish - start)

		@lines\runCallback (lines, line, progress, i) ->
			-- Process the start of the line
			prevKFStart, nextKFStart = -1, -1
			unless checkFor @keyframes, line.startFrame
				for i = 1, #@keyframes
					keyframe = @keyframes[i]
					if keyframe < line.startFrame
						prevKFStart = keyframe
					else
						nextKFStart = keyframe
						break

			prevKFStartDelta = line.start_time - msFromFrame(prevKFStart) unless prevKFStart == -1
			nextKFStartDelta = msFromFrame(nextKFStart) - line.start_time unless nextKFStart == -1
			newStartTime = line.start_time

			if prevKFStartDelta and nextKFStartDelta and 
				prevKFStartDelta < startsBefore and nextKFStartDelta < startsAfter
				-- Use closer KF
				if prevKFStartDelta < nextKFStartDelta
					newStartTime = msFromFrame prevKFStart
				else
					newStartTime = msFromFrame nextKFStart
			elseif prevKFStartDelta and prevKFStartDelta < startsBefore
				newStartTime = msFromFrame prevKFStart
			elseif nextKFStartDelta nextKFStartDelta < startsAfter
				newStartTime = msFromFrame nextKFStart

			-- Process the end of the line
			prevKFEnd, nextKFEnd = -1, -1
			unless checkFor @keyframes, line.endFrame
				for i = 1, #@keyframes
					keyframe = @keyframes[i]
					if keyframe < line.endFrame
						prevKFEnd = keyframe
					else
						nextKFEnd = keyframe
						break

			prevKFEndDelta = line.end_time - msFromFrame(prevKFEnd) unless prevKFEnd == -1
			nextKFEndDelta = msFromFrame(nextKFEnd) - line.end_time unless nextKFEnd == -1

			if prevKFEndDelta and nextKFEndDelta and prevKFEndDelta < endsBefore and nextKFEndDelta < endsAfter
				-- Use closer KF
				if prevKFEndDelta < nextKFEndDelta
					newEndTime = msFromFrame prevKFEnd
				else
					newEndTime = msFromFrame nextKFEnd
			elseif prevKFEndDelta and prevKFEndDelta < endsBefore
				newEndTime = msFromFrame prevKFEnd
			elseif nextKFEndDelta and nextKFEndDelta < endsAfter
				newEndTime = msFromFrame nextKFEnd

			-- CPS checks etc
			if line.start_time != newStartTime or line.end_time != newEndTime
				charCount = 0
				data = ASS\parse line
				data\callback ((sect) -> charCount += sect.len), ASS.Section.Text
				cps = findCps newStartTime, newEndTime, charCount

				if maxCps > 0
					if cps < maxCps
						line.start_time = newStartTime
						line.end_time = newEndTime
					elseif math.abs(newStartTime - line.start_time) <= ignoreCpsThreshold
						line.start_time = newStartTime
					elseif math.abs(newEndTime - line.end_time) <= ignoreCpsThreshold
						line.end_time = newEndTime
				else
					line.start_time = newStartTime
					line.end_time = newEndTime

		@lines\replaceLines!

return DependencyControl\register TPPBase

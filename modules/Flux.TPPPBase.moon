DependencyControl = require('l0.DependencyControl') {
	name: 'Timing Post-Processor Plus Base'
	description: 'Aegisub TPP functionality reimplemented lua-side, with added functionality'
	author: 'CoffeeFlux'
	version: '1.0.0'
	moduleName: 'Flux.TPPPBase'
    url: 'https://github.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts/blob/master/modules/Flux.TPPPBase.moon'
    feed: 'https://raw.githubusercontent.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts/master/DependencyControl.json'
    {
        {'a-mo.LineCollection', version: '1.3.0', url: 'https://github.com/TypesettingTools/Aegisub-Motion',
         feed: 'https://raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json'}
        {'l0.ASSFoundation', version: '0.5.0', url: 'https://github.com/TypesettingTools/ASSFoundation',
         feed: 'https://raw.githubusercontent.com/TypesettingTools/ASSFoundation/master/DependencyControl.json'}
    }
}

LineCollection, ASS = DependencyControl\requireModules!

collides = (a, b) ->
	a.start_time < b.end_time and b.start_time < a.end_time

--- A module reimplementing Aegisub TPP-like functionality lua-side
class TPPPBase
	--- Returns the closest keyframes strictly before and strictly after frame, either of which may be nil
	-- @tparam {number, ...} keyframes sorted list of keyframes
	-- @tparam number frame
	@adjacentKeyframes: (keyframes, frame) ->
		lo, hi = 1, #keyframes
		while lo <= hi
			mid = math.floor (lo + hi) / 2
			if keyframes[mid] <= frame
				lo = mid + 1
			else
				hi = mid - 1
		-- keyframes[lo] is now the first keyframe after frame
		before = keyframes[lo - 1]
		before = keyframes[lo - 2] if before == frame
		return before, keyframes[lo]

	--- Finds the keyframe to snap a frame to, or nil if none is within range
	-- If keyframes in both directions are within range, the closest wins, and the earlier one on a tie like TPP.
	-- @tparam {number, ...} keyframes sorted list of keyframes
	-- @tparam number frame
	-- @tparam number maxBefore how many frames frame may be before a keyframe to snap forward to it
	-- @tparam number maxAfter how many frames frame may be after a keyframe to snap back to it
	@closestKeyframe: (keyframes, frame, maxBefore, maxAfter) ->
		before, after = TPPPBase.adjacentKeyframes keyframes, frame
		before = nil if before and frame - before > maxAfter
		after = nil if after and after - frame > maxBefore
		if before and after
			return frame - before <= after - frame and before or after
		return before or after

	--- Creates a class allowing for easy application of TPP functionality
	-- Lines are processed in order of start time, and only lines included here are considered neighbours of each other.
	-- Changes are made to the lines in the collection but not written back; call commit when done.
	-- @tparam Subtitles|LineCollection subs the subtitles object from registration, or a LineCollection to work on
	-- @tparam Selection sel the selection object from registration, ignored when given a LineCollection
	-- @tparam[opt={}] {string, ...} styles names of styles to process, an empty table means all
	-- @tparam[opt=true] boolean applyToSelection only process selected lines, ignored when given a LineCollection
	-- @tparam[opt=false] boolean applyToComments also process commented lines
	-- @tparam[opt=false] boolean markChanged mark modified lines in the effect field for later inspection
	new: (subs, sel, styles = {}, applyToSelection = true, applyToComments = false, @markChanged = false) =>
		styleSet = {style, true for style in *styles}
		isValid = (line) ->
			(applyToComments or not line.comment) and (#styles == 0 or styleSet[line.style])

		-- Aegisub's subtitles object errors on unknown keys, so only look for a class on tables
		@lines = if type(subs) == 'table' and subs.__class == LineCollection
			subs
		elseif applyToSelection
			LineCollection subs, sel, isValid
		else
			LineCollection\fromAllLines subs, isValid

		@sorted = [line for line in *@lines.lines when isValid line]
		for line in *@sorted
			if line.start_time > line.end_time
				error "Line #{line.humanizedNumber} has a negative duration", 0
		table.sort @sorted, (a, b) ->
			if a.start_time == b.start_time
				a.number < b.number
			else
				a.start_time < b.start_time

		@charCounts = setmetatable {}, __mode: 'k'
		@setKeyframes aegisub.keyframes!

	--- Replaces the keyframes used for snapping, e.g. to add the last frame of the video like TPP does
	-- @tparam {number, ...} keyframes list of keyframe frame numbers
	setKeyframes: (keyframes = {}) =>
		@keyframes = [kf for kf in *keyframes]
		table.sort @keyframes
		@isKeyframe = {kf, true for kf in *@keyframes}

	--- Writes all changes back to the subtitles
	commit: =>
		@lines\replaceLines!

	mark: (line, mark) =>
		line.effect ..= "[#{mark}]" if @markChanged

	--- Readable characters per second, ignoring tags, comments, drawings, whitespace and punctuation
	-- @tparam Line line
	-- @tparam[opt=line.start_time] number startTime
	-- @tparam[opt=line.end_time] number endTime
	cps: (line, startTime = line.start_time, endTime = line.end_time) =>
		duration = (endTime - startTime) / 1000
		return math.huge if duration <= 0
		chars = @charCounts[line]
		unless chars
			parts = {}
			collect = (section) ->
				table.insert parts, section.value
				return
			ASS\parse(line)\callback collect, ASS.Section.Text
			text = table.concat(parts)\gsub('\\[Nnh]', ' ')\gsub('[%s%p]', '')
			-- Count UTF-8 characters rather than bytes
			_, chars = text\gsub '[^\128-\191]', ''
			@charCounts[line] = chars
		return chars / duration

	--- Adds lead-in and lead-out to the specified lines
	-- Negative values cut the lead-in/out instead, but never past the other end of the line.
	-- @tparam number leadIn amount of lead-in, in milliseconds or frames
	-- @tparam number leadOut amount of lead-out, in milliseconds or frames
	-- @tparam[opt=true] boolean preventOverlap trim lead-in/out amounts to avoid overlapping lines they didn't already overlap, like TPP
	-- @tparam[opt=false] boolean stayOnKeyframes don't modify starts/ends already snapped to keyframes
	-- @tparam[opt=false] boolean inFrames leadIn and leadOut are in frames rather than milliseconds
	addLeadIn: (leadIn, leadOut, preventOverlap = true, stayOnKeyframes = false, inFrames = false) =>
		if (inFrames or stayOnKeyframes) and not aegisub.frame_from_ms 0
			error 'Leads in frames and staying on keyframes require video or timecodes to be loaded', 0
		shift = (time, amount) ->
			if inFrames
				aegisub.ms_from_frame aegisub.frame_from_ms(time) + amount
			else
				time + amount

		lines = @sorted
		if leadIn != 0
			for i, line in ipairs lines
				continue if stayOnKeyframes and @isKeyframe[aegisub.frame_from_ms line.start_time]
				newStart = math.min shift(line.start_time, -leadIn), line.end_time
				if preventOverlap
					for j = 1, i - 1
						newStart = math.max newStart, lines[j].end_time unless collides line, lines[j]
				if newStart != line.start_time
					line.start_time = newStart
					@mark line, 'lead-in'

		if leadOut != 0
			for i, line in ipairs lines
				continue if stayOnKeyframes and @isKeyframe[aegisub.frame_from_ms line.end_time]
				newEnd = math.max shift(line.end_time, leadOut), line.start_time
				if preventOverlap
					for j = i + 1, #lines
						newEnd = math.min newEnd, lines[j].start_time unless collides line, lines[j]
				if newEnd != line.end_time
					line.end_time = newEnd
					@mark line, 'lead-out'

	--- Links adjacent lines, closing small gaps and fixing small overlaps
	-- Bias works like TPP: 0 moves the start of the second line, 1 moves the end of the first, 0.5 meets in the middle.
	-- @tparam number maxGap maximum gap to close, in milliseconds
	-- @tparam[opt=0.5] number gapBias where to link lines with a gap between them
	-- @tparam[opt=0] number maxOverlap maximum overlap to fix, in milliseconds
	-- @tparam[opt=0.5] number overlapBias where to link overlapping lines
	linkLines: (maxGap, gapBias = 0.5, maxOverlap = 0, overlapBias = 0.5) =>
		lines = @sorted
		for i = 2, #lines
			prev, cur = lines[i - 1], lines[i]
			dist = cur.start_time - prev.end_time
			bias = if dist > 0 and dist <= maxGap
				gapBias
			elseif dist < 0 and -dist <= maxOverlap
				overlapBias
			continue unless bias

			pos = prev.end_time + math.floor dist * bias + 0.5
			-- Fixing an overlap mustn't swallow either line entirely
			continue if pos <= prev.start_time or pos >= cur.end_time
			prev.end_time, cur.start_time = pos, pos
			@mark prev, 'linked'
			@mark cur, 'linked'

	--- Snaps line starts and ends to nearby keyframes
	-- Thresholds are in frames and follow TPP: "starts before" is how far a line may start before a keyframe to be snapped forward to it, and so on.
	-- @tparam number startsBefore threshold in frames
	-- @tparam number endsBefore threshold in frames
	-- @tparam number startsAfter threshold in frames
	-- @tparam number endsAfter threshold in frames
	-- @tparam[opt=0] number maxCPS don't make a snap that shortens a line if that would push it over this CPS, 0 disables
	-- @tparam[opt=3] number alwaysSnapWithinFrames snaps that shorten a line by this many frames or fewer ignore maxCPS
	-- @tparam[opt=true] boolean preventOverlap don't snap into a neighbouring line that wasn't already overlapped
	snapToKeyframes: (startsBefore, endsBefore, startsAfter, endsAfter, maxCPS = 0, alwaysSnapWithinFrames = 3, preventOverlap = true) =>
		unless aegisub.frame_from_ms 0
			error 'Keyframe snapping requires video or timecodes to be loaded', 0
		return if #@keyframes == 0
		frame, ms = aegisub.frame_from_ms, aegisub.ms_from_frame
		lines = @sorted

		-- Work out every snap first, so overlap checks can account for neighbours that also move
		snaps = {}
		for i, line in ipairs lines
			startFrame, endFrame = frame(line.start_time), frame(line.end_time)
			newStartFrame, newEndFrame = startFrame, endFrame

			unless @isKeyframe[startFrame]
				kf = TPPPBase.closestKeyframe @keyframes, startFrame, startsBefore, startsAfter
				newStartFrame = kf if kf and kf < newEndFrame
			unless @isKeyframe[endFrame]
				kf = TPPPBase.closestKeyframe @keyframes, endFrame, endsBefore, endsAfter
				newEndFrame = kf if kf and kf > newStartFrame

			newStart = newStartFrame == startFrame and line.start_time or ms newStartFrame
			newEnd = newEndFrame == endFrame and line.end_time or ms newEndFrame
			if maxCPS > 0
				if newStartFrame - startFrame > alwaysSnapWithinFrames and @cps(line, newStart, line.end_time) > maxCPS
					newStart = line.start_time
				if endFrame - newEndFrame > alwaysSnapWithinFrames and @cps(line, newStart, newEnd) > maxCPS
					newEnd = line.end_time

			snaps[i] = {startTime: newStart, endTime: newEnd}

		if preventOverlap
			for i, line in ipairs lines
				snap, prev, nxt = snaps[i], lines[i - 1], lines[i + 1]
				-- Checking against the neighbours' snapped times lets linked lines snap to the same keyframe together
				if prev and snap.startTime < snaps[i - 1].endTime and line.start_time >= prev.end_time
					snap.startTime = line.start_time
				if nxt and snap.endTime > snaps[i + 1].startTime and line.end_time <= nxt.start_time
					snap.endTime = line.end_time

		for i, line in ipairs lines
			snap = snaps[i]
			if snap.startTime != line.start_time or snap.endTime != line.end_time
				line.start_time, line.end_time = snap.startTime, snap.endTime
				@mark line, 'snapped'

	version: DependencyControl

return DependencyControl\register TPPPBase

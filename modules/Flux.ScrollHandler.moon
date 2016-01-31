export script_name        = 'ScrollHandler'
export script_description = 'Library to save and load subtitle grid scrollbar positions on Windows'
export script_author      = 'CoffeeFlux'
export script_version     = '1.0.0'
export script_namespace   = 'Flux.ScrollHandler'

DependencyControl = require("l0.DependencyControl") {
    url: "https://github.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts/blob/master/modules/Flux.ScrollHandler.moon"
    feed: "https://raw.githubusercontent.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts/master/DependencyControl.json"
    {
    	"ffi"
    }
}

ffi = DependencyControl\requireModules!

if jit.os != 'Windows'
	return

-- WARNING: Hilarious hacks below

ffi.cdef [[
uintptr_t GetForegroundWindow();
uintptr_t SendMessageA(uintptr_t hWnd, uintptr_t Msg, uintptr_t wParam, uintptr_t lParam);
uintptr_t FindWindowExA(uintptr_t hWndParent, uintptr_t hWndChildAfter, uintptr_t lpszClass, uintptr_t lpszWindow);
]]

msgs = {
    WM_VSCROLL: 0x0115
    SBM_SETPOS: 0xE0
    SBM_GETPOS: 0xE1
    SB_THUMBPOSITION: 4
    SB_ENDSCROLL: 8
    SB_SETTEXT: 0x401
}

class ScrollHandler
	new: =>
		@scrollPositions = {}
		@handle = nil

	getHandle: =>
		if not @handle
			@handle = {}
			@handle.App = ffi.C.GetForegroundWindow!
			@handle.Container = ffi.C.FindWindowExA @handle.App, 0, ffi.cast('uintptr_t','wxWindowNR'), 0
			@handle.SubsGrid = ffi.C.FindWindowExA @handle.Container, 0, 0, 0
			@handle.ScrollBar = ffi.C.FindWindowExA @handle.SubsGrid, 0, 0, 0
		@handle.App != 0

	savePos: (key) =>
		return unless @getHandle!
		@scrollPositions[key] = tonumber ffi.C.SendMessageA @handle.ScrollBar, msgs.SBM_GETPOS, 0, 0
		-- aegisub.update_statusbar 'Jumpscroll %s: saved position %d'\format key, @scrollpos[key]

	loadPos: (key) =>
		return unless @scrollPositions[key] and @getHandle!
		ffi.C.SendMessageA @handle.SubsGrid, msgs.WM_VSCROLL, msgs.SB_THUMBPOSITION, @handle.ScrollBar
		ffi.C.SendMessageA @handle.ScrollBar, msgs.SBM_SETPOS, @scrollPositions[key], 0
		ffi.C.SendMessageA @handle.SubsGrid, msgs.WM_VSCROLL, msgs.SB_ENDSCROLL, @handle.ScrollBar
		-- aegisub.update_statusbar 'Jumpscroll %s: scrolled to position %d'\format key, @scrollpos[key]

return DependencyControl\register ScrollHandler
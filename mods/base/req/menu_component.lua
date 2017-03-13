MenuComponentManager = MenuComponentManager or class()
Hooks:RegisterHook("MenuComponentManagerInitialize")
function MenuComponentManager:init()
	self._ws = Overlay:gui():create_screen_workspace()
	self._fullscreen_ws = managers.gui_data:create_fullscreen_16_9_workspace(managers.gui_data)
	managers.gui_data:layout_workspace(self._ws)
	self._main_panel = self._ws:panel():panel()
	self._requested_textures = {}
	self._block_texture_requests = false
	self._REFRESH_FRIENDS_TIME = 5
	self._refresh_friends_t = TimerManager:main():time() + self._REFRESH_FRIENDS_TIME
	self._sound_source = SoundDevice:create_source("MenuComponentManager")
	self._resolution_changed_callback_id = managers.viewport:add_resolution_changed_func(callback(self, self, "resolution_changed"))
	self._preplanning_saved_draws = {}
	self._active_components = {}
	self._alive_components = {}
	Hooks:Call( "MenuComponentManagerInitialize", self )
end

Hooks:RegisterHook("MenuComponentManagerUpdate")
function MenuComponentManager:update(t, dt)
	Hooks:Call( "MenuComponentManagerUpdate", self, t, dt )
end

Hooks:RegisterHook("MenuComponentManagerPreSetActiveComponents")
function MenuComponentManager:set_active_components(components, node)
	Hooks:Call( "MenuComponentManagerPreSetActiveComponents", self, components, node )
	if not alive(self._ws) or not alive(self._fullscreen_ws) then
		return 
	end
	local to_close = {}
	for component,_ in pairs(self._active_components) do
		to_close[component] = true
	end
	for _,component in ipairs(components) do
		if self._active_components[component] then
			to_close[component] = nil
			self._active_components[component].create(node)
		end
	end
	for component,_ in pairs(to_close) do
		self._active_components[component]:close()
	end
	if not managers.menu:is_pc_controller() then
		self:_setup_controller_input()
	end
end

Hooks:RegisterHook("MenuComponentManagerOnMousePressed")
function MenuComponentManager:mouse_pressed(o, button, x, y )
	local full_16_9_size = managers.gui_data:full_16_9_size()
	x, y = x - full_16_9_size.convert_x, y - full_16_9_size.convert_y
	if Hooks:ReturnCall("MenuComponentManagerOnMousePressed", self, o, button, x, y) then
		return true
	end
	return false
end

Hooks:RegisterHook("MenuComponentManagerOnMouseMoved")
function MenuComponentManager:mouse_moved( o, x, y )
	local full_16_9_size = managers.gui_data:full_16_9_size()
	x, y = x - full_16_9_size.convert_x, y - full_16_9_size.convert_y
	return Hooks:ReturnCall("MenuComponentManagerOnMouseMoved", self, o, x, y)
end

function MenuComponentManager:post_event(event)
	managers.menu:post_event(event)
end

function MenuComponentManager:resolution_changed()
	managers.gui_data:layout_workspace(self._ws)
	managers.gui_data:layout_fullscreen_16_9_workspace(managers.gui_data, self._fullscreen_ws)
end

function MenuComponentManager:close()
	for _,component in pairs(self._active_components) do
		component:close()
	end
end

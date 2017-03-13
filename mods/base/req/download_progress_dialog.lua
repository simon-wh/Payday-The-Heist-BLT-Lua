
local LuaModUpdates = _G.LuaModUpdates
core:module("SystemMenuManager")
require("lib/managers/dialogs/GenericDialog")
DownloadProgressDialog = DownloadProgressDialog or class(GenericDialog)
local make_fine_text = function(text)
	local x, y, w, h = text:text_rect()
	text:set_size(w, h)
	text:set_position(math.round(text:x()), math.round(text:y()))
end

function DownloadProgressDialog:init(manager, data, is_title_outside)

	Dialog.init(self, manager, data)
	if not self._data.focus_button then
		if #self._button_text_list > 0 then
			self._data.focus_button = #self._button_text_list
		else
			self._data.focus_button = 1
		end
	end
	self._ws = self._data.ws or manager:_get_ws()
	local text_config = {
		title_font = data.title_font,
		title_font_size = data.title_font_size,
		font = data.font,
		font_size = data.font_size,
		w = data.w or 420,
		h = data.h or 400,
		no_close_legend = true,
		no_scroll_legend = true,
		use_indicator = data.indicator or data.no_buttons,
		is_title_outside = is_title_outside,
		use_text_formating = data.use_text_formating,
		text_formating_color = data.text_formating_color,
		text_formating_color_table = data.text_formating_color_table,
		text_blend_mode = data.text_blend_mode
	}
	self._panel = self._ws:panel():gui(Idstring("guis/dialog_manager"))
	self._panel:hide()
	self._panel_script = self._panel:script()
	local orig = self._panel_script.setup
	self._panel_script.setup = function(this, data)
		orig(this, data)
		self:_create_text_box()
	end
	self._panel_script:setup(self._data)
	self._panel_script:set_fade(0)


	self._controller = self._data.controller or manager:_get_controller()
	self._confirm_func = callback(self, self, "button_pressed_callback")
	self._cancel_func = callback(self, self, "dialog_cancel_callback")
	self._resolution_changed_callback = callback(self, self, "resolution_changed_callback")
	managers.viewport:add_resolution_changed_func(self._resolution_changed_callback)
	if data.counter then
		self._counter = data.counter
		self._counter_time = self._counter[1]
	end
	self._sound_event = data.sound_event

	LuaModUpdates:RegisterDownloadDialog( self )

end

function DownloadProgressDialog:_create_text_box()
	local small_text = {
		text = "",
		layer = 1,
		font = _G.tweak_data.menu.small_font,
		font_size = _G.tweak_data.menu.small_font_size,
	}
	local medium_text = {
		text = "",
		layer = 1,
		font = _G.tweak_data.menu.default_font,
		font_size = _G.tweak_data.menu.default_font_size,
	}

	local progress_text = self._panel:text(medium_text)
	progress_text:set_position(10, self._panel:child("title"):bottom() + 30)
	progress_text:set_text("000%")
	make_fine_text(progress_text)

	local progress_bg = self._panel:rect({
		h = progress_text:h(),
		color = Color.black,
		alpha = 0.4,
		layer = 1
	})
	progress_bg:set_position(progress_text:right() + 4, progress_text:top())
	progress_bg:set_w(self._panel:w() - progress_bg:left() - 30)

	local progress_bar = self._panel:rect({
		color = Color.white,
		alpha = 1,
		layer = 2,
	})
	progress_bar:set_shape(progress_bg:shape())
	progress_bar:set_w(0)
	progress_bar:grow(0, -4)
	progress_bar:move(2, 0)
	progress_bar:set_center_y(progress_bg:center_y())

	local progress_end = self._panel:rect({
		color = Color.white,
		alpha = 1,
		layer = 3,
	})
	progress_end:set_shape(progress_bg:shape())
	progress_end:set_w(2)
	progress_end:grow(0, -4)
	progress_end:set_center_y(progress_bg:center_y())
	progress_end:set_right(progress_bg:right())

	local download_amt_text = self._panel:text(small_text)
	download_amt_text:set_text(managers.localization:text("base_mod_download_download_progress"))
	make_fine_text(download_amt_text)
	download_amt_text:set_position(progress_bg:left(), progress_bg:bottom() + 2)

	self._panel:set_y(math.round(self._panel:y()))
	local this = self._panel_script
	this._anim_data = {
		progress_bar = progress_bar,
		progress_text = progress_text,
		download_amt_text = download_amt_text,

		start_progress_width = 0,
		progress_width = 0,
		end_progress_width = progress_end:right() - progress_bar:left(),

		bytes_downloaded = 0,
		bytes_total = 0,
	}
	self._thread = self._panel:animate(callback(this, self, "_update"))
end

function DownloadProgressDialog:button_pressed_callback()
	self._download_complete = self._panel_script._anim_data.download_complete
	if self._download_complete then
		DownloadProgressDialog.super.button_pressed_callback(self)
	end
end

function DownloadProgressDialog:dialog_cancel_callback()
	self._download_complete = self._panel_script._anim_data.download_complete
	if self._download_complete then
		DownloadProgressDialog.super.dialog_cancel_callback(self)
	end
end

function DownloadProgressDialog:fade_in()
	DownloadProgressDialog.super.fade_in(self)
	self._start_sound_t = self._sound_event and TimerManager:main():time() + 0.2
end

function DownloadProgressDialog:_update()
	local init_done = false
	while not init_done do
		init_done = not not self._anim_data
		coroutine.yield()
	end
	--wait(1)
	-- managers.menu_component:post_event("count_1")
	-- Download Progress
	while self._anim_data and not self._anim_data.mod_download_complete and not self._anim_data.mod_download_failed do
		coroutine.yield()
		local bytes_down = math.round(self._anim_data.bytes_downloaded / 1024)
		local bytes_total = math.round(self._anim_data.bytes_total / 1024)
		local bytes_tbl = {
			["downloaded"] = bytes_down,
			["total"] = bytes_total
		}
		local t = 0
		if self._anim_data.bytes_downloaded > 0 and self._anim_data.bytes_total > 0 then
			t = self._anim_data.bytes_downloaded / self._anim_data.bytes_total
		end
		self._anim_data.progress_width = math.lerp(self._anim_data.start_progress_width, self._anim_data.end_progress_width, t)
		self._anim_data.progress_bar:set_width(self._anim_data.progress_width)

		self._anim_data.progress_text:set_text( string.format("%000.f %%", t * 100) )
		self._anim_data.download_amt_text:set_text( managers.localization:text("base_mod_download_download_progress", bytes_tbl) )

	end

	managers.menu_component:post_event("count_1_finished")

	-- Extract Progress
	self._anim_data.download_amt_text:set_text( managers.localization:text("base_mod_download_download_progress_extract") )
	make_fine_text( self._anim_data.download_amt_text )

	while self._anim_data and not self._anim_data.mod_extraction_complete and not self._anim_data.mod_download_failed do
		coroutine.yield()
	end

	managers.menu_component:post_event("count_1_finished")

	-- Download Complete or Failed
	if not self._anim_data.mod_download_failed then
		-- Complete
		self._anim_data.download_amt_text:set_text( managers.localization:text("base_mod_download_download_progress_complete") )
		make_fine_text( self._anim_data.download_amt_text )
	else
		-- Failed
		self._anim_data.download_amt_text:set_text( managers.localization:text("base_mod_download_download_progress_failed") )
		make_fine_text( self._anim_data.download_amt_text )
	end

	self._anim_data.progress_bar:set_width( not self._anim_data.mod_download_failed and self._anim_data.end_progress_width or 0 )
	self._anim_data.download_complete = true	
end

function DownloadProgressDialog:update(t, dt)
	DownloadProgressDialog.super.update(self, t, dt)
	if self._start_sound_t and t > self._start_sound_t then
		managers.menu_component:post_event(self._sound_event)
		self._start_sound_t = nil
	end
end

function DownloadProgressDialog:fade_out_close()
	self._download_complete = self._panel_script._anim_data.download_complete
	if self._download_complete then
		self:fade_out()
	end
	managers.menu:post_event("prompt_exit")
end

function DownloadProgressDialog:remove_mouse()
	if not self._download_complete then
		return
	end
	if not self._removed_mouse then
		self._removed_mouse = true
		if managers.controller:get_default_wrapper_type() == "pc" then
			managers.mouse_pointer:remove_mouse(self._mouse_id)
		else
			managers.mouse_pointer:enable()
		end
		self._mouse_id = nil
	end
end

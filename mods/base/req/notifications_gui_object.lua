
NotificationsGuiObject = NotificationsGuiObject or class()
NotificationsGuiObject._edge_padding = 6

local HIGHLIGHT_VISIBLE = 1
local HIGHLIGHT_INVISIBLE = 0
local VISIBILITY_THRESHOLD = 0.001
local CHANGE_NOTIF_THRESHOLD = 0.15
local HIGHLIGHT_PADDING = 2
local NORMAL_COLOR
local HIGHLIGHT_COLOR
local MARKER_COLOR

function NotificationsGuiObject:init(ws)
	local panel = ws:panel():panel({layer = tweak_data.gui.DIALOG_LAYER})
	NORMAL_COLOR = tweak_data.menu.default_font_row_item_color
	HIGHLIGHT_COLOR = tweak_data.menu.default_hightlight_row_item_color
	MARKER_COLOR = tweak_data.menu.highlight_background_color_left
	local font = tweak_data.menu.default_font
	local small_font = tweak_data.menu.small_font
	local font_size = tweak_data.hud.default_font_size - 8
	local small_font_size = tweak_data.hud.small_font_size
	local max_left_len = 0
	local max_right_len = 0
	local extra_w = font_size * 4
	local icon_size = 16

	local highlight_rect = panel:rect({
		name = "highlight",
		color = MARKER_COLOR,
		alpha = HIGHLIGHT_INVISIBLE,
		layer = 0,
	})

	local highlight_left_rect = panel:rect({
		name = "highlight_left",
		color = MARKER_COLOR,
		alpha = HIGHLIGHT_INVISIBLE,
		layer = 0,
	})

	local highlight_right_rect = panel:rect({
		name = "highlight_right",
		color = MARKER_COLOR,
		alpha = HIGHLIGHT_INVISIBLE,
		layer = 0,
	})

	local update_icon = panel:bitmap({
		texture = "guis/textures/icon_star",
		w = icon_size,
		h = icon_size,
		texture_rect = {1, 7, 16, 16},
		x = 20,
		y = 10,
		color = NORMAL_COLOR:with_alpha(0),
		layer = 2
	})
	extra_w = extra_w - icon_size

	local heat_glow = panel:bitmap({
		texture = "guis/textures/pd2/hot_cold_glow",
		layer = 1,
		alpha = 0,
		w = 32,
		h = 32,
		color = Color.yellow:with_alpha(0),
	})
	heat_glow:set_center(10 + icon_size / 2 - 4, 10 + icon_size / 2)

	local focus = ws:panel():bitmap({
		name = "focus",
		texture = "guis/textures/crimenet_map_circle",
		layer = 10,
		color = Color.white:with_alpha(0),
		w = 0,
		h = 0,
	})
	focus:set_center(10 + icon_size / 2 - 4, 10 + icon_size / 2)

	local notification_title_text = panel:text({
		font = font,
		font_size = font_size,
		text = managers.localization:text("base_mod_notifications_none"),
		y = 10,
		color = NORMAL_COLOR
	})
	self:_make_fine_text(notification_title_text)
	notification_title_text:set_left(math.round(update_icon:right()))
	max_left_len = math.max(max_left_len, notification_title_text:w())

	local notification_message_text = panel:text({
		text = "",
		font_size = font_size,
		font = font,
		color = NORMAL_COLOR
	})
	self:_make_fine_text(notification_message_text)
	notification_message_text:set_left(math.round(update_icon:right()))
	notification_message_text:set_top(math.round(notification_title_text:bottom()))
	max_left_len = math.max(max_left_len, notification_message_text:w())

	local font_scale = 1

	local prev_notification_text = panel:text({
		font = small_font,
		font_size = small_font_size,
		text = managers.localization:text("base_mod_notifications_prev"),
		x = 10,
		y = 10,
		color = NORMAL_COLOR:with_alpha( 0.3 )
	})
	self:_make_fine_text(prev_notification_text)

	local next_notification_text = panel:text({
		font = small_font,
		font_size = small_font_size,
		text = managers.localization:text("base_mod_notifications_next"),
		x = 10,
		y = 10,
		color = NORMAL_COLOR:with_alpha( 0.3 )
	})
	self:_make_fine_text(next_notification_text)

	local notification_count_text = panel:text({
		font = font,
		font_size = font_size * 0.8,
		text = managers.localization:text("base_mod_notifications_count", {["current"] = 1, ["max"] = 1}),
		x = 10,
		y = 10,
		color = NORMAL_COLOR:with_alpha( 0.3 )
	})
	self:_make_fine_text(notification_count_text)

	self._panel = panel

	self:_rec_round_object(panel)

	self._highlight_rect = highlight_rect
	self._highlight_left_rect = highlight_left_rect
	self._highlight_right_rect = highlight_right_rect
	self._heat_glow = heat_glow
	self._focus = focus
	self._update_icon = update_icon
	self._notification_title_text = notification_title_text
	self._notification_message_text = notification_message_text
	self._max_left_len = max_left_len
	self._max_right_len = max_right_len

	self._prev_notification_text = prev_notification_text
	self._next_notification_text = next_notification_text
	self._notification_count_text = notification_count_text

	self._hovering_on_notification = false

	self:LoadNotifications()
	self:reposition_and_resize()
end

function NotificationsGuiObject:reposition_and_resize()
	local max_w = 200
	for i, panel in ipairs(self._panel:children()) do
		if CoreClass.type_name(panel) == "Text" and panel ~= self._prev_notification_text and panel ~= self._next_notification_text then
			local w = panel:x() + panel:w()
			if max_w < w then
				max_w = w
			end		 
		end
	end
	self._panel:set_size(max_w + 8, math.max(self._notification_message_text:bottom(), 10) + 8)
	self._panel:set_bottom(self._panel:parent():h() - 70)
end

function NotificationsGuiObject:_rec_round_object(object)
	local x, y, w, h = object:shape()
	object:set_shape(math.round(x), math.round(y), math.round(w), math.round(h))
	if object.children then
		for i, d in ipairs(object:children()) do
			self:_rec_round_object(d)
		end
	end
end

function NotificationsGuiObject:get_text(text, macros)
	return utf8.to_upper(managers.localization:text(text, macros))
end

function NotificationsGuiObject:_make_fine_text(text)
	local x, y, w, h = text:text_rect()
	text:set_size(w, h)
	text:set_position(math.round(text:x()), math.round(text:y()))
end

function NotificationsGuiObject:close()

	if self._panel and alive(self._panel) then

		if self._focus and alive(self._focus) then
			self._panel:parent():remove( self._focus )
			self._focus = nil
		end

		self._panel:parent():remove(self._panel)
		self._panel = nil

	end

end

function NotificationsGuiObject:LoadNotifications()

	local notifs = NotificationsManager:GetNotifications()
	if #notifs < 1 then

		self._notification_title_text:set_text( managers.localization:text("base_mod_notifications_none") )
		self._notification_message_text:set_text( "" )
		self:update()

	else

		local notif = NotificationsManager:GetCurrentNotification()
		if self._panel and alive(self._panel) then

			self._notification_title_text:set_text( notif.title )
			self._notification_message_text:set_text( notif.message )

			self._update_icon:set_color( Color.white:with_alpha(notif.read and 0 or 1) )
			self._heat_glow:set_color( Color.yellow:with_alpha(notif.read and 0 or 0.7) )

			self:update()

			DelayedCalls:Add("MarkNotificationAsRead", 0.2, function()
				NotificationsManager:MarkNotificationAsRead( notif.id )
			end)

		end

	end

end

function NotificationsGuiObject:update()
	if not alive(self._panel) then
		return 
	end

	local update_icon = self._update_icon
	local notification_title_text = self._notification_title_text
	local notification_message_text = self._notification_message_text

	if alive(update_icon) and alive(notification_title_text) and alive(notification_message_text) then

		self:_make_fine_text(notification_title_text)
		notification_title_text:set_left(math.round(update_icon:right()))
		self._max_left_len = math.max(self._max_left_len, notification_title_text:w())

		self:_make_fine_text(notification_message_text)
		notification_message_text:set_left(math.round(update_icon:right()))
		notification_message_text:set_top(math.round(notification_title_text:bottom()))
		self._max_left_len = math.max(self._max_left_len, notification_message_text:w())

		self:reposition_and_resize()
	end

	local prev_notification_text = self._prev_notification_text
	local next_notification_text = self._next_notification_text
	local notification_count_text = self._notification_count_text

	if alive(prev_notification_text) and alive(next_notification_text) and alive(notification_count_text) then

		local padding = self._edge_padding
		local alpha = #NotificationsManager:GetNotifications() > 1 and 1 or 0

		prev_notification_text:set_left( padding )
		prev_notification_text:set_top( self._panel:h() / 2 - prev_notification_text:h() / 2 )
		prev_notification_text:set_alpha( alpha )

		next_notification_text:set_right( self._panel:w() - padding )
		next_notification_text:set_top( self._panel:h() / 2 - next_notification_text:h() / 2 )
		next_notification_text:set_alpha( alpha )

		notification_count_text:set_left( padding )
		notification_count_text:set_bottom( self._panel:h() - padding )
		notification_count_text:set_alpha( alpha )

		local current = NotificationsManager:GetCurrentNotificationIndex()
		local num_notifs = #NotificationsManager:GetNotifications()
		notification_count_text:set_text( managers.localization:text("base_mod_notifications_count", {["current"] = current, ["max"] = num_notifs}) )

	end

	local highlight_rect = self._highlight_rect
	local highlight_left_rect = self._highlight_left_rect
	local highlight_right_rect = self._highlight_right_rect

	if alive(highlight_rect) and alive(highlight_left_rect) and alive(highlight_right_rect) then
		
		local panel = self._panel

		highlight_rect:set_h( panel:h() - HIGHLIGHT_PADDING * 2 )
		highlight_rect:set_w( panel:w() - HIGHLIGHT_PADDING * 2 )
		highlight_rect:set_top( HIGHLIGHT_PADDING )
		highlight_rect:set_left( HIGHLIGHT_PADDING )

		local bars_w = prev_notification_text:w() + 8

		highlight_left_rect:set_h( panel:h() - HIGHLIGHT_PADDING * 2 )
		highlight_left_rect:set_w( bars_w )
		highlight_left_rect:set_top( HIGHLIGHT_PADDING )
		highlight_left_rect:set_left( HIGHLIGHT_PADDING )

		highlight_right_rect:set_h( panel:h() - HIGHLIGHT_PADDING * 2 )
		highlight_right_rect:set_w( bars_w )
		highlight_right_rect:set_top( HIGHLIGHT_PADDING )
		highlight_right_rect:set_right( panel:right() - HIGHLIGHT_PADDING )

	end

end

function NotificationsGuiObject:SetHighlightVisibility( highlight, visible )

	if visible then
		if highlight:alpha() < HIGHLIGHT_VISIBLE - VISIBILITY_THRESHOLD then
			highlight:set_alpha( HIGHLIGHT_VISIBLE )
			managers.menu_component:post_event("highlight")
		end
	else
		if highlight:alpha() > HIGHLIGHT_INVISIBLE + VISIBILITY_THRESHOLD then
			highlight:set_alpha( HIGHLIGHT_INVISIBLE )
		end
	end

end

Hooks:Add("MenuComponentManagerOnMousePressed", "Base_ModUpdates_MenuComponentManagerOnMousePressed", function( menu, o, button, x, y )
	local gui = menu._notifications_gui
	if gui and alive(gui._panel) and gui._panel:inside(x, y) then
		if #NotificationsManager:GetNotifications() > 1 then
			if gui._highlight_left_rect:inside(x,y) then
				NotificationsManager:ShowPreviousNotification()
				gui:LoadNotifications()		
				return true	
			elseif gui._highlight_right_rect:inside(x,y) then
				NotificationsManager:ShowNextNotification()
				gui:LoadNotifications()
				return true
			end
		end
		NotificationsManager:ClickNotification()
		return true
	end
end)

Hooks:Add("MenuComponentManagerOnMouseMoved", "Base_ModUpdates_MenuComponentManagerOnMouseMoved", function( menu, o, x, y )
	local gui = menu._notifications_gui
	if gui and alive(gui._panel) then

		local highlighted = false
		local multiple_notifs = #NotificationsManager:GetNotifications() > 1
		local highlight_visible = false
		if multiple_notifs then

			-- Next notification highlight
			local highlight_right_rect = gui._highlight_right_rect
			if alive( highlight_right_rect ) then
				local highlight_visible = highlight_right_rect:inside( x, y )
				highlighted = highlighted or highlight_visible
				gui:SetHighlightVisibility( highlight_right_rect, highlight_visible )
				gui._next_notification_text:set_color(highlight_visible and HIGHLIGHT_COLOR or NORMAL_COLOR)
			end

			-- Previous notification highlight
			local highlight_left_rect = gui._highlight_left_rect
			if alive( highlight_left_rect ) then
				local highlight_visible = highlight_left_rect:inside( x, y )	
				if highlighted then
					highlight_visible = false
				end
				highlighted = highlighted or highlight_visible
				gui:SetHighlightVisibility( highlight_left_rect, highlight_visible )
				gui._prev_notification_text:set_color(highlight_visible and HIGHLIGHT_COLOR or NORMAL_COLOR)
			end

		end

		-- Clickable area highlight
		local highlight_rect = gui._highlight_rect
		if alive( highlight_rect ) then

			local current_notif = NotificationsManager:GetCurrentNotification()
			--local x_percent = ( x - gui._panel:x() ) / gui._panel:w()
			if not highlight_visible then
				highlight_visible = highlight_rect:inside( x, y )
			end
			if highlighted or (current_notif and not current_notif.callback) then
				highlight_visible = false
			end

			gui:SetHighlightVisibility( highlight_rect, highlight_visible )
			local col = highlight_visible and HIGHLIGHT_COLOR or NORMAL_COLOR
			gui._notification_count_text:set_color(col)
			gui._notification_title_text:set_color(col)
			gui._notification_message_text:set_color(col)
			gui._update_icon:set_color(col)
			if highlight_visible then
				gui._next_notification_text:set_color(HIGHLIGHT_COLOR)
				gui._prev_notification_text:set_color(HIGHLIGHT_COLOR)
			end		
			highlighted = highlighted or highlight_visible
		end

		gui._hovering_on_notification = highlighted
		if highlighted then
			return true, "link"
		else
			if alive(highlight_rect) and highlight_rect:inside( x, y ) then
				return true, "arrow"
			end
		end
	end
end) 

Hooks:Add("LogicOnSelectNode", "Base_ModUpdates_LogicOnSelectNode", function()
	local node = managers.menu:active_menu().logic:selected_node()
	if node and node._default_item_name and node._default_item_name ~= "crimenet" then
		if managers.menu_component and managers.menu_component._notifications_gui then
			managers.menu_component._notifications_gui:close()
		end
	end
end)

Hooks:Add("NotificationManagerOnNotificationsUpdated", "NotificationManagerOnNotificationsUpdated_NotificationsGUI", function(notify, notifications)
	if managers.menu_component and managers.menu_component._notifications_gui then
		managers.menu_component._notifications_gui:LoadNotifications()
	end
end)
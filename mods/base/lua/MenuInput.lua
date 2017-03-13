CloneClass(MenuInput)
function MenuInput:mouse_pressed(o, button, x, y, ...)
	self.orig.mouse_pressed(self, o, button, x, y, ...)
	managers.menu_component:mouse_pressed(o, button, x, y)
end
function MenuInput:mouse_moved(o, x, y, ...)
	self.orig.mouse_moved(self, o, x, y, ...)
	managers.menu_component:mouse_moved(o, x, y)
end
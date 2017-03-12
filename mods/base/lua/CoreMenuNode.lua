core:module("CoreMenuNode")
core:import("CoreSerialize")
core:import("CoreMenuItem")
core:import("CoreMenuItemToggle")
MenuNode = MenuNode or class()
function MenuNode:insert_item(item, i)
	item.dirty_callback = callback(self, self, "item_dirty")
	if self.callback_handler then
		item:set_callback_handler(self.callback_handler)
	end
	table.insert(self._items, i, item)
end
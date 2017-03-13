
local Hooks = Hooks
local CloneClass = CloneClass
core:module("CoreMenuLogic")

CloneClass( Logic )

Hooks:RegisterHook("LogicOnSelectNode")

function Logic:select_node(node_name, queue, ...)
	self.orig.select_node(self, node_name, queue, ...)
	Hooks:Call( "LogicOnSelectNode", self, node_name, queue, ... )
end

function Logic:_select_node(node_name, ...)
	self.orig._select_node(self, node_name, ...)
	local node = self:get_node(node_name, ...)
	if node then
		if managers.menu._open_menus and #managers.menu._open_menus > 0 and node then
			managers.menu_component:set_active_components({}, node)
		end
	end
end

function Logic:_navigate_back(...)	
	self.orig._navigate_back(self, ...)
	local node = self._node_stack[#self._node_stack]
	if node then
		managers.menu_component:set_active_components({}, node)
	end
end

function Logic:close(...)
	managers.menu_component:set_active_components({})
	self.orig.close(self, ...)
end
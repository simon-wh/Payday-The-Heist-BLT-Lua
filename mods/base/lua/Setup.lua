Hooks:PreHook(Setup, "init_managers", "base_pre_init_managers", function(self, managers)
	managers.gui_data = GuiDataManager:new()
end)
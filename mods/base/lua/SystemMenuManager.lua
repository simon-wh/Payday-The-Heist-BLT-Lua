
core:module("SystemMenuManager")
--require("lib/managers/dialogs/SpecializationDialog")

GenericSystemMenuManager.GENERIC_DOWNLOAD_PROGRESS_CLASS = DownloadProgressDialog
GenericSystemMenuManager.DOWNLOAD_PROGRESS_CLASS = DownloadProgressDialog

function GenericSystemMenuManager:show_download_progress( data )
	local success = self:_show_class(data, self.GENERIC_DOWNLOAD_PROGRESS_CLASS, self.DOWNLOAD_PROGRESS_CLASS, data.force)
	self:_show_result(success, data)
end

function GenericSystemMenuManager:_show_result(success, data)
	if not success and data then
		local default_button_index = data.focus_button or 1
		local button_list = data.button_list
		if data.button_list then
			local button_data = data.button_list[default_button_index]
			if button_data then
				local callback_func = button_data.callback_func
				if callback_func then
					callback_func(default_button_index, button_data)
				end
			end
		end
		if data.callback_func then
			data.callback_func(default_button_index, data)
		end
	end
end
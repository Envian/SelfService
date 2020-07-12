-- This file is part of SelfService.
--
-- SelfService is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- SelfService is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with SelfService.  If not, see <https://www.gnu.org/licenses/>.
local ADDON_NAME, ns = ...;

function ns.showControlPanel()
	SelfService_ControlPanel:Show();
end

function ns.closeControlPanel()
	SelfService_ControlPanel:Hide();
end

function ns.toggleControlPanel()

end


-- Events
SelfService_ControlPanel_Header_CloseButton:SetScript("OnClick", ns.closeControlPanel);

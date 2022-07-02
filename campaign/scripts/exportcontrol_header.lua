--
-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.
--

local updateOriginal;
function onInit()
	updateOriginal = super.update;
	super.update = update;
	super.onInit();
end

function update()
	if updateOriginal then
		updateOriginal();
		local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());
		exportcontrol.setReadOnly(bReadOnly);
	end
end
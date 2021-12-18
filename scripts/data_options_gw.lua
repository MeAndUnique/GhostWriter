-- 
-- Please see the license file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	OptionsManager.registerOption2("GWDE", true, "option_header_GW", "option_label_GWDE", "option_entry_cycler", 
		{ labels="option_val_export_player", values="player", baselabel="option_val_export_gm", baseval="gm", default="gm" });
end
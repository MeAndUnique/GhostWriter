-- 
-- Please see the license.txt file included with this distribution for 
-- attribution and copyright information.
--

local addExportNodeOriginal;
local performExportOriginal;

local bPlayerVisible;
local recordTypePlayerDefault = {};
local nodeChaptersBackup = nil;
local removedPages = {};

function onInit()
	addExportNodeOriginal = ExportManager.addExportNode;
	ExportManager.addExportNode = addExportNode;

	performExportOriginal = ExportManager.performExport;
	ExportManager.performExport = performExport;

	ExportManager.registerPostExportCallback(cleanupChaptersPostExport);
end

function performExport(wExport)
	bPlayerVisible = (wExport.playervisible.getValue() == 1);
	for _,wRecordType in ipairs(wExport.recordtypes.getWindows()) do
		recordTypePlayerDefault[wRecordType.getExportType()] = wRecordType.playerdefault.getValue();
	end
	performExportOriginal(wExport);
end

function addExportNode(nodeSource, sTargetPath, sExportType, sExportLabel, sExportListClass, sExportRootPath)
	if ReferenceManualManager.MANUAL_DEFAULT_INDEX .. "." .. ReferenceManualManager.MANUAL_DEFAULT_CHAPTER_LIST_NAME == sTargetPath then
		handleChaptersNode(nodeSource);
	elseif not checkForExport(nodeSource, sExportType) then
		if sExportType == "referencemanualpage" then
			removedPages[nodeSource.getPath()] = true;
		end
		return;
	end

	addExportNodeOriginal(nodeSource, sTargetPath, sExportType, sExportLabel, sExportListClass, sExportRootPath);
end

function checkForExport(nodeSource, sExportType)
	local sExport = DB.getValue(nodeSource, "exportcontrol");
	if (sExport or "") == "" then
		if recordTypePlayerDefault[sExportType] then
			sExport = "player";
		else
			sExport = "gm";
		end
	end
	return (sExport == "both") or (bPlayerVisible == (sExport == "player"));
end

function handleChaptersNode(nodeChapters)
	if next(removedPages) == nil then
		return;
	end

	nodeChaptersBackup = DB.createNode("exportChaptersBackup");
	DB.copyNode(nodeChapters, nodeChaptersBackup);

	local chaptersToRemove = {};
	for _,nodeChapter in pairs(DB.getChildren(nodeChapters)) do
		local subChaptersToRemove = {};
		local bHasSubChapters = false;
		for _,nodeSubChapter in pairs(DB.getChildren(nodeChapter, "subchapters")) do
			local pagesToRemove = {};
			local bHasPages = false;
			for _,nodePage in pairs(DB.getChildren(nodeSubChapter, "refpages")) do
				local _,sRecord = DB.getValue(nodePage, "listlink", "", "");
				if removedPages[sRecord] then
					table.insert(pagesToRemove, nodePage);
				else
					bHasPages = true;
				end
			end

			if bHasPages then
				bHasSubChapters = true;
				for _,nodePage in ipairs(pagesToRemove) do
					DB.deleteNode(nodePage);
				end
			else
				table.insert(subChaptersToRemove, nodeSubChapter)
			end
		end

		if bHasSubChapters then
			for _,nodeSubChapter in ipairs(subChaptersToRemove) do
				DB.deleteNode(nodeSubChapter);
			end
		else
			table.insert(chaptersToRemove, nodeChapter);
		end
	end

	for _,nodeChapter in ipairs(chaptersToRemove) do
		DB.deleteNode(nodeChapter);
	end
end

function cleanupChaptersPostExport(sRecordType, tRecords)
	if nodeChaptersBackup then
		DB.deleteNode(ReferenceManualManager.MANUAL_DEFAULT_INDEX .. "." .. ReferenceManualManager.MANUAL_DEFAULT_CHAPTER_LIST_NAME);
		local nodeChapters = DB.createNode(ReferenceManualManager.MANUAL_DEFAULT_INDEX .. "." .. ReferenceManualManager.MANUAL_DEFAULT_CHAPTER_LIST_NAME);
		DB.copyNode(nodeChaptersBackup, nodeChapters);
		DB.deleteNode(nodeChaptersBackup);
		nodeChaptersBackup = nil;
	end

	removedPages = {};
end
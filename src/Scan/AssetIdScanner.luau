-- Carga plugins públicos del Creator Store por AssetId (Studio / plugins)

local ServerStorage = game:GetService("ServerStorage")

export type AssetPluginInfo = {
	id: string,
	assetId: number,
	name: string,
	origin: string,
	scriptCount: number,
	root: Instance,
}

export type FetchResult = {
	ok: boolean,
	plugin: AssetPluginInfo?,
	errorMessage: string?,
}

local SCAN_FOLDER_NAME = "PluginGuard_Scan"

local function countScripts(root: Instance): number
	local n = 0
	if root:IsA("LuaSourceContainer") then
		n += 1
	end
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("LuaSourceContainer") then
			n += 1
		end
	end
	return n
end

local function getScanFolder(): Folder
	local existing = ServerStorage:FindFirstChild(SCAN_FOLDER_NAME)
	if existing and existing:IsA("Folder") then
		return existing
	end
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = SCAN_FOLDER_NAME
	folder.Parent = ServerStorage
	return folder
end

local function parseAssetIds(rawText: string): { number }
	local seen: { [number]: boolean } = {}
	local ids: { number } = {}

	for token in string.gmatch(rawText, "[^%s,;]+") do
		local asNumber = tonumber(token)
		if asNumber == nil then
			local fromUrl = string.match(token, "(%d%d%d%d%d+)")
			asNumber = if fromUrl then tonumber(fromUrl) else nil
		end
		if asNumber and asNumber > 0 and not seen[asNumber] then
			seen[asNumber] = true
			table.insert(ids, asNumber)
		end
	end

	return ids
end

local function fetchOne(assetId: number): FetchResult
	local folder = getScanFolder()
	local childName = ("Asset_%d"):format(assetId)

	local previous = folder:FindFirstChild(childName)
	if previous then
		previous:Destroy()
	end

	local ok, objectsOrErr = pcall(function()
		return game:GetObjects("rbxassetid://" .. tostring(assetId))
	end)

	if not ok then
		return {
			ok = false,
			errorMessage = ("No se pudo descargar %d: %s"):format(assetId, tostring(objectsOrErr)),
		}
	end

	local objects = objectsOrErr
	if typeof(objects) ~= "table" or #objects == 0 then
		return {
			ok = false,
			errorMessage = ("AssetId %d no devolvió instancias (privado, borrado o vacío)."):format(assetId),
		}
	end

	local container: Instance
	if #objects == 1 then
		container = objects[1]
	else
		container = Instance.new("Folder")
		for _, obj in ipairs(objects) do
			obj.Parent = container
		end
	end

	local displayName = container.Name
	if displayName == "" or displayName == "Folder" then
		displayName = ("Asset %d"):format(assetId)
	end
	container.Name = childName
	container.Parent = folder

	local scriptCount = countScripts(container)
	local info: AssetPluginInfo = {
		id = ("asset:%d"):format(assetId),
		assetId = assetId,
		name = displayName,
		origin = ("AssetId %d"):format(assetId),
		scriptCount = scriptCount,
		root = container,
	}

	if scriptCount == 0 then
		return {
			ok = false,
			plugin = info,
			errorMessage = ("AssetId %d cargó, pero no tiene scripts legibles."):format(assetId),
		}
	end

	return {
		ok = true,
		plugin = info,
	}
end

local function fetchMany(rawText: string): {
	ok: { AssetPluginInfo },
	errors: { string },
}
	local ids = parseAssetIds(rawText)
	local okList: { AssetPluginInfo } = {}
	local errors: { string } = {}

	if #ids == 0 then
		table.insert(errors, "No se encontró ningún AssetId válido.")
		return { ok = okList, errors = errors }
	end

	for _, assetId in ipairs(ids) do
		local result = fetchOne(assetId)
		if result.plugin then
			table.insert(okList, result.plugin)
		end
		if not result.ok then
			table.insert(errors, result.errorMessage or ("Error con AssetId %d"):format(assetId))
		end
	end

	return { ok = okList, errors = errors }
end

local function clearScanFolder()
	local existing = ServerStorage:FindFirstChild(SCAN_FOLDER_NAME)
	if existing then
		existing:Destroy()
	end
end

return {
	parseAssetIds = parseAssetIds,
	fetchOne = fetchOne,
	fetchMany = fetchMany,
	getScanFolder = getScanFolder,
	clearScanFolder = clearScanFolder,
}

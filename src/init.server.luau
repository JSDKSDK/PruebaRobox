-- PluginGuard — entry (pestañas Debug / AssetId + motor de reglas)

local MainPanel = require(script:WaitForChild("UI"):WaitForChild("MainPanel"))
local DebugScanner = require(script:WaitForChild("Scan"):WaitForChild("DebugScanner"))
local AssetIdScanner = require(script:WaitForChild("Scan"):WaitForChild("AssetIdScanner"))
local Orchestrator = require(script:WaitForChild("Scan"):WaitForChild("Orchestrator"))
local Types = require(script:WaitForChild("Rules"):WaitForChild("Types"))

local toolbar = plugin:CreateToolbar("PluginGuard")
local auditButton = toolbar:CreateButton(
	"Auditar",
	"Abrir el panel de auditoría de plugins",
	""
)
auditButton.ClickableWhenViewportHidden = true

local panel = MainPanel.create(plugin)
panel.widget.Enabled = false

local rootsById: { [string]: Instance } = {}
local metaById: { [string]: { name: string, origin: string } } = {}
local lastResults: { [string]: any } = {}
local assetEntriesById: { [string]: any } = {}
local lastDebugPlugins: { any } = {}

local function buildFindingRows(result: any): { any }
	local rows = {}
	for _, finding in ipairs(result.findings) do
		table.insert(rows, {
			severity = finding.severity,
			title = ("[%s] %s"):format(Types.severityLabel(finding.severity), finding.ruleId),
			body = ("%s\nScript: %s\n%s"):format(finding.message, finding.scriptPath, finding.snippet),
		})
	end
	return rows
end

local function formatFindingsHeader(result: any): string
	local lines = {
		("Plugin: %s"):format(result.pluginName),
		("Origen: %s"):format(result.origin),
		("Scripts OK: %d · fallidos: %d"):format(result.scriptsScanned, result.scriptsFailed),
		("Badge: %s"):format(Types.badgeLabel(result.badge)),
	}

	if #result.findings == 0 then
		table.insert(lines, "")
		table.insert(lines, "Sin hallazgos con las reglas actuales.")
		table.insert(lines, "Eso no garantiza que sea seguro.")
	else
		table.insert(lines, "")
		table.insert(lines, ("Hallazgos (%d):"):format(#result.findings))
	end

	return table.concat(lines, "\n")
end

local function applyResultToUi(result: any)
	lastResults[result.pluginId] = result
	panel.updateEntryBadge(result.pluginId, Types.badgeLabel(result.badge))

	local high, medium = 0, 0
	for _, f in ipairs(result.findings) do
		if f.severity == "high" then
			high += 1
		elseif f.severity == "medium" then
			medium += 1
		end
	end

	panel.showScanResult(
		("Resultado: %s\n%d críticos · %d revisar · %d hallazgos"):format(
			Types.badgeLabel(result.badge),
			high,
			medium,
			#result.findings
		),
		formatFindingsHeader(result),
		buildFindingRows(result)
	)
end

local function toUiEntries(sourceList: { any }): { any }
	local entries = {}
	for _, info in ipairs(sourceList) do
		local previous = lastResults[info.id]
		table.insert(entries, {
			id = info.id,
			name = info.name,
			origin = info.origin,
			scriptCount = info.scriptCount,
			badge = if previous then Types.badgeLabel(previous.badge) else "—",
		})
	end
	table.sort(entries, function(a, b)
		return string.lower(a.name) < string.lower(b.name)
	end)
	return entries
end

local function refreshAssetTab()
	local list = {}
	for _, entry in pairs(assetEntriesById) do
		table.insert(list, entry)
	end
	local ui = toUiEntries(list)
	panel.setAssetEntries(
		ui,
		if #ui == 0 then "No hay AssetIds.\nUsa + AssetId para agregar." else nil
	)
end

local function refreshDebugList()
	panel.setStatus("Estado: Buscando en PluginDebugService…")

	local result = DebugScanner.scan()
	lastDebugPlugins = result.plugins

	for id in pairs(rootsById) do
		if string.sub(id, 1, 6) == "debug:" then
			rootsById[id] = nil
			metaById[id] = nil
		end
	end

	for _, info in ipairs(result.plugins) do
		rootsById[info.id] = info.root
		metaById[info.id] = { name = info.name, origin = info.origin }
	end

	for id, entry in pairs(assetEntriesById) do
		if entry.root and entry.root.Parent then
			rootsById[id] = entry.root
			metaById[id] = { name = entry.name, origin = entry.origin }
		end
	end

	local debugUi = toUiEntries(result.plugins)
	panel.setDebugEntries(debugUi, result.message)
	refreshAssetTab()

	local assetCount = 0
	for _ in pairs(assetEntriesById) do
		assetCount += 1
	end

	if result.debugLikelyEnabled then
		panel.setDebugLabel(
			("Plugin Debugging: activo\nDebug: %d · AssetId: %d"):format(#result.plugins, assetCount),
			true
		)
	else
		panel.setDebugLabel(
			"Plugin Debugging: vacío/inactivo\nUsa la pestaña AssetId si quieres",
			false
		)
	end

	local tab = panel.getActiveTab()
	if tab == "debug" then
		panel.setStatus(("Estado: pestaña Debug · %d plugin(s)"):format(#result.plugins))
	else
		panel.setStatus(("Estado: pestaña AssetId · %d item(s)"):format(assetCount))
	end

	print("[PluginGuard]", result.message)
end

local function addAssetIds(rawText: string)
	panel.setStatus("Estado: descargando AssetId…")
	local result = AssetIdScanner.fetchMany(rawText)

	for _, info in ipairs(result.ok) do
		assetEntriesById[info.id] = {
			id = info.id,
			name = info.name,
			origin = info.origin,
			scriptCount = info.scriptCount,
			root = info.root,
		}
		rootsById[info.id] = info.root
		metaById[info.id] = { name = info.name, origin = info.origin }
	end

	refreshAssetTab()
	panel.setActiveTab("asset")

	if #result.errors > 0 then
		panel.setStatus(("Estado: %d ok · %d error(es)"):format(#result.ok, #result.errors))
		panel.showScanResult(
			("AssetId: %d agregados, %d con error"):format(#result.ok, #result.errors),
			table.concat(result.errors, "\n")
		)
	else
		panel.setStatus(("Estado: %d AssetId en pestaña AssetId"):format(#result.ok))
		panel.showScanResult(
			("Se agregaron %d AssetId."):format(#result.ok),
			"Estás en la pestaña AssetId.\nSelecciona uno y pulsa Escanear este."
		)
	end

	print("[PluginGuard] AssetId ok=", #result.ok, "errors=", #result.errors)
end

local function clearWorkingList()
	local tab = panel.getActiveTab()

	if tab == "asset" then
		table.clear(assetEntriesById)
		for id in pairs(rootsById) do
			if string.sub(id, 1, 6) == "asset:" then
				rootsById[id] = nil
				metaById[id] = nil
				lastResults[id] = nil
			end
		end
		AssetIdScanner.clearScanFolder()
		refreshAssetTab()
		panel.setSelected(nil)
		panel.showScanResult(
			"Pestaña AssetId limpia.",
			"Se quitaron AssetIds y ServerStorage.PluginGuard_Scan."
		)
		panel.setStatus("Estado: AssetId limpiados")
		print("[PluginGuard] Limpió pestaña AssetId")
		return
	end

	-- En Debug: limpia solo badges/resultados de debug (no puede “borrar” plugins instalados)
	for id in pairs(lastResults) do
		if string.sub(id, 1, 6) == "debug:" then
			lastResults[id] = nil
		end
	end
	refreshDebugList()
	panel.setSelected(nil)
	panel.showScanResult(
		"Resultados Debug limpiados.",
		"Los plugins locales siguen instalados; solo se resetearon badges de esta pestaña.\nPara quitar AssetIds, ve a la pestaña AssetId → Limpiar lista."
	)
	panel.setStatus("Estado: resultados Debug limpiados")
	print("[PluginGuard] Limpió resultados Debug")
end

local function scanSelected()
	local entry = panel.getSelected()
	if entry == nil then
		panel.setStatus("Estado: selecciona un plugin primero")
		return
	end

	local root = rootsById[entry.id]
	if root == nil or root.Parent == nil then
		panel.setStatus("Estado: no hay root (re-agrega AssetId o Re-escanea Debug)")
		return
	end

	panel.setStatus(("Estado: escaneando %s…"):format(entry.name))
	local result = Orchestrator.scanTarget({
		pluginId = entry.id,
		pluginName = entry.name,
		origin = entry.origin,
		root = root,
	})
	applyResultToUi(result)
	panel.setStatus(("Estado: escaneo listo — %s"):format(entry.name))
	print(("[PluginGuard] Scan %s → %s (%d findings)"):format(entry.name, result.badge, #result.findings))
end

local function scanAll()
	local tab = panel.getActiveTab()
	local prefix = if tab == "debug" then "debug:" else "asset:"

	local targets = {}
	for id, root in pairs(rootsById) do
		local meta = metaById[id]
		if meta and root and root.Parent and string.sub(id, 1, #prefix) == prefix then
			table.insert(targets, {
				pluginId = id,
				pluginName = meta.name,
				origin = meta.origin,
				root = root,
			})
		end
	end

	if #targets == 0 then
		panel.setStatus("Estado: no hay plugins en esta pestaña")
		return
	end

	panel.setStatus(("Estado: escaneando pestaña %s (%d)…"):format(tab, #targets))
	local results = Orchestrator.scanMany(targets)

	local critical, review, okCount = 0, 0, 0
	for _, result in ipairs(results) do
		applyResultToUi(result)
		if result.badge == "critical" then
			critical += 1
		elseif result.badge == "review" then
			review += 1
		elseif result.badge == "ok" then
			okCount += 1
		end
	end

	local selected = panel.getSelected()
	if selected and lastResults[selected.id] then
		applyResultToUi(lastResults[selected.id])
	else
		panel.showScanResult(
			("Pestaña %s: %d🔴 · %d🟡 · %d🟢"):format(tab, critical, review, okCount),
			"Escaneo de la pestaña terminado.\nSelecciona un plugin para ver su detalle."
		)
	end

	panel.setStatus(
		("Estado: pestaña %s lista — %d🔴 · %d🟡 · %d🟢"):format(tab, critical, review, okCount)
	)
	print("[PluginGuard] Scan tab", tab, #results)
end

panel.onRescan(function()
	if panel.getActiveTab() == "asset" then
		refreshAssetTab()
		panel.setStatus("Estado: pestaña AssetId actualizada")
	else
		refreshDebugList()
	end
end)
panel.onAssetIdSubmit(addAssetIds)
panel.onClearList(clearWorkingList)
panel.onTabChanged(function(tab)
	panel.setSelected(nil)
	if tab == "debug" then
		panel.showScanResult(
			"Pestaña Debug",
			"Aquí solo ves plugins locales (PluginDebugService).\nSelecciona uno y escanea."
		)
		panel.setStatus(("Estado: pestaña Debug · %d"):format(#lastDebugPlugins))
	else
		local n = 0
		for _ in pairs(assetEntriesById) do
			n += 1
		end
		panel.showScanResult(
			"Pestaña AssetId",
			"Aquí solo ves lo que agregaste con + AssetId.\nNo se mezclan con Debug."
		)
		panel.setStatus(("Estado: pestaña AssetId · %d"):format(n))
	end
end)
panel.onSelect(function(entry)
	local previous = lastResults[entry.id]
	if previous then
		applyResultToUi(previous)
	else
		panel.showScanResult(
			"Sin escaneo aún para este plugin.",
			("Nombre: %s\nOrigen: %s\nPestaña: %s\n\nPulsa Escanear este."):format(
				entry.name,
				entry.origin,
				panel.getActiveTab()
			)
		)
	end
end)
panel.onScanSelected(scanSelected)
panel.onScanAll(scanAll)

auditButton.Click:Connect(function()
	panel.widget.Enabled = not panel.widget.Enabled
	if panel.widget.Enabled then
		refreshDebugList()
	end
end)

print("[PluginGuard] Cargado — pestañas Debug / AssetId")

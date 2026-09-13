-- PluginGuard — entry (UI + Debug list + Rules engine)

local MainPanel = require(script:WaitForChild("UI"):WaitForChild("MainPanel"))
local DebugScanner = require(script:WaitForChild("Scan"):WaitForChild("DebugScanner"))
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

local function formatFindingsDetail(result: any): string
	local lines = {
		("Plugin: %s"):format(result.pluginName),
		("Origen: %s"):format(result.origin),
		("Scripts OK: %d · fallidos: %d"):format(result.scriptsScanned, result.scriptsFailed),
		("Badge: %s"):format(Types.badgeLabel(result.badge)),
		"",
	}

	if #result.findings == 0 then
		table.insert(lines, "Sin hallazgos con las reglas actuales.")
		table.insert(lines, "Eso no garantiza que sea seguro.")
		return table.concat(lines, "\n")
	end

	table.insert(lines, ("Hallazgos (%d):"):format(#result.findings))
	for _, finding in ipairs(result.findings) do
		table.insert(
			lines,
			("• [%s] %s — %s"):format(
				Types.severityLabel(finding.severity),
				finding.ruleId,
				finding.message
			)
		)
		table.insert(lines, ("  Script: %s"):format(finding.scriptPath))
		table.insert(lines, ("  %s"):format(finding.snippet))
		table.insert(lines, "")
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
		formatFindingsDetail(result)
	)
end

local function refreshDebugList()
	panel.setStatus("Estado: Buscando en PluginDebugService…")

	local result = DebugScanner.scan()
	table.clear(rootsById)
	table.clear(metaById)

	local entries = {}
	for _, info in ipairs(result.plugins) do
		rootsById[info.id] = info.root
		metaById[info.id] = { name = info.name, origin = info.origin }

		local previous = lastResults[info.id]
		table.insert(entries, {
			id = info.id,
			name = info.name,
			origin = info.origin,
			scriptCount = info.scriptCount,
			badge = if previous then Types.badgeLabel(previous.badge) else "—",
		})
	end

	panel.setPluginList(entries, result.message)

	if result.debugLikelyEnabled then
		panel.setDebugLabel(
			("Plugin Debugging: parece activo\n%d plugin(s) listados"):format(#entries),
			true
		)
		panel.setStatus(("Estado: %d plugin(s) listados"):format(#entries))
	else
		panel.setDebugLabel(
			"Plugin Debugging: no se ven plugins\nActiva Plugin Debugging Enabled y reinicia Studio",
			false
		)
		panel.setStatus("Estado: Debug vacío / inactivo")
	end

	print("[PluginGuard]", result.message)
end

local function scanSelected()
	local entry = panel.getSelected()
	if entry == nil then
		panel.setStatus("Estado: selecciona un plugin primero")
		return
	end

	local root = rootsById[entry.id]
	if root == nil then
		panel.setStatus("Estado: no hay root para ese plugin")
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
	local targets = {}
	for id, root in pairs(rootsById) do
		local meta = metaById[id]
		if meta then
			table.insert(targets, {
				pluginId = id,
				pluginName = meta.name,
				origin = meta.origin,
				root = root,
			})
		end
	end

	if #targets == 0 then
		panel.setStatus("Estado: no hay plugins para escanear")
		return
	end

	panel.setStatus(("Estado: escaneando %d plugin(s)…"):format(#targets))
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

	-- Si hay selección, muestra su detalle; si no, resumen global
	local selected = panel.getSelected()
	if selected and lastResults[selected.id] then
		applyResultToUi(lastResults[selected.id])
	else
		panel.showScanResult(
			("Todos: %d🔴 · %d🟡 · %d🟢"):format(critical, review, okCount),
			"Escaneo de todos terminado.\nSelecciona un plugin para ver su detalle."
		)
	end

	panel.setStatus(
		("Estado: todos listos — %d🔴 · %d🟡 · %d🟢"):format(critical, review, okCount)
	)
	print("[PluginGuard] Scan all done", #results)
end

panel.onRescan(refreshDebugList)
panel.onAddAssetId(function()
	panel.setStatus("Estado: + AssetId (próximamente)")
end)
panel.onSelect(function(entry)
	local previous = lastResults[entry.id]
	if previous then
		applyResultToUi(previous)
	else
		panel.showScanResult(
			"Sin escaneo aún para este plugin.",
			("Nombre: %s\nOrigen: %s\n\nPulsa Escanear este."):format(entry.name, entry.origin)
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

print("[PluginGuard] Cargado — listar Debug + motor de reglas (Catalog en claro)")

-- Panel 3 columnas + API de listado/escaneo

export type PluginListEntry = {
	id: string,
	name: string,
	origin: string,
	scriptCount: number?,
	badge: string?,
}

export type PanelHandles = {
	widget: DockWidgetPluginGui,
	setStatus: (text: string) -> (),
	setDebugLabel: (text: string, ok: boolean?) -> (),
	setPluginList: (entries: { PluginListEntry }, emptyMessage: string?) -> (),
	setSelected: (entry: PluginListEntry?) -> (),
	getSelected: () -> PluginListEntry?,
	updateEntryBadge: (pluginId: string, badge: string) -> (),
	showScanResult: (summaryText: string, detailText: string) -> (),
	onRescan: (callback: () -> ()) -> (),
	onAddAssetId: (callback: () -> ()) -> (),
	onSelect: (callback: (entry: PluginListEntry) -> ()) -> (),
	onScanSelected: (callback: () -> ()) -> (),
	onScanAll: (callback: () -> ()) -> (),
}

local function color(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local COLORS = {
	bg = color(30, 30, 30),
	panel = color(40, 40, 40),
	panelAlt = color(45, 45, 45),
	text = color(230, 230, 230),
	muted = color(160, 160, 160),
	accent = color(0, 162, 255),
	button = color(55, 55, 55),
	buttonHover = color(70, 70, 70),
	row = color(50, 50, 50),
	rowSelected = color(0, 90, 140),
	ok = color(80, 180, 100),
	warn = color(220, 180, 60),
}

local function applyCorner(parent: Instance, radius: number?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 4)
	c.Parent = parent
end

local function applyPadding(parent: Instance, px: number)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, px)
	p.PaddingBottom = UDim.new(0, px)
	p.PaddingLeft = UDim.new(0, px)
	p.PaddingRight = UDim.new(0, px)
	p.Parent = parent
end

local function makeLabel(parent: Instance, text: string, size: UDim2, bold: boolean?): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = size
	label.Font = if bold then Enum.Font.GothamBold else Enum.Font.Gotham
	label.TextSize = 14
	label.TextColor3 = COLORS.text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.TextWrapped = true
	label.Text = text
	label.Parent = parent
	return label
end

local function makeButton(parent: Instance, text: string, size: UDim2): TextButton
	local button = Instance.new("TextButton")
	button.Size = size
	button.BackgroundColor3 = COLORS.button
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Font = Enum.Font.GothamMedium
	button.TextSize = 14
	button.TextColor3 = COLORS.text
	button.Text = text
	button.Parent = parent
	applyCorner(button, 4)

	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = COLORS.buttonHover
	end)
	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = COLORS.button
	end)

	return button
end

local function makeColumn(parent: Instance, title: string, order: number): Frame
	local column = Instance.new("Frame")
	column.Name = title
	column.BackgroundColor3 = COLORS.panel
	column.BorderSizePixel = 0
	column.Size = UDim2.new(1 / 3, -8, 1, 0)
	column.LayoutOrder = order
	column.Parent = parent
	applyCorner(column, 6)

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 6)
	layout.Parent = column
	applyPadding(column, 8)

	local header = makeLabel(column, title, UDim2.new(1, 0, 0, 22), true)
	header.LayoutOrder = 1

	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundColor3 = COLORS.panelAlt
	body.BorderSizePixel = 0
	body.Size = UDim2.new(1, 0, 1, -30)
	body.LayoutOrder = 2
	body.Parent = column
	applyCorner(body, 4)
	applyPadding(body, 6)

	return body
end

local function create(plugin: Plugin): PanelHandles
	local widgetInfo = DockWidgetPluginGuiInfo.new(
		Enum.InitialDockState.Float,
		false,
		false,
		720,
		480,
		520,
		320
	)

	local widget = plugin:CreateDockWidgetPluginGui("PluginGuardMain", widgetInfo)
	widget.Title = "PluginGuard"
	widget.Name = "PluginGuard"

	local root = Instance.new("Frame")
	root.Name = "Root"
	root.BackgroundColor3 = COLORS.bg
	root.BorderSizePixel = 0
	root.Size = UDim2.fromScale(1, 1)
	root.Parent = widget
	applyPadding(root, 10)

	local rootLayout = Instance.new("UIListLayout")
	rootLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rootLayout.Padding = UDim.new(0, 8)
	rootLayout.Parent = root

	local top = Instance.new("Frame")
	top.BackgroundTransparency = 1
	top.Size = UDim2.new(1, 0, 0, 32)
	top.LayoutOrder = 1
	top.Parent = root

	local topLayout = Instance.new("UIListLayout")
	topLayout.FillDirection = Enum.FillDirection.Horizontal
	topLayout.SortOrder = Enum.SortOrder.LayoutOrder
	topLayout.Padding = UDim.new(0, 8)
	topLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	topLayout.Parent = top

	local btnRescan = makeButton(top, "Re-escanear", UDim2.new(0, 120, 0, 28))
	btnRescan.LayoutOrder = 1

	local btnAddAssetId = makeButton(top, "+ AssetId", UDim2.new(0, 110, 0, 28))
	btnAddAssetId.LayoutOrder = 2
	btnAddAssetId.BackgroundColor3 = COLORS.accent

	local statusLabel = makeLabel(top, "Estado: Listo", UDim2.new(1, -250, 1, 0), false)
	statusLabel.LayoutOrder = 3
	statusLabel.TextColor3 = COLORS.muted
	statusLabel.TextYAlignment = Enum.TextYAlignment.Center

	local columns = Instance.new("Frame")
	columns.BackgroundTransparency = 1
	columns.Size = UDim2.new(1, 0, 1, -70)
	columns.LayoutOrder = 2
	columns.Parent = root

	local columnsLayout = Instance.new("UIListLayout")
	columnsLayout.FillDirection = Enum.FillDirection.Horizontal
	columnsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	columnsLayout.Padding = UDim.new(0, 8)
	columnsLayout.Parent = columns

	local listBody = makeColumn(columns, "1) Plugins encontrados", 1)
	local centerBody = makeColumn(columns, "2) Acciones / resumen", 2)
	local detailBody = makeColumn(columns, "3) Detalle", 3)

	local listFrame = Instance.new("ScrollingFrame")
	listFrame.BackgroundTransparency = 1
	listFrame.BorderSizePixel = 0
	listFrame.Size = UDim2.fromScale(1, 1)
	listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	listFrame.ScrollBarThickness = 6
	listFrame.Parent = listBody

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 4)
	listLayout.Parent = listFrame

	local selectedLabel = makeLabel(centerBody, "Seleccionado: —", UDim2.new(1, 0, 0, 20), true)

	local debugLabel = makeLabel(centerBody, "Plugin Debugging: sin comprobar", UDim2.new(1, 0, 0, 40), false)
	debugLabel.Position = UDim2.fromOffset(0, 24)
	debugLabel.TextColor3 = COLORS.muted

	local btnScanSelected = makeButton(centerBody, "Escanear este", UDim2.new(1, 0, 0, 28))
	btnScanSelected.Position = UDim2.fromOffset(0, 72)

	local btnScanAll = makeButton(centerBody, "Escanear todos", UDim2.new(1, 0, 0, 28))
	btnScanAll.Position = UDim2.fromOffset(0, 106)

	local summaryLabel = makeLabel(
		centerBody,
		"Aún sin escaneo de reglas.",
		UDim2.new(1, 0, 0, 70),
		false
	)
	summaryLabel.Position = UDim2.fromOffset(0, 144)
	summaryLabel.TextColor3 = COLORS.muted

	local detailFrame = Instance.new("ScrollingFrame")
	detailFrame.BackgroundTransparency = 1
	detailFrame.BorderSizePixel = 0
	detailFrame.Size = UDim2.fromScale(1, 1)
	detailFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	detailFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	detailFrame.ScrollBarThickness = 6
	detailFrame.Parent = detailBody

	local detailLabel = makeLabel(
		detailFrame,
		"Selecciona un plugin y pulsa Escanear este.",
		UDim2.new(1, -8, 0, 120),
		false
	)
	detailLabel.TextColor3 = COLORS.muted

	local footer = makeLabel(
		root,
		"Escaneo heurístico: no prueba ni descarta malware.",
		UDim2.new(1, 0, 0, 18),
		false
	)
	footer.LayoutOrder = 3
	footer.TextColor3 = COLORS.muted
	footer.TextSize = 12

	local rescanCallback: (() -> ())? = nil
	local addAssetCallback: (() -> ())? = nil
	local selectCallback: ((PluginListEntry) -> ())? = nil
	local scanSelectedCallback: (() -> ())? = nil
	local scanAllCallback: (() -> ())? = nil

	local selectedEntry: PluginListEntry? = nil
	local currentEntries: { PluginListEntry } = {}
	local rowButtons: { TextButton } = {}
	local titleLabels: { [string]: TextLabel } = {}

	btnRescan.MouseButton1Click:Connect(function()
		if rescanCallback then
			rescanCallback()
		end
	end)
	btnAddAssetId.MouseButton1Click:Connect(function()
		if addAssetCallback then
			addAssetCallback()
		end
	end)
	btnScanSelected.MouseButton1Click:Connect(function()
		if scanSelectedCallback then
			scanSelectedCallback()
		end
	end)
	btnScanAll.MouseButton1Click:Connect(function()
		if scanAllCallback then
			scanAllCallback()
		end
	end)

	local function clearList()
		for _, child in ipairs(listFrame:GetChildren()) do
			if not child:IsA("UIListLayout") then
				child:Destroy()
			end
		end
		table.clear(rowButtons)
		table.clear(titleLabels)
	end

	local function setStatus(text: string)
		statusLabel.Text = text
	end

	local function setDebugLabel(text: string, ok: boolean?)
		debugLabel.Text = text
		if ok == true then
			debugLabel.TextColor3 = COLORS.ok
		elseif ok == false then
			debugLabel.TextColor3 = COLORS.warn
		else
			debugLabel.TextColor3 = COLORS.muted
		end
	end

	local function setSelected(entry: PluginListEntry?)
		selectedEntry = entry
		if entry == nil then
			selectedLabel.Text = "Seleccionado: —"
			for _, row in ipairs(rowButtons) do
				row.BackgroundColor3 = COLORS.row
			end
			return
		end

		selectedLabel.Text = ("Seleccionado: %s"):format(entry.name)
		for _, row in ipairs(rowButtons) do
			row.BackgroundColor3 = if row:GetAttribute("EntryId") == entry.id
				then COLORS.rowSelected
				else COLORS.row
		end
	end

	local function setPluginList(entries: { PluginListEntry }, emptyMessage: string?)
		clearList()
		currentEntries = entries

		if #entries == 0 then
			local empty = makeLabel(listFrame, emptyMessage or "No hay plugins listados.", UDim2.new(1, 0, 0, 80), false)
			empty.TextColor3 = COLORS.muted
			setSelected(nil)
			return
		end

		for index, entry in ipairs(entries) do
			local row = Instance.new("TextButton")
			row.Size = UDim2.new(1, -4, 0, 44)
			row.BackgroundColor3 = COLORS.row
			row.BorderSizePixel = 0
			row.AutoButtonColor = false
			row.Text = ""
			row.LayoutOrder = index
			row:SetAttribute("EntryId", entry.id)
			row.Parent = listFrame
			applyCorner(row, 4)
			applyPadding(row, 6)

			local badge = entry.badge or "—"
			local title = makeLabel(row, ("%s  %s"):format(badge, entry.name), UDim2.new(1, 0, 0, 18), true)
			titleLabels[entry.id] = title

			local subtitle = makeLabel(
				row,
				("%s · %d script(s)"):format(entry.origin, entry.scriptCount or 0),
				UDim2.new(1, 0, 0, 16),
				false
			)
			subtitle.Position = UDim2.fromOffset(0, 18)
			subtitle.TextColor3 = COLORS.muted
			subtitle.TextSize = 12

			row.MouseButton1Click:Connect(function()
				setSelected(entry)
				if selectCallback then
					selectCallback(entry)
				end
			end)

			table.insert(rowButtons, row)
		end
	end

	local function updateEntryBadge(pluginId: string, badge: string)
		for _, entry in ipairs(currentEntries) do
			if entry.id == pluginId then
				entry.badge = badge
				break
			end
		end
		local title = titleLabels[pluginId]
		if title then
			for _, entry in ipairs(currentEntries) do
				if entry.id == pluginId then
					title.Text = ("%s  %s"):format(badge, entry.name)
					break
				end
			end
		end
	end

	local function showScanResult(summaryText: string, detailText: string)
		summaryLabel.Text = summaryText
		summaryLabel.TextColor3 = COLORS.text
		detailLabel.Text = detailText
		detailLabel.TextColor3 = COLORS.text
	end

	return {
		widget = widget,
		setStatus = setStatus,
		setDebugLabel = setDebugLabel,
		setPluginList = setPluginList,
		setSelected = setSelected,
		getSelected = function()
			return selectedEntry
		end,
		updateEntryBadge = updateEntryBadge,
		showScanResult = showScanResult,
		onRescan = function(cb)
			rescanCallback = cb
		end,
		onAddAssetId = function(cb)
			addAssetCallback = cb
		end,
		onSelect = function(cb)
			selectCallback = cb
		end,
		onScanSelected = function(cb)
			scanSelectedCallback = cb
		end,
		onScanAll = function(cb)
			scanAllCallback = cb
		end,
	}
end

return {
	create = create,
}

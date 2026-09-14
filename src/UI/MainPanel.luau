-- Panel 3 columnas + pestañas Debug / AssetId

export type PluginListEntry = {
	id: string,
	name: string,
	origin: string,
	scriptCount: number?,
	badge: string?,
}

export type FindingRow = {
	severity: string, -- high | medium | info
	title: string,
	body: string,
}

export type TabId = "debug" | "asset"

export type PanelHandles = {
	widget: DockWidgetPluginGui,
	setStatus: (text: string) -> (),
	setDebugLabel: (text: string, ok: boolean?) -> (),
	setDebugEntries: (entries: { PluginListEntry }, emptyMessage: string?) -> (),
	setAssetEntries: (entries: { PluginListEntry }, emptyMessage: string?) -> (),
	setActiveTab: (tab: TabId) -> (),
	getActiveTab: () -> TabId,
	setSelected: (entry: PluginListEntry?) -> (),
	getSelected: () -> PluginListEntry?,
	updateEntryBadge: (pluginId: string, badge: string) -> (),
	showScanResult: (summaryText: string, headerText: string, findings: { FindingRow }?) -> (),
	showAssetIdModal: () -> (),
	hideAssetIdModal: () -> (),
	onRescan: (callback: () -> ()) -> (),
	onAddAssetId: (callback: () -> ()) -> (),
	onAssetIdSubmit: (callback: (rawText: string) -> ()) -> (),
	onSelect: (callback: (entry: PluginListEntry) -> ()) -> (),
	onScanSelected: (callback: () -> ()) -> (),
	onScanAll: (callback: () -> ()) -> (),
	onClearList: (callback: () -> ()) -> (),
	onTabChanged: (callback: (tab: TabId) -> ()) -> (),
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
	danger = color(160, 55, 55),
	tabOn = color(0, 120, 190),
	tabOff = color(50, 50, 50),
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
		if button:GetAttribute("LockedColor") then
			return
		end
		button.BackgroundColor3 = COLORS.buttonHover
	end)
	button.MouseLeave:Connect(function()
		local locked = button:GetAttribute("BaseColor")
		if typeof(locked) == "Color3" then
			button.BackgroundColor3 = locked
		else
			button.BackgroundColor3 = COLORS.button
		end
	end)

	return button
end

local function create(plugin: Plugin): PanelHandles
	local widgetInfo = DockWidgetPluginGuiInfo.new(
		Enum.InitialDockState.Float,
		false,
		false,
		760,
		500,
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

	-- Top bar
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

	local btnRescan = makeButton(top, "Re-escanear", UDim2.new(0, 100, 0, 28))
	btnRescan.LayoutOrder = 1

	local btnAddAssetId = makeButton(top, "+ AssetId", UDim2.new(0, 95, 0, 28))
	btnAddAssetId.LayoutOrder = 2
	btnAddAssetId.BackgroundColor3 = COLORS.accent
	btnAddAssetId:SetAttribute("BaseColor", COLORS.accent)

	local btnClearList = makeButton(top, "Limpiar lista", UDim2.new(0, 105, 0, 28))
	btnClearList.LayoutOrder = 3
	btnClearList.BackgroundColor3 = COLORS.danger
	btnClearList:SetAttribute("BaseColor", COLORS.danger)

	local statusLabel = makeLabel(top, "Estado: Listo", UDim2.new(1, -320, 1, 0), false)
	statusLabel.LayoutOrder = 4
	statusLabel.TextColor3 = COLORS.muted
	statusLabel.TextYAlignment = Enum.TextYAlignment.Center

	-- Columns
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

	-- Columna 1 con pestañas
	local listColumn = Instance.new("Frame")
	listColumn.Name = "Lista"
	listColumn.BackgroundColor3 = COLORS.panel
	listColumn.BorderSizePixel = 0
	listColumn.Size = UDim2.new(1 / 3, -8, 1, 0)
	listColumn.LayoutOrder = 1
	listColumn.Parent = columns
	applyCorner(listColumn, 6)
	applyPadding(listColumn, 8)

	local listColLayout = Instance.new("UIListLayout")
	listColLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listColLayout.Padding = UDim.new(0, 6)
	listColLayout.Parent = listColumn

	local tabsRow = Instance.new("Frame")
	tabsRow.BackgroundTransparency = 1
	tabsRow.Size = UDim2.new(1, 0, 0, 28)
	tabsRow.LayoutOrder = 1
	tabsRow.Parent = listColumn

	local tabsLayout = Instance.new("UIListLayout")
	tabsLayout.FillDirection = Enum.FillDirection.Horizontal
	tabsLayout.Padding = UDim.new(0, 6)
	tabsLayout.Parent = tabsRow

	local tabDebug = makeButton(tabsRow, "Debug", UDim2.new(0.5, -3, 1, 0))
	tabDebug.LayoutOrder = 1
	local tabAsset = makeButton(tabsRow, "AssetId", UDim2.new(0.5, -3, 1, 0))
	tabAsset.LayoutOrder = 2

	local listBody = Instance.new("Frame")
	listBody.Name = "Body"
	listBody.BackgroundColor3 = COLORS.panelAlt
	listBody.BorderSizePixel = 0
	listBody.Size = UDim2.new(1, 0, 1, -34)
	listBody.LayoutOrder = 2
	listBody.Parent = listColumn
	applyCorner(listBody, 4)
	applyPadding(listBody, 6)

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

	-- Columna 2
	local centerColumn = Instance.new("Frame")
	centerColumn.BackgroundColor3 = COLORS.panel
	centerColumn.BorderSizePixel = 0
	centerColumn.Size = UDim2.new(1 / 3, -8, 1, 0)
	centerColumn.LayoutOrder = 2
	centerColumn.Parent = columns
	applyCorner(centerColumn, 6)
	applyPadding(centerColumn, 8)

	local centerLayout = Instance.new("UIListLayout")
	centerLayout.SortOrder = Enum.SortOrder.LayoutOrder
	centerLayout.Padding = UDim.new(0, 6)
	centerLayout.Parent = centerColumn

	makeLabel(centerColumn, "2) Acciones / resumen", UDim2.new(1, 0, 0, 22), true).LayoutOrder = 1

	local centerBody = Instance.new("Frame")
	centerBody.BackgroundColor3 = COLORS.panelAlt
	centerBody.BorderSizePixel = 0
	centerBody.Size = UDim2.new(1, 0, 1, -30)
	centerBody.LayoutOrder = 2
	centerBody.Parent = centerColumn
	applyCorner(centerBody, 4)
	applyPadding(centerBody, 6)

	local selectedLabel = makeLabel(centerBody, "Seleccionado: —", UDim2.new(1, 0, 0, 20), true)
	local debugLabel = makeLabel(centerBody, "Plugin Debugging: sin comprobar", UDim2.new(1, 0, 0, 40), false)
	debugLabel.Position = UDim2.fromOffset(0, 24)
	debugLabel.TextColor3 = COLORS.muted

	local tabHint = makeLabel(centerBody, "Pestaña: Debug", UDim2.new(1, 0, 0, 18), false)
	tabHint.Position = UDim2.fromOffset(0, 66)
	tabHint.TextColor3 = COLORS.accent
	tabHint.TextSize = 12

	local btnScanSelected = makeButton(centerBody, "Escanear este", UDim2.new(1, 0, 0, 28))
	btnScanSelected.Position = UDim2.fromOffset(0, 90)

	local btnScanAll = makeButton(centerBody, "Escanear pestaña", UDim2.new(1, 0, 0, 28))
	btnScanAll.Position = UDim2.fromOffset(0, 124)

	local summaryLabel = makeLabel(centerBody, "Aún sin escaneo de reglas.", UDim2.new(1, 0, 0, 70), false)
	summaryLabel.Position = UDim2.fromOffset(0, 162)
	summaryLabel.TextColor3 = COLORS.muted

	-- Columna 3
	local detailColumn = Instance.new("Frame")
	detailColumn.BackgroundColor3 = COLORS.panel
	detailColumn.BorderSizePixel = 0
	detailColumn.Size = UDim2.new(1 / 3, -8, 1, 0)
	detailColumn.LayoutOrder = 3
	detailColumn.Parent = columns
	applyCorner(detailColumn, 6)
	applyPadding(detailColumn, 8)

	local detailColLayout = Instance.new("UIListLayout")
	detailColLayout.SortOrder = Enum.SortOrder.LayoutOrder
	detailColLayout.Padding = UDim.new(0, 6)
	detailColLayout.Parent = detailColumn

	makeLabel(detailColumn, "3) Detalle", UDim2.new(1, 0, 0, 22), true).LayoutOrder = 1

	local detailBody = Instance.new("Frame")
	detailBody.BackgroundColor3 = COLORS.panelAlt
	detailBody.BorderSizePixel = 0
	detailBody.Size = UDim2.new(1, 0, 1, -30)
	detailBody.LayoutOrder = 2
	detailBody.Parent = detailColumn
	applyCorner(detailBody, 4)
	applyPadding(detailBody, 6)

	local TextService = game:GetService("TextService")

	local SEVERITY_ICON = {
		high = "rbxasset://textures/StudioSharedUI/alert_error.png",
		medium = "rbxasset://textures/StudioSharedUI/alert_warning.png",
		info = "rbxasset://textures/StudioSharedUI/alert_info.png",
	}
	local SEVERITY_COLOR = {
		high = color(220, 80, 80),
		medium = color(220, 180, 60),
		info = color(100, 160, 220),
	}

	local detailFrame = Instance.new("ScrollingFrame")
	detailFrame.BackgroundTransparency = 1
	detailFrame.BorderSizePixel = 0
	detailFrame.Size = UDim2.fromScale(1, 1)
	detailFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	detailFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	detailFrame.ScrollBarThickness = 10
	detailFrame.ScrollingDirection = Enum.ScrollingDirection.Y
	detailFrame.ElasticBehavior = Enum.ElasticBehavior.Never
	detailFrame.ScrollBarImageColor3 = Color3.fromRGB(180, 180, 180)
	detailFrame.Parent = detailBody

	local detailListLayout = Instance.new("UIListLayout")
	detailListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	detailListLayout.Padding = UDim.new(0, 6)
	detailListLayout.Parent = detailFrame

	detailListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		detailFrame.CanvasSize = UDim2.new(0, 0, 0, detailListLayout.AbsoluteContentSize.Y + 8)
	end)

	local function clearDetailRows()
		for _, child in ipairs(detailFrame:GetChildren()) do
			if not child:IsA("UIListLayout") then
				child:Destroy()
			end
		end
	end

	local function estimateTextHeight(text: string, width: number, textSize: number, font: Enum.Font): number
		local ok, bounds = pcall(function()
			return TextService:GetTextSize(text, textSize, font, Vector2.new(width, 200000))
		end)
		if ok and bounds then
			return math.max(bounds.Y, textSize)
		end
		local lines = 1
		for _ in string.gmatch(text, "\n") do
			lines += 1
		end
		return lines * (textSize + 4)
	end

	local function addDetailHeader(text: string, order: number)
		local label = makeLabel(detailFrame, text, UDim2.new(1, -14, 0, 0), false)
		label.LayoutOrder = order
		label.TextColor3 = COLORS.text
		label.TextYAlignment = Enum.TextYAlignment.Top
		local h = estimateTextHeight(text, math.max(100, detailFrame.AbsoluteSize.X - 20), 14, Enum.Font.Gotham)
		label.Size = UDim2.new(1, -14, 0, h + 4)
	end

	local function addFindingRow(finding: FindingRow, order: number)
		local severity = finding.severity
		if severity ~= "high" and severity ~= "medium" and severity ~= "info" then
			severity = "info"
		end

		local row = Instance.new("Frame")
		row.BackgroundColor3 = color(42, 42, 46)
		row.BorderSizePixel = 0
		row.Size = UDim2.new(1, -4, 0, 72)
		row.LayoutOrder = order
		row.Parent = detailFrame
		applyCorner(row, 4)
		applyPadding(row, 6)

		local icon = Instance.new("ImageLabel")
		icon.BackgroundTransparency = 1
		icon.Size = UDim2.fromOffset(18, 18)
		icon.Position = UDim2.fromOffset(0, 2)
		icon.Image = SEVERITY_ICON[severity]
		icon.Parent = row

		local title = Instance.new("TextLabel")
		title.BackgroundTransparency = 1
		title.Position = UDim2.fromOffset(26, 0)
		title.Size = UDim2.new(1, -30, 0, 18)
		title.Font = Enum.Font.GothamBold
		title.TextSize = 13
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = SEVERITY_COLOR[severity]
		title.Text = finding.title
		title.TextTruncate = Enum.TextTruncate.AtEnd
		title.Parent = row

		local body = Instance.new("TextLabel")
		body.BackgroundTransparency = 1
		body.Position = UDim2.fromOffset(26, 20)
		body.Size = UDim2.new(1, -30, 0, 0)
		body.Font = Enum.Font.Gotham
		body.TextSize = 12
		body.TextXAlignment = Enum.TextXAlignment.Left
		body.TextYAlignment = Enum.TextYAlignment.Top
		body.TextWrapped = true
		body.TextColor3 = COLORS.muted
		body.Text = finding.body
		body.Parent = row

		local bodyWidth = math.max(80, detailFrame.AbsoluteSize.X - 50)
		local bodyHeight = estimateTextHeight(finding.body, bodyWidth, 12, Enum.Font.Gotham)
		body.Size = UDim2.new(1, -30, 0, bodyHeight)
		row.Size = UDim2.new(1, -4, 0, math.max(48, bodyHeight + 32))
	end

	local footer = makeLabel(
		root,
		"Escaneo heurístico: no prueba ni descarta malware.",
		UDim2.new(1, 0, 0, 18),
		false
	)
	footer.LayoutOrder = 3
	footer.TextColor3 = COLORS.muted
	footer.TextSize = 12

	-- Modal AssetId
	local modal = Instance.new("Frame")
	modal.Name = "AssetIdModal"
	modal.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	modal.BackgroundTransparency = 0.45
	modal.BorderSizePixel = 0
	modal.Size = UDim2.fromScale(1, 1)
	modal.Visible = false
	modal.ZIndex = 20
	modal.Parent = root

	local modalCard = Instance.new("Frame")
	modalCard.Size = UDim2.new(0, 360, 0, 220)
	modalCard.Position = UDim2.new(0.5, -180, 0.5, -110)
	modalCard.BackgroundColor3 = COLORS.panel
	modalCard.BorderSizePixel = 0
	modalCard.ZIndex = 21
	modalCard.Parent = modal
	applyCorner(modalCard, 8)
	applyPadding(modalCard, 12)

	local modalTitle = makeLabel(modalCard, "Agregar por AssetId", UDim2.new(1, 0, 0, 22), true)
	modalTitle.ZIndex = 22

	local modalHint = makeLabel(
		modalCard,
		"Pega uno o varios IDs (o URLs del Store), uno por línea.",
		UDim2.new(1, 0, 0, 34),
		false
	)
	modalHint.Position = UDim2.fromOffset(0, 26)
	modalHint.TextColor3 = COLORS.muted
	modalHint.TextSize = 12
	modalHint.ZIndex = 22

	local assetBox = Instance.new("TextBox")
	assetBox.Size = UDim2.new(1, 0, 0, 90)
	assetBox.Position = UDim2.fromOffset(0, 64)
	assetBox.BackgroundColor3 = COLORS.panelAlt
	assetBox.BorderSizePixel = 0
	assetBox.ClearTextOnFocus = false
	assetBox.MultiLine = true
	assetBox.TextXAlignment = Enum.TextXAlignment.Left
	assetBox.TextYAlignment = Enum.TextYAlignment.Top
	assetBox.Font = Enum.Font.Code
	assetBox.TextSize = 13
	assetBox.TextColor3 = COLORS.text
	assetBox.PlaceholderText = "123456789"
	assetBox.Text = ""
	assetBox.ZIndex = 22
	assetBox.Parent = modalCard
	applyCorner(assetBox, 4)
	applyPadding(assetBox, 6)

	local modalButtons = Instance.new("Frame")
	modalButtons.BackgroundTransparency = 1
	modalButtons.Size = UDim2.new(1, 0, 0, 32)
	modalButtons.Position = UDim2.fromOffset(0, 168)
	modalButtons.ZIndex = 22
	modalButtons.Parent = modalCard

	local modalBtnLayout = Instance.new("UIListLayout")
	modalBtnLayout.FillDirection = Enum.FillDirection.Horizontal
	modalBtnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	modalBtnLayout.Padding = UDim.new(0, 8)
	modalBtnLayout.Parent = modalButtons

	local btnCancelAsset = makeButton(modalButtons, "Cancelar", UDim2.new(0, 100, 0, 28))
	btnCancelAsset.ZIndex = 23
	local btnConfirmAsset = makeButton(modalButtons, "Agregar", UDim2.new(0, 100, 0, 28))
	btnConfirmAsset.BackgroundColor3 = COLORS.accent
	btnConfirmAsset:SetAttribute("BaseColor", COLORS.accent)
	btnConfirmAsset.ZIndex = 23

	-- State
	local activeTab: TabId = "debug"
	local debugEntries: { PluginListEntry } = {}
	local assetEntries: { PluginListEntry } = {}
	local debugEmptyMessage = "No hay plugins en Debug.\nActiva Plugin Debugging Enabled."
	local assetEmptyMessage = "No hay AssetIds.\nUsa + AssetId para agregar."

	local rescanCallback: (() -> ())? = nil
	local addAssetCallback: (() -> ())? = nil
	local assetSubmitCallback: ((string) -> ())? = nil
	local selectCallback: ((PluginListEntry) -> ())? = nil
	local scanSelectedCallback: (() -> ())? = nil
	local scanAllCallback: (() -> ())? = nil
	local clearListCallback: (() -> ())? = nil
	local tabChangedCallback: ((TabId) -> ())? = nil

	local selectedEntry: PluginListEntry? = nil
	local rowButtons: { TextButton } = {}
	local titleLabels: { [string]: TextLabel } = {}

	local function hideAssetIdModal()
		modal.Visible = false
	end

	local function showAssetIdModal()
		modal.Visible = true
		assetBox.Text = ""
		assetBox:CaptureFocus()
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

	local function clearRows()
		for _, child in ipairs(listFrame:GetChildren()) do
			if not child:IsA("UIListLayout") then
				child:Destroy()
			end
		end
		table.clear(rowButtons)
		table.clear(titleLabels)
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

	local function renderList()
		clearRows()
		local entries = if activeTab == "debug" then debugEntries else assetEntries
		local emptyMessage = if activeTab == "debug" then debugEmptyMessage else assetEmptyMessage

		tabHint.Text = if activeTab == "debug"
			then "Pestaña: Debug (plugins locales)"
			else "Pestaña: AssetId (Store)"

		tabDebug.BackgroundColor3 = if activeTab == "debug" then COLORS.tabOn else COLORS.tabOff
		tabDebug:SetAttribute("BaseColor", tabDebug.BackgroundColor3)
		tabAsset.BackgroundColor3 = if activeTab == "asset" then COLORS.tabOn else COLORS.tabOff
		tabAsset:SetAttribute("BaseColor", tabAsset.BackgroundColor3)

		if #entries == 0 then
			local empty = makeLabel(listFrame, emptyMessage, UDim2.new(1, 0, 0, 90), false)
			empty.TextColor3 = COLORS.muted
			setSelected(nil)
			return
		end

		local keepSelection: PluginListEntry? = nil
		for index, entry in ipairs(entries) do
			if selectedEntry and selectedEntry.id == entry.id then
				keepSelection = entry
			end

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

		setSelected(keepSelection)
	end

	local function setActiveTab(tab: TabId)
		if activeTab == tab then
			renderList()
			return
		end
		activeTab = tab
		setSelected(nil)
		renderList()
		if tabChangedCallback then
			tabChangedCallback(tab)
		end
	end

	local function setDebugEntries(entries: { PluginListEntry }, emptyMessage: string?)
		debugEntries = entries
		if emptyMessage then
			debugEmptyMessage = emptyMessage
		end
		if activeTab == "debug" then
			renderList()
		end
	end

	local function setAssetEntries(entries: { PluginListEntry }, emptyMessage: string?)
		assetEntries = entries
		if emptyMessage then
			assetEmptyMessage = emptyMessage
		end
		if activeTab == "asset" then
			renderList()
		end
	end

	local function updateEntryBadge(pluginId: string, badge: string)
		local function touch(list: { PluginListEntry })
			for _, entry in ipairs(list) do
				if entry.id == pluginId then
					entry.badge = badge
					local title = titleLabels[pluginId]
					if title then
						title.Text = ("%s  %s"):format(badge, entry.name)
					end
					break
				end
			end
		end
		touch(debugEntries)
		touch(assetEntries)
	end

	local lastSummary = ""
	local lastHeader = ""
	local lastFindings: { FindingRow }? = nil
	local reflowing = false

	local function showScanResult(summaryText: string, headerText: string, findings: { FindingRow }?)
		lastSummary = summaryText
		lastHeader = headerText
		lastFindings = findings

		summaryLabel.Text = summaryText
		summaryLabel.TextColor3 = COLORS.text
		clearDetailRows()
		detailFrame.CanvasPosition = Vector2.new(0, 0)

		local order = 1
		if headerText and headerText ~= "" then
			addDetailHeader(headerText, order)
			order += 1
		end

		if findings then
			for _, finding in ipairs(findings) do
				addFindingRow(finding, order)
				order += 1
			end
		end
	end

	detailFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if reflowing or lastSummary == "" then
			return
		end
		reflowing = true
		local pos = detailFrame.CanvasPosition
		showScanResult(lastSummary, lastHeader, lastFindings)
		detailFrame.CanvasPosition = pos
		reflowing = false
	end)

	-- Placeholder inicial
	showScanResult(
		"Selecciona un plugin",
		"Elige pestaña Debug o AssetId, selecciona un plugin y escanea.",
		nil
	)

	tabDebug.MouseButton1Click:Connect(function()
		setActiveTab("debug")
	end)
	tabAsset.MouseButton1Click:Connect(function()
		setActiveTab("asset")
	end)

	btnRescan.MouseButton1Click:Connect(function()
		if rescanCallback then
			rescanCallback()
		end
	end)
	btnAddAssetId.MouseButton1Click:Connect(function()
		setActiveTab("asset")
		showAssetIdModal()
		if addAssetCallback then
			addAssetCallback()
		end
	end)
	btnClearList.MouseButton1Click:Connect(function()
		if clearListCallback then
			clearListCallback()
		end
	end)
	btnCancelAsset.MouseButton1Click:Connect(function()
		hideAssetIdModal()
	end)
	btnConfirmAsset.MouseButton1Click:Connect(function()
		local text = assetBox.Text
		hideAssetIdModal()
		if assetSubmitCallback then
			assetSubmitCallback(text)
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

	-- Initial paint
	tabDebug.BackgroundColor3 = COLORS.tabOn
	tabDebug:SetAttribute("BaseColor", COLORS.tabOn)
	tabAsset.BackgroundColor3 = COLORS.tabOff
	tabAsset:SetAttribute("BaseColor", COLORS.tabOff)
	renderList()

	return {
		widget = widget,
		setStatus = setStatus,
		setDebugLabel = setDebugLabel,
		setDebugEntries = setDebugEntries,
		setAssetEntries = setAssetEntries,
		setActiveTab = setActiveTab,
		getActiveTab = function()
			return activeTab
		end,
		setSelected = setSelected,
		getSelected = function()
			return selectedEntry
		end,
		updateEntryBadge = updateEntryBadge,
		showScanResult = showScanResult,
		showAssetIdModal = showAssetIdModal,
		hideAssetIdModal = hideAssetIdModal,
		onRescan = function(cb)
			rescanCallback = cb
		end,
		onAddAssetId = function(cb)
			addAssetCallback = cb
		end,
		onAssetIdSubmit = function(cb)
			assetSubmitCallback = cb
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
		onClearList = function(cb)
			clearListCallback = cb
		end,
		onTabChanged = function(cb)
			tabChangedCallback = cb
		end,
	}
end

return {
	create = create,
}

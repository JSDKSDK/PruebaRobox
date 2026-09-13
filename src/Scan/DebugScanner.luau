-- Descubre plugins visibles bajo PluginDebugService (requiere Plugin Debugging)

export type DebugPluginInfo = {
	id: string,
	name: string,
	origin: string, -- "Debug"
	className: string,
	scriptCount: number,
	root: Instance,
}

export type DebugScanResult = {
	debugLikelyEnabled: boolean,
	plugins: { DebugPluginInfo },
	message: string,
}

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

local function scan(): DebugScanResult
	local okService, pds = pcall(function()
		return game:GetService("PluginDebugService")
	end)

	if not okService or pds == nil then
		return {
			debugLikelyEnabled = false,
			plugins = {},
			message = "No se pudo acceder a PluginDebugService.",
		}
	end

	local children = pds:GetChildren()
	local plugins: { DebugPluginInfo } = {}

	for index, child in ipairs(children) do
		-- En debug, cada plugin local suele aparecer como hijo (Plugin u otro contenedor)
		local scriptCount = countScripts(child)
		table.insert(plugins, {
			id = ("debug:%s:%d"):format(child.Name, index),
			name = child.Name,
			origin = "Debug",
			className = child.ClassName,
			scriptCount = scriptCount,
			root = child,
		})
	end

	table.sort(plugins, function(a, b)
		return string.lower(a.name) < string.lower(b.name)
	end)

	local debugLikelyEnabled = #plugins > 0
	local message: string
	if debugLikelyEnabled then
		message = ("Se encontraron %d plugin(s) en PluginDebugService."):format(#plugins)
	else
		message =
			"PluginDebugService está vacío. Activa File → Studio Settings → Studio → Plugin Debugging Enabled, reinicia Studio y vuelve a Re-escanear."
	end

	return {
		debugLikelyEnabled = debugLikelyEnabled,
		plugins = plugins,
		message = message,
	}
end

return {
	scan = scan,
}

-- Une listado + source + engine (estilo lite)

local SourceCollector = require(script.Parent.SourceCollector)
local Engine = require(script.Parent.Parent.Rules.Engine)
local Types = require(script.Parent.Parent.Rules.Types)

type PluginScanResult = Types.PluginScanResult

export type ScanTarget = {
	pluginId: string,
	pluginName: string,
	origin: string,
	root: Instance,
}

local function scanTarget(target: ScanTarget): PluginScanResult
	local collected = SourceCollector.collect(target.root)
	return Engine.scanSources(
		target.pluginId,
		target.pluginName,
		target.origin,
		collected.sources,
		collected.failed
	)
end

local function scanMany(targets: { ScanTarget }): { PluginScanResult }
	local results = {}
	for _, target in ipairs(targets) do
		table.insert(results, scanTarget(target))
	end
	return results
end

return {
	scanTarget = scanTarget,
	scanMany = scanMany,
}

-- Aplica reglas heurísticas sobre fuentes de scripts

local Types = require(script.Parent.Types)
local Catalog = require(script.Parent.Catalog)

type Rule = Types.Rule
type SourceFile = Types.SourceFile
type Finding = Types.Finding
type PluginScanResult = Types.PluginScanResult

local function makeSnippet(source: string, startIndex: number): string
	local from = math.max(1, startIndex - 40)
	local to = math.min(#source, startIndex + 80)
	local chunk = string.sub(source, from, to)
	chunk = string.gsub(chunk, "[\r\n\t]", " ")
	if from > 1 then
		chunk = "…" .. chunk
	end
	if to < #source then
		chunk = chunk .. "…"
	end
	return chunk
end

local function matchRuleOnSource(rule: Rule, sourceFile: SourceFile): Finding?
	for _, pattern in ipairs(rule.patterns) do
		local ok, startIndex = pcall(function()
			return string.find(sourceFile.source, pattern)
		end)
		if ok and typeof(startIndex) == "number" then
			return {
				ruleId = rule.id,
				severity = rule.severity,
				message = rule.message,
				scriptPath = sourceFile.scriptPath,
				snippet = makeSnippet(sourceFile.source, startIndex),
			}
		end
	end
	return nil
end

local function scanSources(
	pluginId: string,
	pluginName: string,
	origin: string,
	sources: { SourceFile },
	scriptsFailed: number
): PluginScanResult
	local rules = Catalog.getRules()
	local findings: { Finding } = {}
	local seen: { [string]: boolean } = {}

	for _, sourceFile in ipairs(sources) do
		for _, rule in ipairs(rules) do
			local finding = matchRuleOnSource(rule, sourceFile)
			if finding then
				local key = rule.id .. "@" .. sourceFile.scriptPath
				if not seen[key] then
					seen[key] = true
					table.insert(findings, finding)
				end
			end
		end
	end

	table.sort(findings, function(a, b)
		local ra = Types.severityRank(a.severity)
		local rb = Types.severityRank(b.severity)
		if ra == rb then
			return a.ruleId < b.ruleId
		end
		return ra > rb
	end)

	return {
		pluginId = pluginId,
		pluginName = pluginName,
		origin = origin,
		badge = Types.badgeFromFindings(findings),
		findings = findings,
		scriptsScanned = #sources,
		scriptsFailed = scriptsFailed,
	}
end

return {
	scanSources = scanSources,
}

-- Aplica reglas heurísticas + firmas de nombre + whitespace trap

local Types = require(script.Parent.Types)
local Catalog = require(script.Parent.Catalog)
local NameSignatures = require(script.Parent.NameSignatures)

type Rule = Types.Rule
type SourceFile = Types.SourceFile
type Finding = Types.Finding
type PluginScanResult = Types.PluginScanResult

local WHITESPACE_NEWLINE_THRESHOLD = 50

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

local function checkWhitespaceTrap(sourceFile: SourceFile): Finding?
	local leading = string.match(sourceFile.source, "^%s*") or ""
	local _, newlineCount = string.gsub(leading, "\n", "")
	if newlineCount > WHITESPACE_NEWLINE_THRESHOLD then
		return {
			ruleId = "whitespace_trap",
			severity = "high",
			message = ("Trampa de espacios en blanco (%d líneas vacías al inicio)."):format(newlineCount),
			scriptPath = sourceFile.scriptPath,
			snippet = ("… %d newlines antes del código …"):format(newlineCount),
		}
	end
	return nil
end

local function checkInvisibleChars(sourceFile: SourceFile): Finding?
	-- Zero-width space / non-joiner / joiner
	if string.find(sourceFile.source, "\u{200B}")
		or string.find(sourceFile.source, "\u{200C}")
		or string.find(sourceFile.source, "\u{200D}")
	then
		local startIndex = string.find(sourceFile.source, "\u{200B}")
			or string.find(sourceFile.source, "\u{200C}")
			or string.find(sourceFile.source, "\u{200D}")
			or 1
		return {
			ruleId = "invisible_unicode",
			severity = "high",
			message = "Caracteres Unicode invisibles (zero-width): posible evasión de firmas.",
			scriptPath = sourceFile.scriptPath,
			snippet = makeSnippet(sourceFile.source, startIndex),
		}
	end
	return nil
end

local function checkVirusName(sourceFile: SourceFile): Finding?
	local matched = NameSignatures.matchVirusName(sourceFile.scriptPath)
	if matched then
		return {
			ruleId = "known_virus_name",
			severity = "high",
			message = ("Nombre coincide con firma conocida de virus: \"%s\"."):format(matched),
			scriptPath = sourceFile.scriptPath,
			snippet = matched,
		}
	end
	return nil
end

local function addFinding(findings: { Finding }, seen: { [string]: boolean }, finding: Finding)
	local key = finding.ruleId .. "@" .. finding.scriptPath
	if seen[key] then
		return
	end
	seen[key] = true
	table.insert(findings, finding)
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
		local nameFinding = checkVirusName(sourceFile)
		if nameFinding then
			addFinding(findings, seen, nameFinding)
		end

		local wsFinding = checkWhitespaceTrap(sourceFile)
		if wsFinding then
			addFinding(findings, seen, wsFinding)
		end

		local invFinding = checkInvisibleChars(sourceFile)
		if invFinding then
			addFinding(findings, seen, invFinding)
		end

		for _, rule in ipairs(rules) do
			local finding = matchRuleOnSource(rule, sourceFile)
			if finding then
				addFinding(findings, seen, finding)
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

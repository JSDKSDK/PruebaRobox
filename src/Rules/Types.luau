-- Tipos compartidos del motor (lite)

export type Severity = "high" | "medium" | "info"

export type Badge = "critical" | "review" | "ok" | "unknown"

export type Rule = {
	id: string,
	severity: Severity,
	patterns: { string },
	message: string,
}

export type SourceFile = {
	scriptPath: string,
	source: string,
}

export type Finding = {
	ruleId: string,
	severity: Severity,
	message: string,
	scriptPath: string,
	snippet: string,
}

export type PluginScanResult = {
	pluginId: string,
	pluginName: string,
	origin: string,
	badge: Badge,
	findings: { Finding },
	scriptsScanned: number,
	scriptsFailed: number,
}

local function severityRank(severity: Severity): number
	if severity == "high" then
		return 3
	elseif severity == "medium" then
		return 2
	end
	return 1
end

local function badgeFromFindings(findings: { Finding }): Badge
	if #findings == 0 then
		return "ok"
	end

	local worst = 0
	for _, f in ipairs(findings) do
		worst = math.max(worst, severityRank(f.severity))
	end

	if worst >= 3 then
		return "critical"
	elseif worst >= 2 then
		return "review"
	end
	return "ok"
end

local function badgeLabel(badge: Badge): string
	if badge == "critical" then
		return "🔴"
	elseif badge == "review" then
		return "🟡"
	elseif badge == "ok" then
		return "🟢"
	end
	return "—"
end

local function severityLabel(severity: Severity): string
	if severity == "high" then
		return "ALTO"
	elseif severity == "medium" then
		return "MEDIO"
	end
	return "INFO"
end

return {
	severityRank = severityRank,
	badgeFromFindings = badgeFromFindings,
	badgeLabel = badgeLabel,
	severityLabel = severityLabel,
}

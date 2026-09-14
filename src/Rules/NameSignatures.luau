-- Firmas por nombre (virus clásicos de free models / scripts conocidos)
-- Match cuidadoso: exacto o el nombre termina con la firma (evita "Health" falso).

local EXACT = {
	["s.vaccine"] = true,
	["vaccine"] = true,
	["r.rofl"] = true,
	["rofl"] = true,
	["os.c-rex"] = true,
	["pa/s.firespread"] = true,
	["firespread"] = true,
	["lt/s.4d being"] = true,
	["4d being"] = true,
	["game destroyer"] = true,
	["projectx"] = true,
	["nom"] = true,
	["learn to script"] = true,
	["noot noot"] = true,
	["corrupt"] = true,
	["crasher"] = true,
	["spongebill"] = true,
	["iemotionless lag script"] = true,
}

-- Solo si el nombre del script es exactamente esto (muy genéricos fuera de EXACT)
local EXACT_ONLY_GENERIC = {
	["lag"] = true,
}

local function leafName(scriptPath: string): string
	local leaf = string.match(scriptPath, "[^%.]+$") or scriptPath
	return string.lower(leaf)
end

local function matchVirusName(scriptPath: string): string?
	local name = leafName(scriptPath)
	if EXACT[name] or EXACT_ONLY_GENERIC[name] then
		return name
	end
	return nil
end

return {
	matchVirusName = matchVirusName,
}

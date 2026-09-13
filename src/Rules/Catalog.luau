-- Carga las reglas desde rules.json (Rojo lo expone como ModuleScript)

local Types = require(script.Parent.Types)
type Rule = Types.Rule

local RULES: { Rule } = require(script.Parent:WaitForChild("rules"))

local function getRules(): { Rule }
	return RULES
end

return {
	getRules = getRules,
}

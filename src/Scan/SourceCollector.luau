-- Recolecta Source de scripts bajo un root (plugin en Debug, etc.)

local Types = require(script.Parent.Parent.Rules.Types)
type SourceFile = Types.SourceFile

export type CollectResult = {
	sources: { SourceFile },
	failed: number,
}

local function collect(root: Instance): CollectResult
	local sources: { SourceFile } = {}
	local failed = 0

	local function tryRead(container: LuaSourceContainer)
		local ok, source = pcall(function()
			return container.Source
		end)
		if ok and typeof(source) == "string" then
			table.insert(sources, {
				scriptPath = container:GetFullName(),
				source = source,
			})
		else
			failed += 1
		end
	end

	if root:IsA("LuaSourceContainer") then
		tryRead(root)
	end

	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("LuaSourceContainer") then
			tryRead(d)
		end
	end

	return {
		sources = sources,
		failed = failed,
	}
end

return {
	collect = collect,
}

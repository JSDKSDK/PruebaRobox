-- CANARIO DE PRUEBA — NO usar en producción.
-- Solo para verificar que PluginGuard dispara reglas high/medium.
-- Save as Local Plugin con nombre "PluginGuardCanary".

local HttpService = game:GetService("HttpService")

-- high: loadstring
pcall(function()
	loadstring("return 1")
end)

-- high: require asset id (fallará al correr; el scanner solo lee Source)
pcall(function()
	require(1234567890)
end)

-- high: getfenv
pcall(function()
	getfenv(1)
end)

-- high/medium: HTTP
pcall(function()
	HttpService:PostAsync("https://example.com/hook", "{}")
	HttpService:RequestAsync({ Url = "https://discord.com/api/webhooks/fake", Method = "POST" })
end)

-- medium: ofuscación típica
local s = string.char(114, 101, 113)
local r = string.reverse("eriuqer")

-- high: escritura de Source (patrón inject)
pcall(function()
	local dummy = Instance.new("Script")
	dummy.Source = "-- canary"
	dummy:Destroy()
end)

print("[PluginGuardCanary] loaded — scan me with PluginGuard")

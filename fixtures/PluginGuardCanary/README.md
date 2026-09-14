# Plugin canario (prueba de alertas)

No es malware del Store: es un script **local** con patrones a propósito.

## Cómo probarlo

1. En Studio, crea un `Script` vacío (o carpeta) y pega el contenido de `init.server.luau`,  
   **o** copia el archivo a ServerStorage y ábrelo.
2. Clic derecho → **Save as Local Plugin** → nombre `PluginGuardCanary`.
3. Activa **Plugin Debugging** si hace falta.
4. Abre PluginGuard → **Re-escanear** → selecciona `PluginGuardCanary` → **Escanear este**.

Deberías ver hallazgos 🔴/🟡: `loadstring`, `require_asset`, `getset_fenv`, HTTP, ofuscación, etc.

Luego puedes borrar el `.rbxm` de `Documents/Roblox/Plugins/PluginGuardCanary`.

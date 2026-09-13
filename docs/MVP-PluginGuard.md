# Plan MVP — Auditor de plugins de Roblox Studio

Documento interno del proyecto de prueba (`PruebaRobox` / rama `Integration`).  
Objetivo: dejar por escrito **qué vamos a construir**, **en qué orden**, **qué hay que instalar** y **qué queda para después**.

> Nombre comercial pendiente. En este documento usamos el nombre temporal **PluginGuard**.

---

## 1. Problema que resolvemos

Muchos desarrolladores de Roblox acortan el ciclo de desarrollo instalando plugins (terreno, árboles, animaciones, utilidades, etc.).

En la comunidad también existen plugins poco confiables: a veces por dolo, a veces por error, pueden incluir código que:

- hace cosas no pedidas,
- contacta servidores externos,
- inyecta scripts en el place,
- o se comporta de forma opaca (“caja negra”).

**PluginGuard** no pretende ser un antivirus perfecto. Pretende ser una **herramienta de auditoría heurística** que ayude a revisar plugins y generar un reporte claro (semáforo + motivos).

---

## 2. Visión de producto (2 versiones)

### 2.1 Versión gratuita (MVP)

- Plugin de **Roblox Studio** (corre donde corra Studio: Windows y Mac).
- El usuario lo instala y lo lanza desde la pestaña **Plugins**.
- Escanea plugins y muestra un **reporte en pantalla** (panel DockWidget).
- Reglas de detección **locales**, dentro del plugin, **cifradas/ofuscadas** (speed bump, no secreto absoluto).
- **Sin companion** de escritorio (nada orientado solo a Mac o solo a Windows).
- **Sin AWS** todavía.

### 2.2 Versión de pago / pro (fase 2)

- Backend en **AWS** (u equivalente).
- Reglas avanzadas / secretas en servidor.
- El plugin envía código o fingerprints y recibe **hallazgos**, no el catálogo completo de reglas.
- Posible cuenta, token, actualización de firmas, allowlist de plugins conocidos.
- Mejor resistencia a ingeniería inversa.

---

## 3. Alcance del MVP (qué SÍ / qué NO)

### Sí (MVP)

| Pieza | Descripción |
|-------|-------------|
| Toolbar + botón **Auditar** | Lanza el panel |
| Panel (DockWidget) | Resumen + lista + detalle |
| Modo **Instalados (Debug)** | Requiere Plugin Debugging |
| Modo **AssetId (Creator Store)** | Pegar ID(s) públicos del Store |
| Motor de reglas local | Heurísticas básicas |
| Cifrado local de reglas | Las reglas no van en texto plano trivial |
| Semáforo | 🟢 OK / 🟡 Revisar / 🔴 Sospechoso |
| Mensajes claros | Debug off, ID inválido, sin source, etc. |

### No (MVP)

- App companion de Mac/PC.
- Escanear automáticamente toda la carpeta `InstalledPlugins` del disco.
- Prometer detección 100 % de malware.
- Pagos, cuentas, dashboard web.
- AWS / nube.
- Ofuscación militar como “imposible de revertir”.

---

## 4. Cómo se lanza (UX)

1. Usuario instala PluginGuard (local plugin o, más adelante, Creator Store).
2. Abre Studio en modo edición (**no hace falta Play**).
3. Pestaña **Plugins** → botón **Auditar**.
4. Se abre (o enfoca) el panel dockeable **PluginGuard**.

### Frase de producto

> Activa Plugin Debugging para revisar lo instalado en Studio.  
> Si el plugin es del Creator Store, pega su AssetId y lo auditamos igual.

---

## 4.1 Interfaz detallada (MVP)

### A) Entrada en la cinta de Studio

En la pestaña **Plugins** de Studio:

```
[ PluginGuard ]
   ┌─────────┐
   │ Auditar │  ← un solo botón principal (icono + texto)
   └─────────┘
```

- **Clic en Auditar** → abre/muestra el DockWidget.
- Tooltip: `Auditar plugins instalados o por AssetId`.

### B) Layout en 3 partes (acordado)

El panel principal se divide en **tres columnas/zonas** fijas:

```
┌─ PluginGuard ──────────────────────────────────────────────────────┐
│  [ Re-escanear ]   [ + AssetId ]              Estado: Listo         │
├────────────────────┬─────────────────────┬─────────────────────────┤
│  1) PLUGINS        │  2) RESUMEN / SCAN  │  3) DETALLE             │
│     ENCONTRADOS    │                     │                         │
│                    │                     │                         │
│  Lista de todos    │  Semáforo global    │  Reglas que pegaron     │
│  los plugins que   │  Botón Escanear     │  Snippets               │
│  el auditor pudo   │  Origen Debug/ID    │  Path del script        │
│  descubrir         │  Avisos (debug off) │                         │
│                    │                     │                         │
└────────────────────┴─────────────────────┴─────────────────────────┘
│  Pie: Escaneo heurístico — no prueba ni descarta malware.           │
└─────────────────────────────────────────────────────────────────────┘
```

#### Parte 1 — Lista de plugins encontrados (izquierda)

Muestra **todos** los plugins que el auditor logró descubrir en la sesión actual:

| Origen del ítem | Cómo entra a la lista |
|-----------------|------------------------|
| Debug | Visibles vía Plugin Debugging / `PluginDebugService` |
| AssetId | Tras pegar ID(s) y resolverlos (botón **+ AssetId**) |
| (Futuro) | Otras fuentes — no en MVP |

Cada fila:

```
🟡  Rojo                 Debug
🔴  TreeTool             AssetId 13057…
🟢  MiUtil               Debug
⚪  PluginX              Sin escanear aún
```

- Clic en una fila → selecciona ese plugin (partes 2 y 3 se enfocan en él).
- Checkbox opcional (MVP+): multi-selección para escanear varios.
- Si Debug está off y aún no hay IDs: lista vacía + mensaje.

**Importante (honestidad de producto):**  
“Todos los encontrados” ≠ “todos los que existen en el disco del PC”.  
Solo los que Studio/PluginGuard pueden ver con Debug + AssetIds agregados.

#### Parte 2 — Centro (acciones + resumen)

```
┌─ Centro ─────────────────────────┐
│  Seleccionado: Rojo              │
│  Origen: Debug                   │
│                                  │
│  [ Escanear este ]               │
│  [ Escanear todos los listados ] │
│                                  │
│  Último escaneo: hace 10 s       │
│  Resultado: 🟡 REVISAR           │
│  0 críticos · 2 medium · …       │
│                                  │
│  ⚠ Plugin Debugging: Activado    │
│    (o instrucciones si está OFF) │
└──────────────────────────────────┘
```

#### Parte 3 — Detalle (derecha)

Al tener un plugin escaneado/seleccionado:

```
┌─ Detalle ────────────────────────┐
│  Hallazgos (2)                   │
│                                  │
│  [MEDIO] http_request            │
│  Script: Main                    │
│  “… HttpService:RequestAsync …”  │
│                                  │
│  [MEDIO] external_url            │
│  “… https://…”                   │
│                                  │
│  (Si OK: “Sin hallazgos…”)       │
└──────────────────────────────────┘
```

### C) Flujo de uso típico

1. Abrir panel con **Auditar**.  
2. (Si aplica) activar Plugin Debugging → **Re-escanear** lista.  
3. Ver en la **parte 1** los plugins encontrados.  
4. Opcional: **+ AssetId** para sumar plugins del Store a la misma lista.  
5. **Escanear este** o **Escanear todos**.  
6. Leer semáforo en el centro y detalle a la derecha.

### D) Diálogo / mini-form “+ AssetId”

No hace falta una pestaña aparte si el layout es de 3 columnas. Un botón abre un bloque o modal simple:

```
Agregar por AssetId
┌─────────────────────────────┐
│ 123456789                   │
│ 987654321                   │
└─────────────────────────────┘
[ Agregar a la lista ]  [ Cancelar ]
```

Los IDs agregados aparecen en la parte 1 con origen `AssetId`.

### E) Semáforo

| Badge | Significado |
|-------|-------------|
| 🔴 CRÍTICO | ≥1 regla `high` |
| 🟡 REVISAR | Solo `medium` (o high bajado por allowlist) |
| 🟢 OK | Sin matches relevantes |
| ⚪ / — | Listado pero **aún no escaneado** |

### F) Qué NO lleva la UI del MVP

- Login / paywall  
- Gráficas complejas  
- Editor de reglas  
- Prometer “todos los plugins del disco”

### G) Componentes Roblox (implementación)

| Zona | Instancias típicas |
|------|--------------------|
| Panel | `DockWidgetPluginGui` |
| 3 columnas | 3 `Frame` (o `UIListLayout` horizontal) |
| Lista plugins | `ScrollingFrame` + filas clicables |
| Centro | Labels + `TextButton`s + aviso Debug |
| Detalle | `ScrollingFrame` + labels |
| + AssetId | `TextBox` multilínea + botones |

Tamaño inicial sugerido del DockWidget: ~700×480 px (para que quepan las 3 partes).

---

## 5. Dos modos de obtención de `Source`

El motor de reglas necesita el **código fuente** (`Script` / `LocalScript` / `ModuleScript` → propiedad `Source`).  
Un plugin en ejecución no siempre expone su código en el Explorer; por eso hay dos caminos.

### 5.1 Modo A — Instalados (Plugin Debugging) 【obligatorio para este camino】

**Requisito del usuario:**

1. `File` → `Studio Settings` → `Studio` → activar **Plugin Debugging Enabled**.
2. Reiniciar Studio si hace falta.

**Qué hace PluginGuard:**

1. Comprueba que el modo debug sea usable (p. ej. presencia útil en `PluginDebugService`).
2. Si no → bloquea el escaneo y muestra instrucciones.
3. Si sí → recorre scripts visibles bajo debug.
4. Lee `Source` (desde contexto de plugin) y aplica reglas.

**Cubre:** plugins locales / visibles en depuración.  
**No garantiza:** todos los del Store ni plugins no depurables.

### 5.2 Modo B — Por AssetId (Creator Store)

**Qué es el Store:** plugins instalados desde el Creator Store / toolbox de Roblox (tienda), no solo los `.rbxm` locales de “Save as Local Plugin”.

**Qué es el AssetId:** el número público del asset (aparece en la URL del plugin en create.roblox.com).

**Qué hace PluginGuard:**

1. Usuario pega uno o varios IDs.
2. `game:GetObjects("rbxassetid://ID")`.
3. Parent temporal (carpeta tipo `PluginGuard_Scan` en `ServerStorage`).
4. Recorre `LuaSourceContainer`, lee `Source`, aplica reglas.
5. Borra la carpeta temporal.
6. Si el asset es privado/borrado/no descargable → error claro en el reporte.

**Cubre:** muchos plugins **públicos** del Store.  
**No cubre igual:** privados, eliminados, o que no permitan `GetObjects`.

### 5.3 Combinación

- Misma UI de reporte.
- Cada hallazgo indica origen: `Debug` o `AssetId: 123…`.
- Un solo motor de reglas.

---

## 6. Motor de reglas (fase 1: local + cifrado)

### 6.0 Arquitectura que usaremos (acordada)

El motor es **puro Luau dentro del plugin**, sin red en el MVP.  
Separa tres responsabilidades: **obtener código**, **evaluar reglas**, **presentar resultado**.

```
┌──────────────┐     ┌─────────────────┐     ┌──────────────────┐
│  UI Panel    │────▶│  ScanOrchestrator│────▶│  Rules/Engine    │
│  Escanear    │     │  (por plugin)    │     │  + Payload       │
│  este/todos  │     └────────┬────────┘     └────────▲─────────┘
└──────▲───────┘              │                       │
       │                      ▼                       │
       │              ┌───────────────┐               │
       │              │ CollectSource │               │
       │              │ (Debug root / │               │
       │              │  AssetId tmp) │               │
       │              └───────┬───────┘               │
       │                      │  { path, source }[]   │
       │                      └───────────────────────┘
       │
       │  PluginScanResult (badge + findings)
       └──────────────────────────────────────────────
```

#### Módulos

| Módulo | Rol |
|--------|-----|
| `Scan/DebugScanner` | Ya existe: lista plugins en `PluginDebugService` |
| `Scan/AssetIdScanner` | (Después) trae source por AssetId |
| `Scan/SourceCollector` | Dado un `root` Instance → recorre `LuaSourceContainer` → lee `.Source` con `pcall` |
| `Rules/Types` | Tipos: `Rule`, `Finding`, `PluginScanResult`, severidades |
| `Rules/Payload` | Blob cifrado + `loadRules()` → `{ Rule }` en memoria |
| `Rules/Allowlist` | Nombres/dominios conocidos → bajar severidad o ignorar |
| `Rules/Engine` | `scanSources(sources, rules) → findings` + badge peor severidad |
| `Scan/Orchestrator` | Une todo: plugin seleccionado → collect → engine → UI |
| `UI/MainPanel` | Muestra badge en lista + hallazgos en columna 3 |

#### Flujo al pulsar “Escanear este”

1. UI pasa el `id` / `root` del plugin seleccionado (Debug ya lo guardamos en `rootsById`).
2. `SourceCollector.collect(root)` → lista `{ scriptPath, source }`.
3. `Payload.loadRules()` (descifra una vez, cache en memoria de la sesión).
4. `Engine.scan(sources, rules, allowlist)` → `findings[]`.
5. Calcula badge: `high`→🔴, solo `medium`→🟡, vacío→🟢, error de lectura→⚪/aviso.
6. UI actualiza fila + columna detalle + resumen centro.

“Escanear todos” = el mismo flujo en loop sobre la lista.

#### Contrato de datos

**Rule (tras decrypt):**

```lua
{
  id = "loadstring",
  severity = "high", -- "high" | "medium" | "info"
  patterns = { "loadstring%s*%(" }, -- Lua patterns
  message = "Uso de loadstring (código dinámico).",
}
```

**Finding:**

```lua
{
  ruleId = "loadstring",
  severity = "high",
  message = "...",
  scriptPath = "PluginGuard.Main",
  snippet = "… loadstring( …", -- recorte ~120 chars
  lineHint = 42, -- opcional si podemos estimarla
}
```

**PluginScanResult:**

```lua
{
  pluginId = "debug:Rojo:1",
  pluginName = "Rojo",
  origin = "Debug",
  badge = "critical" | "review" | "ok" | "unknown",
  findings = { Finding },
  scriptsScanned = 3,
  scriptsFailed = 0,
}
```

#### Cifrado (fase 1, sin cambiar la arquitectura del Engine)

```
tools/encrypt_rules  →  Rules/Payload.luau (blob)
                              │
                         loadRules()
                              ▼
                         { Rule }  →  Engine (nunca ve el blob)
```

El Engine **solo recibe reglas ya en claro en memoria**. Así más adelante AWS puede sustituir `Payload.loadRules()` por `Cloud.fetchScan()` sin reescribir el Engine.

#### Qué no metemos en el Engine (aún)

- Red / AWS  
- Machine learning  
- Análisis AST completo (solo patterns sobre texto)  
- Persistencia de reportes en disco  

#### Orden de implementación sugerido

1. `Rules/Types` + `Rules/Engine` con reglas **en claro** (dev)  
2. `SourceCollector` + botones Escanear este / todos  
3. Pintar findings en UI (badge + detalle)  
4. Mover reglas a `Payload` cifrado  
5. Allowlist mínima (p. ej. Rojo)

---

### 6.1 Formato propuesto de una regla

```lua
{
  id = "loadstring",
  severity = "high", -- high | medium | info
  -- patrón o lista de patrones (tras descifrar)
  patterns = { "loadstring%s*%(" },
  message = "Uso de loadstring (código dinámico).",
}
```

Salida de un match:

```lua
{
  pluginName = "...",
  origin = "Debug" | "AssetId:123",
  scriptPath = "...",
  ruleId = "loadstring",
  severity = "high",
  snippet = "...",
}
```

### 6.2 Set mínimo inicial (8 reglas para probar)

| ID | Severidad | Idea |
|----|-----------|------|
| `loadstring` | high | Ejecución dinámica |
| `httpget` | high | `HttpGet` / `HttpGetAsync` |
| `getset_fenv` | high | `getfenv` / `setfenv` |
| `http_request` | medium | `RequestAsync` / `PostAsync` / `HttpService` |
| `require_asset` | medium | `require(` + número largo |
| `inject_sss` | high | Crear scripts / escribir `Source` hacia `ServerScriptService` |
| `obfuscation_blob` | medium | Strings enormes / poca legibilidad |
| `external_url` | medium | `http://` / `https://` fuera de allowlist |

**Allowlist inicial de ejemplos (bajar severidad):** dominios/herramientas conocidas (p. ej. Rojo) — se irá afinando a mano.

### 6.3 Cifrado local de reglas (paso 1 acordado)

- Las reglas **no** van en texto trivial en el repo publicado / plugin.
- Flujo:
  1. Mantener un archivo fuente de reglas en el equipo de desarrollo (privado).
  2. Script de build (o paso manual) que **cifra** el payload.
  3. El plugin guarda un **blob cifrado**.
  4. Al Auditar: descifra en memoria → aplica → no imprime el catálogo completo en Output.
- Objetivo: dificultar la lectura casual.
- Límite: la clave/lógica de descifrado también está en el cliente → **no es secreto absoluto**. Ingeniería inversa avanzada sigue siendo posible.

### 6.4 Copy legal / honestidad del producto

> Escaneo heurístico. 🟡/🔴 no prueba malware. 🟢 no garantiza seguridad. Revisar hallazgos con criterio.

---

## 7. Fase 2 — AWS (acordado como segundo paso)

Cuando el MVP local funcione:

1. API HTTPS (ej. API Gateway + Lambda, o contenedor en ECS/Fargate; el detalle se elige después).
2. BD de reglas (p. ej. Postgres / DynamoDB).
3. Endpoint principal propuesto: `POST /v1/scan`
   - Entrada: fragmentos de source / metadata / token.
   - Salida: hallazgos (sin devolver todas las reglas).
4. Auth (API key o cuenta).
5. El plugin free puede seguir offline; el pro usa cloud.

**Alternativas válidas a AWS** si más adelante conviene: Cloudflare Workers, Railway, Fly.io, Vercel + DB. AWS queda como opción acordada de fase 2.

---

## 8. Arquitectura técnica del repo (MVP)

Estructura orientativa (a crear/evolucionar desde el repo actual):

```
Plugin/
├── default.project.json      # Rojo → sync a Studio
├── rokit.toml                # versión de Rojo del equipo
├── .gitignore
├── docs/
│   └── MVP-PluginGuard.md    # este documento
├── src/
│   ├── init.server.luau      # entry del plugin (toolbar + wiring)
│   ├── UI/                   # DockWidget, listas, pestañas
│   ├── Scan/
│   │   ├── DebugScanner.luau
│   │   └── AssetIdScanner.luau
│   ├── Rules/
│   │   ├── Engine.luau       # aplica reglas al source
│   │   └── Payload.luau      # blob cifrado + decrypt
│   └── Util/
└── tools/                    # (opcional) cifrar reglas antes de empaquetar
```

Flujo de desarrollo (ya probado en el sandbox):

```
Editar src/  →  rojo serve  →  Studio (plugin Rojo Connect)
     → ServerStorage.PruebaPlugin (o nombre final)
     → Save as Local Plugin
     → Probar en pestaña Plugins
```

---

## 9. Pasos de implementación (checklist)

### Fase 0 — Base (parcialmente hecha en el sandbox)

- [x] Repo GitHub de prueba + rama `Integration`
- [x] Rojo + Rokit instalados en el entorno de desarrollo
- [x] Sync básico plugin demo (`Hola` / hola mundo)
- [ ] Renombrar/estructurar el plugin hacia **PluginGuard** (cuando se decida)
- [ ] Commit del plan y del esqueleto en `Integration`

### Fase 1 — Esqueleto UI

- [ ] Toolbar `PluginGuard` + botón `Auditar`
- [ ] `DockWidgetPluginGui` con título y layout básico
- [ ] Pestañas: **Instalados** | **AssetId**
- [ ] Zona de resumen + lista (aunque sea con datos fake al inicio)
- [ ] Botón Re-escanear

### Fase 2 — Modo Debug

- [ ] Detectar / exigir Plugin Debugging
- [ ] UI de bloqueo con instrucciones si está off
- [ ] Enumerar scripts bajo `PluginDebugService` (o estrategia equivalente)
- [ ] Leer `Source` con `pcall`
- [ ] Pasar textos al motor de reglas
- [ ] Pintar resultados reales

### Fase 3 — Modo AssetId

- [ ] Input de texto (uno o varios IDs)
- [ ] `GetObjects` + carpeta temporal
- [ ] Escaneo + limpieza
- [ ] Manejo de errores (ID malo, privado, vacío)
- [ ] Marcar origen `AssetId:…` en el reporte

### Fase 4 — Reglas + cifrado local

- [ ] Definir las 8 reglas mínimas en formato estructurado
- [ ] Implementar `Engine` (match → severity → snippet)
- [ ] Allowlist mínima
- [ ] Pipeline de cifrado del payload + decrypt en runtime
- [ ] No filtrar reglas completas a Output

### Fase 5 — Pulido MVP

- [ ] Textos de ayuda / limitaciones
- [ ] Contador de clics / vacío de resultados
- [ ] Probar con plugins buenos (Rojo) y casos sintéticos malos (fixtures propios)
- [ ] Documentar instalación para el compañero
- [ ] Preparar mensaje free vs pro (sin implementar pagos)

### Fase 6 — AWS (después del MVP)

- [ ] Diseñar contrato `POST /v1/scan`
- [ ] Levantar API + almacenamiento de reglas
- [ ] Auth básica
- [ ] Integrar modo “Cloud Scan” en el plugin
- [ ] Mover reglas avanzadas fuera del cliente

---

## 10. Qué hay que instalar / configurar

### 10.1 Para desarrollar (equipo)

| Herramienta | Para qué | Notas |
|-------------|----------|--------|
| **Roblox Studio** | Editor + probar el plugin | Win / Mac |
| **Git + GitHub** | Versionado (`main`, `QA`, `Integration`, etc.) | Repo de prueba ya existe |
| **Rokit** | Gestor de toolchain | Ya usado en el sandbox |
| **Rojo** (vía Rokit) | Sync `src/` ↔ Studio | `rokit.toml` fija versión |
| **Plugin Rojo en Studio** | Connect a `localhost:34872` | `rojo plugin install` |
| Editor (Cursor / VS Code / etc.) | Editar Luau | Opcional pero recomendado |

Comandos típicos de desarrollo:

```bash
# en la raíz del repo
rojo serve
```

En Studio: Plugins → Rojo → Connect → trabajar → **Save as Local Plugin** al probar el auditor como plugin real.

### 10.2 Para que el *usuario final* use PluginGuard (MVP)

| Requisito | Obligatorio |
|-----------|-------------|
| Roblox Studio | Sí |
| Instalar el plugin PluginGuard | Sí |
| **Plugin Debugging Enabled** | Sí para modo Instalados |
| Conocer AssetId | Sí para modo Store |
| Rojo | No |
| Rokit | No |
| AWS / cuenta cloud | No (MVP) |
| Companion de escritorio | No |

Ruta de settings del requisito Debug:

`File → Studio Settings → Studio → Plugin Debugging Enabled`

### 10.3 Para la fase AWS (después)

| Pieza | Para qué |
|-------|----------|
| Cuenta AWS | Hosting API |
| Dominio + HTTPS | Endpoint seguro |
| BD de reglas | Guardar firmas/heurísticas pro |
| Posible usuario/token | Licencia / rate limit |

Detalle de servicios exactos (Lambda vs EC2, etc.) se decide en fase 6.

---

## 11. Limitaciones técnicas (no olvidar)

1. **No hay API oficial de “lista todos los plugins y dame su source”.**
2. `PluginDebugService` solo ayuda con debug activo y plugins depurables.
3. AssetId depende de que el asset sea obtenible públicamente.
4. Heurísticas ≠ prueba forense de malware.
5. Cifrado local ≠ reglas secretas de verdad.
6. Plugins legítimos (p. ej. Rojo) dispararán reglas de red → hace falta allowlist y buen copy.
7. No escanear disco `InstalledPlugins` desde el plugin de forma portable multi-OS en el MVP.

---

## 12. Criterios de “MVP listo”

Se considera MVP demostrable cuando:

1. Se puede instalar PluginGuard y abrir el panel con **Auditar**.
2. Con Debug ON, lista al menos los plugins visibles y genera reporte.
3. Con un AssetId público de prueba, descarga, escanea y limpia.
4. Las 8 reglas mínimas producen hallazgos en fixtures de prueba.
5. Las reglas empaquetadas no están en claro trivial (cifrado local activo).
6. El panel explica limitaciones y el requisito de Plugin Debugging.
7. El flujo funciona en Studio sin companion y sin AWS.

---

## 13. Decisiones ya acordadas

| Tema | Decisión |
|------|----------|
| Plataforma del MVP | Solo plugin de Studio (Win/Mac vía Studio) |
| Companion escritorio | No por ahora |
| Modos de scan | Debug (obligatorio para instalados) + AssetId |
| Reglas fase 1 | Locales + cifradas en el plugin |
| Reglas fase 2 | Servidor (AWS) |
| Repo actual | Prueba / sandbox; el “real” puede venir después |
| Rama de trabajo actual | `Integration` |

---

## 14. Próximo paso sugerido

1. Congelar este documento como referencia del equipo.  
2. Montar el **esqueleto** en `src/`: toolbar + DockWidget + 2 pestañas vacías.  
3. Implementar detección del requisito **Plugin Debugging**.  
4. Meter el motor con 8 reglas (primero en claro en dev; cifrar al empaquetar).

---

## 15. Referencias útiles

- [Studio plugins (Creator Hub)](https://create.roblox.com/docs/studio/plugins)
- [Rojo](https://rojo.space/)
- [Studio MCP (opcional, para desarrollo con agentes)](https://create.roblox.com/docs/studio/mcp)
- Plugin Debugging: Studio Settings → Studio → Plugin Debugging Enabled

---

*Última actualización: documento generado para alinear el MVP de PluginGuard (auditor heurístico de plugins) con cifrado local primero y AWS después.*

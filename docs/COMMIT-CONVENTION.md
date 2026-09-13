# Convención de commits (PluginGuard)

Usamos **Conventional Commits** (simple). Así el historial se entiende rápido entre el equipo.

## Formato

```text
tipo(alcance opcional): resumen en imperativo, máximo ~72 caracteres

[cuerpo opcional: por qué / contexto]
```

## Tipos permitidos

| Tipo | Cuándo |
|------|--------|
| `feat` | Nueva funcionalidad visible |
| `fix` | Corrección de bug |
| `docs` | Solo documentación |
| `refactor` | Cambio interno sin feat/fix |
| `chore` | Tooling, deps, gitignore, Rojo, etc. |
| `style` | Formato, sin cambio de lógica |
| `test` | Tests |

## Alcances útiles (opcionales)

`ui` · `scan` · `rules` · `rojo` · `docs`

## Ejemplos

```text
feat(ui): add PluginGuard panel with three columns
feat(scan): list plugins from PluginDebugService
feat(rules): add heuristic engine and rules.json
docs: add MVP plan and commit convention
chore: add Rojo project and Rokit toolchain
fix(ui): keep selected plugin after rescan
```

## Reglas del equipo

1. Un commit = una idea coherente (no mezclar UI + AWS + docs gigantes sin necesidad).
2. Resumen en **inglés** (más estándar en Git) o español, pero **elige uno y manténlo** — recomendado: **inglés**.
3. No commits vacíos ni “wip” en `main` / `QA`; en `Integration` se tolera `wip:` solo temporal.
4. No subir secretos, `.rbxl`, builds ni plugins locales (`*.rbxm` ya van en `.gitignore`).

## Flujo de ramas (recordatorio)

`Integration` (trabajo) → `QA` → `main`

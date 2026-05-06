# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

Agentic skill set for scaffolding and developing AutoCAD .NET plugins targeting **AutoCAD 2027** products (.NET 10, x64). Civil 3D and Plant 3D are vertical toolsets built on top of the AutoCAD base platform — all share the AutoCAD base APIs and assembly loading model.

## Target Stack

| Item | Value |
|------|-------|
| Target Framework | `net10.0-windows` |
| Platform | `win-x64` |
| AutoCAD base NuGet | `AutoCAD.NET 26.0.0` (desktop) / `AutoCAD.NET.Core 26.0.0` (DA/headless) |
| Civil 3D NuGet | `Civil3D.NET 13.9.628` |
| Plant 3D | Local SDK — no NuGet (see [Configurable Paths](#configurable-paths)) |

## Configurable Paths

These differ per developer machine. When generating code, substitute real values or prompt the user.

| Variable | Suggested Default | Description |
|----------|------------------|-------------|
| `ACAD_HOME` | `C:\Program Files\Autodesk\AutoCAD 2027` | AutoCAD install directory |
| `PLANT_SDK` | *(none — must be set)* | Path to Plant 3D SDK `inc-x64\` folder |

**Plant SDK download:** https://aps.autodesk.com/developer/overview/autocad-plant-3d-objectarx-sdk-downloads

If `PLANT_SDK` is not set, ask the user for the path before generating any Plant 3D `.csproj`.

## Product → Template Map

| Product | dotnet template | NuGet packages added after scaffold |
|---------|----------------|--------------------------------------|
| AutoCAD (desktop) | `dotnet new acad` | `AutoCAD.NET 26.0.0` |
| AutoCAD (Design Automation) | `dotnet new acad` | *(Core already wired by template)* |
| Civil 3D | `dotnet new civil` | `Civil3D.NET 13.9.628` |
| Plant 3D | Manual csproj | `AutoCAD.NET.Core 26.0.0` + SDK DLL refs |

### Verify / install templates

```bash
dotnet new list | grep -E "acad|civil"
```

If missing, you can install them manually from the bundled templates in this repository:

```bash
# AutoCAD template
dotnet new install ./templates/acad

# Civil 3D template
dotnet new install ./templates/civil
```
*(Note: If you use the `npx` installation script, these templates are automatically registered for you).*

## Uninstalling the skill pack

The `npx` installer **copies** files into your project and **registers** the `dotnet new acad` / `civil` template packages on your machine. For safety it **does not** delete anything from your repo when you run uninstall — you remove copied folders yourself so merged `.cursor` rules, custom edits under `skills/`, and the rest of `.github/` are never wiped by mistake.

### 1. Unregister the .NET templates (machine-wide)

```bash
npx github:ADN-DevTech/acad-api-skill uninstall
```

From a **clone** of this repository (same effect):

```bash
node bin/install.js uninstall
```

That runs `dotnet new uninstall` on the `templates/acad` and `templates/civil` folders that belong to this package. Assistant flags like `-a cursor` do not apply here.

**If that misses entries** (for example an old npx cache path), list everything and remove by the exact path shown:

```bash
dotnet new uninstall
```

Copy and run each printed `dotnet new uninstall <path>` line for the `acad` / `civil` packages you want gone.

**If you installed templates from a clone** with `dotnet new install ./templates/...`, reverse with the same paths:

```bash
dotnet new uninstall ./templates/acad
dotnet new uninstall ./templates/civil
```

### 2. Delete copied files from the project

In the **project folder where you ran install**, delete the paths below. After every successful install, the script also prints **absolute paths** on this machine; treat that output as the checklist for your copy.

| Install command | Remove (relative to that project root) |
|-----------------|----------------------------------------|
| `npx …` default (all assistants) | `skills/`, `.cursor/`, `.github/`, `CLAUDE.md` |
| `npx … -a cursor` | `skills/`, `.cursor/` |
| `npx … -a github-copilot` | `skills/`, `.github/` — often only `.github/copilot-instructions.md` if the rest of `.github/` is yours |
| `npx … -a claude` | `skills/`, `CLAUDE.md` |

If you **merged** into an existing `.cursor/rules/` tree, delete only the files this pack added (for example `acad-plugin.mdc`), not the whole `.cursor/` folder.

### 3. Undo global manual setup

If you followed README **Manual Installation** into `%USERPROFILE%\.cursor\`, VS Code Copilot settings, or Claude global config, remove those copies or settings separately.

Full narrative for humans is also in [`README.md`](README.md) (Quick Start → Uninstall).

## Scaffold Skills

See [`skills/scaffold.md`](skills/scaffold.md) — agentic steps to create a project end-to-end.

## API Reference Skills

| Skill | When to apply |
|-------|--------------|
| [`skills/autocad-api.md`](skills/autocad-api.md) | Base AutoCAD .NET: assembly/DLL map, transactions, entities, plotting, events, accoreconsole flags, common gotchas |
| [`skills/civil3d-api.md`](skills/civil3d-api.md) | Civil 3D: alignments, surfaces, corridors, pipe networks, COGO points, Data Shortcuts (DREFs) |
| [`skills/plant3d-api.md`](skills/plant3d-api.md) | Plant 3D: world map, P&ID objects, data manager, pipe routing |
| [`skills/code-sleuth.md`](skills/code-sleuth.md) | Locating SDK samples and navigating API docs |
| [`skills/learnings.md`](skills/learnings.md) | Append-only log of new discoveries — review before promoting to skill files |

## Autodesk Help MCP Server

For AI-assisted doc lookup, connect the Autodesk Help MCP server. See `skills/autocad-api.md` > "Autodesk Help MCP Server" for VS Code / Cursor / Claude Desktop setup.

Endpoint: `https://developer.api.autodesk.com/knowledge/public/v1/mcp`

## Tooling Prerequisites

| Tool | Check | Install |
|------|-------|---------|
| `dotnet` | `dotnet --version` | https://dot.net |
| `rg` (ripgrep) | `rg --version` | `winget install BurntSushi.ripgrep.MSVC` |

If a required tool is missing, prompt the user to install it before proceeding. After `winget` install, a new terminal session is needed for `PATH` to update.

## Universal Rules for All Plugins

- Framework: `net10.0-windows`, platform `<PlatformTarget>x64</PlatformTarget>`, `<Nullable>enable</Nullable>`
- **Use `<PlatformTarget>x64</PlatformTarget>` instead of `<RuntimeIdentifier>`** unless explicitly bringing in cross-platform native NuGet packages (like Oracle). If `RuntimeIdentifier` is needed, use `<AppendRuntimeIdentifierToOutputPath>false</AppendRuntimeIdentifierToOutputPath>` or ensure bundle paths point to the correct subfolder so AutoCAD can probe it.
- **Never copy host DLLs to output.** AutoCAD/Civil/Plant assemblies: `ExcludeAssets="runtime"` (NuGet) or `<Private>false</Private>` (direct refs)
- Entry points auto-registered via `[assembly: ExtensionApplication]` and `[assembly: CommandClass]` -- no manual registration
- Desktop loading: `NETLOAD` or ApplicationPlugins bundle (`%APPDATA%\Autodesk\ApplicationPlugins\`)
- Design Automation (headless): use `AutoCAD.NET.Core` + `AutoCAD.NET.Model` only -- no `AutoCAD.NET` (AcMgd.dll)
- accoreconsole: same Core-only rule; use `/al` with `/isolate` for bundle loading, or `SECURELOAD 0` + `NETLOAD`
- All toolset API calls must be on the **main AutoCAD thread** — not thread-safe
- `DocumentLock` required for any write operation: `using (doc.LockDocument()) { ... }`

## Learning Accumulation

When you discover a new gotcha, API behavior, workaround, or corrected pattern during a development session that is **not already documented** in the skill files:

1. **Check first.** Search the existing skill files (`autocad-api.md`, `civil3d-api.md`, `plant3d-api.md`, `scaffold.md`) to confirm the discovery is genuinely new.
2. **Append to [`skills/learnings.md`](skills/learnings.md)** with today's date, category, and a concise description. Include the exact error message or API signature if applicable.
3. **Do NOT modify the main skill files directly.** Learnings must be reviewed and verified by a human before promotion. This prevents hallucinated API facts from contaminating the verified skill database.
4. **Cite your source.** Note how the discovery was verified — SDK sample path, runtime error output, official docs URL, or `rg` search result.


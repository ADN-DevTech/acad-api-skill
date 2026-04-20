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

If missing, install from the source repos (template packages must be installed once per machine):

```bash
# AutoCAD template — install from published NuGet or local clone
dotnet new install <source>

# Civil 3D template — from https://github.com/MadhukarMoogala/CivilClassLibTemplate
cd <cloned-repo>/Civil
dotnet new install .
```

## Scaffold Skills

See [`skills/scaffold.md`](skills/scaffold.md) — agentic steps to create a project end-to-end.

## API Reference Skills

| Skill | When to apply |
|-------|--------------|
| [`skills/autocad-api.md`](skills/autocad-api.md) | Base AutoCAD .NET: transactions, entities, commands, selection |
| [`skills/civil3d-api.md`](skills/civil3d-api.md) | Civil 3D: COGO points, alignments, surfaces, parcels |
| [`skills/plant3d-api.md`](skills/plant3d-api.md) | Plant 3D: world map, P&ID objects, data manager, pipe routing |
| [`skills/code-sleuth.md`](skills/code-sleuth.md) | Locating SDK samples and navigating API docs |

## Tooling Prerequisites

| Tool | Check | Install |
|------|-------|---------|
| `dotnet` | `dotnet --version` | https://dot.net |
| `rg` (ripgrep) | `rg --version` | `winget install BurntSushi.ripgrep.MSVC` |

If a required tool is missing, prompt the user to install it before proceeding. After `winget` install, a new terminal session is needed for `PATH` to update.

## Universal Rules for All Plugins

- Framework: `net10.0-windows`, platform `win-x64`, `<Nullable>enable</Nullable>`
- **Never copy host DLLs to output.** AutoCAD/Civil/Plant assemblies: `ExcludeAssets="runtime"` (NuGet) or `<Private>false</Private>` (direct refs)
- Entry points auto-registered via `[assembly: ExtensionApplication]` and `[assembly: CommandClass]` — no manual registration
- Load in AutoCAD: `NETLOAD` → `bin\Debug\net10.0-windows\<Plugin>.dll`
- Design Automation (headless): use `AutoCAD.NET.Core` only — no WPF/WinForms references
- All toolset API calls must be on the **main AutoCAD thread** — not thread-safe
- `DocumentLock` required for any write operation: `using (doc.LockDocument()) { ... }`

# GitHub Copilot Instructions — AutoCAD .NET Plugin Development

This repository is an agentic skill set for building AutoCAD 2027 .NET plugins. See `CLAUDE.md` for full guidance.

## Target stack

- .NET 10 (`net10.0-windows`), `<PlatformTarget>x64</PlatformTarget>`
- `AutoCAD.NET 26.0.0` (desktop) or `AutoCAD.NET.Core 26.0.0` + `AutoCAD.NET.Model 26.0.0` (DA/headless)
- `Civil3D.NET 13.9.628` for Civil 3D toolset
- Plant 3D: local SDK DLL references -- path in `PLANT_SDK` env var / MSBuild property

## When generating plugin code

1. Check `skills/scaffold.md` for project setup, testing, and deployment steps
2. Check `skills/autocad-api.md` for assembly/DLL map, plotting, accoreconsole flags, and common gotchas
3. Check `skills/civil3d-api.md` or `skills/plant3d-api.md` for product-specific patterns
4. Check `skills/code-sleuth.md` for SDK sample locations before inventing API usage
5. Never copy AutoCAD/Civil/Plant assemblies to output (`ExcludeAssets="runtime"` or `Private=false`)
6. Use `<PlatformTarget>x64</PlatformTarget>` instead of `<RuntimeIdentifier>` (unless required for cross-platform native NuGet dependencies like Oracle).
7. Wrap all write operations in `DocumentLock`
8. All toolset API calls on main AutoCAD thread only
9. For DA/headless: use `AutoCAD.NET.Core` + `AutoCAD.NET.Model` only (no AcMgd.dll)
10. When discovering new gotchas or API behaviors not in the skill files, append to `skills/learnings.md` — never edit main skill files directly

## Uninstalling the skill pack

See `CLAUDE.md` section **Uninstalling the skill pack**: run `npx github:ADN-DevTech/acad-api-skill uninstall` to unregister `dotnet new` templates, then delete the copied `skills/` (and `.cursor/`, `.github/`, `CLAUDE.md` as applicable) from the project where install was run. The installer prints absolute paths after a successful install.

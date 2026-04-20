# GitHub Copilot Instructions — AutoCAD .NET Plugin Development

This repository is an agentic skill set for building AutoCAD 2027 .NET plugins. See `CLAUDE.md` for full guidance.

## Target stack

- .NET 10 (`net10.0-windows`), `win-x64`
- `AutoCAD.NET 26.0.0` (desktop) or `AutoCAD.NET.Core 26.0.0` (Design Automation)
- `Civil3D.NET 13.9.628` for Civil 3D toolset
- Plant 3D: local SDK DLL references — path in `PLANT_SDK` env var / MSBuild property

## When generating plugin code

1. Check `skills/scaffold.md` for project setup steps
2. Check `skills/plant3d-api.md` or `skills/civil3d-api.md` for product-specific patterns
3. Check `skills/code-sleuth.md` for SDK sample locations before inventing API usage
4. Never copy AutoCAD/Civil/Plant assemblies to output (`ExcludeAssets="runtime"` or `Private=false`)
5. Wrap all write operations in `DocumentLock`
6. All toolset API calls on main AutoCAD thread only

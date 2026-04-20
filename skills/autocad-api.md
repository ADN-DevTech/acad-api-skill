# AutoCAD .NET API — References

Base AutoCAD .NET patterns (transactions, commands, entities, selection, prompts) are well-documented. Use official references rather than this file.

## Official Docs (AutoCAD 2027)

| Resource | Link |
|----------|------|
| Developer's Guide | https://help.autodesk.com/view/OARX/2027/ENU/ |
| Managed .NET API Reference | https://help.autodesk.com/view/OARX/2027/ENU/?guid=GUID-B1C7E6C8-C90E-4E55-BEB7-B8D08FFE8B21 |
| NuGet: `AutoCAD.NET` | https://www.nuget.org/packages/AutoCAD.NET |

## Version-Specific Facts (2027)

- NuGet package: `AutoCAD.NET 26.0.0` (desktop), `AutoCAD.NET.Core 26.0.0` (Design Automation / headless)
- Target framework: `net10.0-windows`, platform `win-x64`
- AutoCAD internal version: 26.x
- All packages: `ExcludeAssets="runtime"` — AutoCAD loads assemblies from its install directory

## When to use Core vs Full

| Scenario | Package |
|----------|---------|
| Desktop plugin (NETLOAD) | `AutoCAD.NET 26.0.0` |
| Design Automation (cloud/headless) | `AutoCAD.NET.Core 26.0.0` only — no WPF/WinForms |
| Vertical toolset base | `AutoCAD.NET.Core` (toolset adds its own UI assemblies) |

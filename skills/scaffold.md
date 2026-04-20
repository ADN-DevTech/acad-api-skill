# Scaffold Skill — AutoCAD .NET Plugins

Agentic steps to create a new plugin project end-to-end. Execute these steps in order.

## Step 0 — Identify the target product

| User says | Target | Template | Extra packages |
|-----------|--------|----------|----------------|
| "AutoCAD plugin" / "acad add-in" | AutoCAD 2027 | `acad` | `AutoCAD.NET 26.0.0` |
| "Civil 3D plugin" / "c3d add-in" | Civil 3D 2027 | `civil` | `Civil3D.NET 13.9.628` |
| "Plant 3D plugin" / "plant add-in" | Plant 3D 2027 | *(manual)* | `AutoCAD.NET.Core 26.0.0` + SDK DLL refs |
| "Design Automation" / "DA" | Any (headless) | `acad` | *(Core already wired)* |

---

## Step 1 — Scaffold

### AutoCAD

```bash
dotnet new acad -n <ProjectName> -o <ProjectName>
cd <ProjectName>
```

### Civil 3D

```bash
dotnet new civil --rootNamespace=<ProjectName> -o <ProjectName>
cd <ProjectName>
```

### Plant 3D (manual)

Create `<ProjectName>/<ProjectName>.csproj`:

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Library</OutputType>
    <TargetFramework>net10.0-windows</TargetFramework>
    <RuntimeIdentifier>win-x64</RuntimeIdentifier>
    <Nullable>enable</Nullable>
    <RootNamespace>$(MSBuildProjectName)</RootNamespace>
    <GenerateTargetFrameworkAttribute>false</GenerateTargetFrameworkAttribute>
  </PropertyGroup>

  <ItemGroup>
    <FrameworkReference Include="Microsoft.WindowsDesktop.App" />
    <PackageReference Include="AutoCAD.NET.Core" Version="26.0.0" ExcludeAssets="runtime" />
    <PackageReference Include="AutoCAD.NET.Model" Version="26.0.0" ExcludeAssets="runtime" />
  </ItemGroup>

  <!-- Plant 3D SDK — PLANT_SDK = path to inc-x64\ folder -->
  <!-- Download SDK: https://aps.autodesk.com/developer/overview/autocad-plant-3d-objectarx-sdk-downloads -->
  <ItemGroup>
    <Reference Include="PnIDMgd">
      <HintPath>$(PLANT_SDK)\PnIDMgd.dll</HintPath>
      <Private>false</Private>
    </Reference>
    <Reference Include="PnPDataLinks">
      <HintPath>$(PLANT_SDK)\PnPDataLinks.dll</HintPath>
      <Private>false</Private>
    </Reference>
    <Reference Include="PnPDataObjects">
      <HintPath>$(PLANT_SDK)\PnPDataObjects.dll</HintPath>
      <Private>false</Private>
    </Reference>
    <Reference Include="PnPProjectManagerMgd">
      <HintPath>$(PLANT_SDK)\PnPProjectManagerMgd.dll</HintPath>
      <Private>false</Private>
    </Reference>
    <Reference Include="PnPCommonMgd">
      <HintPath>$(PLANT_SDK)\PnPCommonMgd.dll</HintPath>
      <Private>false</Private>
    </Reference>
    <Reference Include="PnPCommonDbxMgd">
      <HintPath>$(PLANT_SDK)\PnPCommonDbxMgd.dll</HintPath>
      <Private>false</Private>
    </Reference>
    <Reference Include="PnIdProjectPartsMgd">
      <HintPath>$(PLANT_SDK)\PnIdProjectPartsMgd.dll</HintPath>
      <Private>false</Private>
    </Reference>
  </ItemGroup>
</Project>
```

Set `PLANT_SDK` as an MSBuild property, environment variable, or `Directory.Build.props`:

```xml
<!-- Directory.Build.props (repo root) -->
<Project>
  <PropertyGroup>
    <PLANT_SDK Condition="'$(PLANT_SDK)'==''">D:\SDKS\Plant2027\inc-x64</PLANT_SDK>
  </PropertyGroup>
</Project>
```

Create the entry point `App.cs`:

```csharp
using Autodesk.AutoCAD.Runtime;

[assembly: ExtensionApplication(typeof(<ProjectName>.App))]
[assembly: CommandClass(typeof(<ProjectName>.Commands))]

namespace <ProjectName>;

public class App : IExtensionApplication
{
    public void Initialize() { }
    public void Terminate() { }
}
```

---

## Step 2 — Update framework (if template generated older target)

If the scaffolded `.csproj` shows `net8.0-windows` or `net6.0-windows`, update it:

```bash
# In the .csproj, replace:
# <TargetFramework>net8.0-windows</TargetFramework>
# with:
# <TargetFramework>net10.0-windows</TargetFramework>
```

---

## Step 3 — Add variant packages

### AutoCAD (desktop testing)

```bash
dotnet add package AutoCAD.NET --version 26.0.0
```

### Civil 3D

```bash
dotnet add package Civil3D.NET --version 13.9.628
```

> Plant 3D packages are already in the manual csproj from Step 1.

---

## Step 4 — Add launchSettings.json

Create `Properties/launchSettings.json`. Replace `<ACAD_HOME>` with the AutoCAD install path (e.g. `C:\Program Files\Autodesk\AutoCAD 2027` or prompt the user).

### AutoCAD

```json
{
  "profiles": {
    "<ProjectName>": { "commandName": "Project" },
    "AutoCAD2027": {
      "commandName": "Executable",
      "executablePath": "<ACAD_HOME>\\acad.exe"
    }
  }
}
```

### Civil 3D

```json
{
  "profiles": {
    "<ProjectName>": { "commandName": "Project" },
    "C3D2027_Metric": {
      "commandName": "Executable",
      "executablePath": "<ACAD_HOME>\\acad.exe",
      "commandLineArgs": "/ld \"<ACAD_HOME>\\AecBase.dbx\" /p \"<<C3D_Metric>>\" /product C3D /language en-US"
    },
    "C3D2027_Imperial": {
      "commandName": "Executable",
      "executablePath": "<ACAD_HOME>\\acad.exe",
      "commandLineArgs": "/ld \"<ACAD_HOME>\\AecBase.dbx\" /p \"<<C3D_Imperial>>\" /product C3D /language en-US"
    }
  }
}
```

### Plant 3D

```json
{
  "profiles": {
    "<ProjectName>": { "commandName": "Project" },
    "Plant3D2027": {
      "commandName": "Executable",
      "executablePath": "<ACAD_HOME>\\acad.exe",
      "commandLineArgs": "/product PLNT3D /language \"en-US\""
    }
  }
}
```

---

## Step 5 — Build and load

```bash
dotnet build -c Debug
```

In AutoCAD: `NETLOAD` → `bin\Debug\net10.0-windows\<ProjectName>.dll`

Run your command (template default: `HELLOWORLD`).

# AutoCAD API Skills

AI agent skills for building AutoCAD, Civil 3D, and Plant 3D plugins with .NET 10.

These aren't generic prompts. They're verified API patterns, assembly maps, and deployment recipes that stop your AI assistant from hallucinating outdated .NET Framework code and crashing your plugin at runtime.

The original motivation: AI assistants couldn't write even a HelloWorld plugin for Plant 3D. The API documentation is scarce — mostly offline CHM files bundled with a separately downloaded SDK, no NuGet packages, and very few public examples. This skill set captures what a senior developer knows so the AI doesn't have to guess.

## Why this exists

AI assistants are trained on years of StackOverflow posts and blog articles — most of which target AutoCAD 2015–2024 with .NET Framework 4.8. Ask one to scaffold a plugin today and you'll get code that compiles but fails to load because it used `<RuntimeIdentifier>` (creates a subfolder AutoCAD can't probe), referenced `AcMgd.dll` in a Design Automation context, or forgot that Civil 3D's `Entity` class collides with AutoCAD's.

This skill set gives your AI the same knowledge a senior AutoCAD developer carries in their head:

- **Correct assembly loading** — which DLLs go where, what to exclude, what never to copy
- **Project scaffolding** — `dotnet new` templates with the right csproj settings out of the box
- **Deployment patterns** — `.bundle` packaging, `PackageContents.xml`, accoreconsole testing with `/al`
- **Explicit guardrails** — "do NOT" rules that prevent the most common AI mistakes
- **SDK-grounded lookup** — teaches the AI to search local SDK samples with `rg` before inventing API usage

### It learns as you work

Inspired by [Karpathy's LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f), the AI appends new discoveries to `skills/learnings.md` during development sessions. You review, verify against the SDK, and promote the good ones into the canonical skill files. Knowledge compounds. The AI never overwrites verified facts on its own.

## Quick Start

> 💡 Install at the **Workspace level**, not globally. You don't want AutoCAD rules polluting your web projects.

```bash
mkdir MyPlugin && cd MyPlugin
npx github:ADN-DevTech/acad-api-skill
```

This copies the skill files, registers the `dotnet new acad` and `dotnet new civil` templates, and you're ready to go.

### Target a specific assistant

```bash
npx github:ADN-DevTech/acad-api-skill -a cursor
npx github:ADN-DevTech/acad-api-skill -a github-copilot
npx github:ADN-DevTech/acad-api-skill -a claude
```

Behind a VPN? Add `--registry=https://registry.npmjs.org/` before the package name.

### Uninstall

**1. Unregister the `dotnet new` templates**

From any directory (while online so `npx` can resolve the package), run:

```bash
npx github:ADN-DevTech/acad-api-skill uninstall
```

That runs `dotnet new uninstall` for the AutoCAD and Civil 3D template folders shipped with this package. Assistant flags such as `-a cursor` are ignored for `uninstall` (templates are global to the machine). If you installed templates from a **cloned repo** instead of `npx`, use the same paths you used with `dotnet new install`:

```bash
dotnet new uninstall ./templates/acad
dotnet new uninstall ./templates/civil
```

If a template was registered from an **old npx cache path** (rare after cache cleanup), list everything and remove by the exact path shown:

```bash
dotnet new uninstall
```

Copy the `dotnet new uninstall <path>` line next to the `acad` / `civil` entries you want to drop.

**2. Remove copied skill files from your project**

The installer only **copies** files; it does not track them for automatic removal. Delete what you added, depending on how you installed:

| You ran | Typical folders / files to remove from the project root |
|---------|-----------------------------------------------------------|
| Default (all assistants) | `skills/`, `.cursor/`, `.github/`, `CLAUDE.md` |
| `-a cursor` | `skills/`, `.cursor/` |
| `-a github-copilot` | `skills/`, `.github/` (or only `.github/copilot-instructions.md` if you merged other GitHub metadata) |
| `-a claude` | `skills/`, `CLAUDE.md` |

If you merged AutoCAD rules into an existing `.cursor/rules/` tree, remove only the skill-related rule files (for example `acad-plugin.mdc`) instead of deleting the whole `.cursor/` folder.

**3. Assistant-specific settings (global installs)**

If you followed **Manual Installation** and copied files into your user profile or pasted Copilot instructions into VS Code settings, undo those steps in Cursor / VS Code / Claude Code settings and delete any copied global `skills` copy you added.

Canonical checklist for humans and agents also lives in **[`CLAUDE.md`](CLAUDE.md)** (section *Uninstalling the skill pack*).

---

## Manual Installation

### Cursor

- **Global:** Copy `.cursor/rules/` → `%USERPROFILE%\.cursor\rules\` and `skills/` → `%USERPROFILE%\.cursor\skills\`
- **Workspace:** Copy `.cursor/rules/` and `skills/` into your project root

### VS Code (GitHub Copilot)

- **Global:** Add contents of `.github/copilot-instructions.md` to `github.copilot.chat.codeGeneration.instructions` in your settings
- **Workspace:** Copy `.github/copilot-instructions.md` and `skills/` into your project

### Claude Code

- **Workspace:** Copy `CLAUDE.md` and `skills/` to your project root
- **Global:** `claude config set custom_instructions "..."`

---

## What's in the box

| File | What it does |
|------|-------------|
| `skills/scaffold.md` | End-to-end project creation: templates, csproj fixes, bundling, deployment |
| `skills/autocad-api.md` | Assembly/DLL map, plotting API, accoreconsole flags, common gotchas |
| `skills/civil3d-api.md` | Alignments, surfaces, corridors, pipe networks, data shortcuts |
| `skills/plant3d-api.md` | P&ID world map, data manager, pipe routing, project access |
| `skills/code-sleuth.md` | How to find SDK samples and query the Autodesk Help MCP server |
| `skills/learnings.md` | Append-only discovery log — human-reviewed before promotion |
| `templates/acad/` | `dotnet new acad` template (auto-installed) |
| `templates/civil/` | `dotnet new civil` template (auto-installed) |

## Links

- **Repository:** [github.com/ADN-DevTech/acad-api-skill](https://github.com/ADN-DevTech/acad-api-skill)
- **AutoCAD .NET API Reference:** [help.autodesk.com](https://help.autodesk.com/view/OARX/2027/ENU/?guid=GUID-C3F3C736-40CF-44A0-9210-55F6A939B6F2)
- **Autodesk Help MCP Server:** `https://developer.api.autodesk.com/knowledge/public/v1/mcp`
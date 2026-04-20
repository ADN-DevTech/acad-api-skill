> 🚧 **WORK IN PROGRESS** 🚧

# AutoCAD API Skills

A collection of AI agent skills and rules for scaffolding and building AutoCAD, Civil 3D, and Plant 3D plugins using .NET 10.

## How to Use

This repository contains context files, rules, and instructions designed to make AI coding assistants experts at AutoCAD API development. 

To use these skills in your own plugin projects, copy the relevant files to your project's workspace depending on which AI assistant you are using:

### Cursor
Cursor supports project-specific rules and skills to guide the AI's behavior.
- **Rules**: Copy the `.cursor/rules/` directory to your project's `.cursor/rules/` folder.
- **Skills**: Copy the `skills/` directory to your project's `.cursor/skills/` folder, or directly reference the markdown files (like `plant3d-api.md`) in your prompts.

### Claude (Claude Code / Claude Desktop)
Claude looks for a `CLAUDE.md` file in the root of your workspace to understand project context and system instructions.
- Copy the `CLAUDE.md` file from this repository to the root of your project.

### VS Code (GitHub Copilot)
GitHub Copilot uses specific instruction files to understand project context and coding standards.
- Copy the `.github/copilot-instructions.md` file to your project's `.github/` folder.

## Repository
[https://github.com/ADN-DevTech/acad-api-skill](https://github.com/ADN-DevTech/acad-api-skill)
